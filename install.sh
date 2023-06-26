#!/bin/bash
# Ce script doit être lancé en tant que root
if [ $(id -u) -ne 0 ]; then
  printf "Le script doit être exécuté avec le privilège de superutilisateur. Essayez 'sudo ./install.sh'\n"
  exit 1
fi

cp init_sql.sql /tmp/init_sql.sql -f

#apt list --upgradable

# 1. configuration requise pour l'installation
apt -f -y install dialog mosquitto mosquitto-clients redis-server redis-tools ruby-redis postgresql postgresql-doc postgresql-doc-14 apt-transport-https dirmngr isag

# 2. configurer les bases de données et les utilisateurs PostgreSQL
sudo -i -u postgres psql -c "create role chirpstack with login password 'chirpstack';"
sudo -i -u postgres psql -c "create database chirpstack with owner chirpstack;"
sudo -i -u postgres psql chirpstack -c "create extension pg_trgm;"
sudo -i -u postgres psql chirpstack -c "create extension hstore;"
sudo -i -u postgres psql -U postgres -f /tmp/init_sql.sql
sudo rm -f /tmp/init_sql.sql

#3. installer les packages ChirpStack

#3.1 installer les exigences https
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00
sudo apt-key export 6DBCCA00 | sudo gpg --dearmour -o /usr/share/keyrings/chirpstack.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chirpstack.gpg] https://artifacts.chirpstack.io/packages/4.x/deb stable main" | sudo tee /etc/apt/sources.list.d/chirpstack.list
sudo apt update
sudo apt install chirpstack
sudo apt install chirpstack-gateway-bridge

#4. configuration de lora
# configuration de chirpstack Server
#cp -f /etc/chirpstack-network-server/chirpstack-network-server.toml  /etc/chirpstack-network-server/chirpstack-network-server.toml_bak
cp -rf ./chirpstack_conf/*  /etc/chirpstack/
#chown -R networkserver:networkserver /etc/chirpstack

# configuration de chirpstack App Server
#cp -f /etc/chirpstack-application-server/chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml_bak
#cp -f ./chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml
#chown -R appserver:appserver /etc/chirpstack

# Demarrer chirpstack
sudo systemctl start chirpstack
# Demarrer chirpstack au demarrage
sudo systemctl enable chirpstack

# Demarrer chirpstack-gateway-bridge
systemctl restart chirpstack-gateway-bridge
# Demarrer chirpstack-gateway-bridge au demarrage
sudo systemctl enable chirpstack-gateway-bridge


#Imprimer la sortie du journal ChirpStack:
sudo journalctl -f -n 100 -u chirpstack
