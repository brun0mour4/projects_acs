#!/bin/bash

# Instalação para debian 11
# by BrunoMoura

hora() {
date "+%Y-%m-%d %T.%3N"
}
DATA=$(hora)
USER=$(whoami)
while [ $USER != "root" ]; do
    echo "$DATA - Para prosseguir, você deve estar logado como root!"
    sudo su
    USER=$(whoami)
    if [ $USER = "root" ]; then
        break
    fi
done

cp -p /etc/apt/sources.list /etc/apt/sources.list.old

echo "$DATA - Seu source list será alterado, mas será criado um arquivo de backup \".old\""

echo 'deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main contrib non-free

deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free

deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free

deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main contrib non-free
 
deb http://security.debian.org/debian-security bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security bullseye-security main contrib non-free
 
deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free' > /etc/apt/sources.list

echo "$DATA - Buscando e realizando atualizações..."

apt update && apt upgrade -y
apt install firmware-linux firmware-linux-free firmware-linux-nonfree -y
apt install curl gnupg2 wget -y

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install nodejs -y

AVX=$(lscpu | grep avx | wc -l)
if [ $AVX = "1" ]; then
    echo "$DATA - Processador com suporte para operar versão superior do MongoDB 4.x, realizando instalação da versão \"5.0\""
    cd /tmp
    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
    curl -sSL https://www.mongodb.org/static/pgp/server-5.0.asc  -o mongoserver.asc
    gpg --no-default-keyring --keyring ./mongo_key_temp.gpg --import ./mongoserver.asc
    gpg --no-default-keyring --keyring ./mongo_key_temp.gpg --export > ./mongoserver_key.gpg
    mv mongoserver_key.gpg /etc/apt/trusted.gpg.d/
elif [ $AVX = "0" ]; then
    echo "$DATA - Processador sem suporte para operar versão superior do MongoDB 4.x, realizando instalação da versão \"4.4\""
    cd /tmp
    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
fi


apt update
apt install mongodb-org node-mongodb -y

systemctl enable mongod
systemctl start mongod
systemctl status mongod

npm install -g genieacs

useradd --system --no-create-home --user-group genieacs

mkdir /opt/genieacs
mkdir /opt/genieacs/ext

echo 'GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret' > /opt/genieacs/genieacs.env

chown genieacs. /opt/genieacs -R
chmod 600 /opt/genieacs/genieacs.env

mkdir /var/log/genieacs
chown genieacs. /var/log/genieacs

sudo bash -c 'cat > /etc/systemd/system/genieacs-cwmp.service <<EOF
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF'

sudo bash -c 'cat > /etc/systemd/system/genieacs-nbi.service <<EOF
[Unit]
Description=GenieACS NBI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi
 
[Install]
WantedBy=default.target
EOF'

sudo bash -c 'cat > /etc/systemd/system/genieacs-cwmp.service <<EOF
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF'

sudo bash -c 'cat > /etc/systemd/system/genieacs-fs.service <<EOF
[Unit]
Description=GenieACS FS
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs
 
[Install]
WantedBy=default.target
EOF'


sudo bash -c 'cat > /etc/systemd/system/genieacs-ui.service <<EOF
[Unit]
Description=GenieACS UI
After=network.target
 
[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui
 
[Install]
WantedBy=default.target
EOF'


echo '/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}' > /etc/logrotate.d/genieacs

systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
systemctl start genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
systemctl status genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui --no-pager | grep -A2 -B1 "Loaded"

#IP=$(ip a | grep -w "inet" | grep -v '127.0.0.1' | sed 's/^....//g' | cut -d ' ' -f2 | cut -d '/' -f1)

#echo "$DATA - Fim! Para acessar http://$IP:3000"
echo "$DATA - Fim!"
