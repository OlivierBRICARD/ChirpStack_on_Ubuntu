#!/bin/bash
# script needs to be run with super privilege
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run with superuser privilege. Try 'sudo ./install.sh'\n"
  exit 1
fi

cp init_sql.sql /tmp/init_sql.sql -f

#apt list --upgradable

# 1. install requirements
apt -f -y install dialog mosquitto mosquitto-clients redis-server redis-tools ruby-redis postgresql postgresql-doc postgresql-doc-14 apt-transport-https dirmngr isag

# 2. setup PostgreSQL databases and users
sudo -u postgres psql -c "create role chirpstack with login password 'chirpstack';"
sudo -u postgres psql -c "create database chirpstack with owner chirpstack;"
sudo -u postgres psql chirpstack -c "create extension pg_trgm;"
sudo -u postgres psql chirpstack -c "create extension hstore;"
sudo -u postgres psql -U postgres -f /tmp/init_sql.sql
rm -f /tmp/init_sql.sql

#3. install ChirpStack packages
#3.1 install https requirements
#apt -f -y install apt-transport-https dirmngr
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00
sudo apt-key export 6DBCCA00 | sudo gpg --dearmour -o /usr/share/keyrings/chirpstack.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chirpstack.gpg] https://artifacts.chirpstack.io/packages/4.x/deb stable main" | sudo tee /etc/apt/sources.list.d/chirpstack.list
sudo apt update
sudo apt install chirpstack
sudo apt install chirpstack-gateway-bridge

#4. configure lora
# configure chirpstack Server
#cp -f /etc/chirpstack-network-server/chirpstack-network-server.toml  /etc/chirpstack-network-server/chirpstack-network-server.toml_bak
cp -rf ./chirpstack_conf/*  /etc/chirpstack/
chown -R networkserver:networkserver /etc/chirpstack

# configure chirpstack App Server
#cp -f /etc/chirpstack-application-server/chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml_bak
#cp -f ./chirpstack-application-server.toml /etc/chirpstack-application-server/chirpstack-application-server.toml
chown -R appserver:appserver /etc/chirpstack

# start chirpstack
sudo systemctl start chirpstack
# start chirpstack on boot
sudo systemctl enable chirpstack

# start chirpstack-gateway-bridge
systemctl restart chirpstack-gateway-bridge
# start chirpstack-gateway-bridge on boot
sudo systemctl enable chirpstack-gateway-bridge


#Print the ChirpStack log-output:
sudo journalctl -f -n 100 -u chirpstack
