#!/bin/bash

# Installation des mises à jour du système
apt update -y && apt upgrade -y

# Installation d'Apache, PHP, MariaDB, Curl et GIT
apt install apache2 php libapache2-mod-php mariadb-server php-mysql php-curl php-gd php-intl php-json php-mbstring php-xml php-zip curl git-all rsync -y

# Activation de mods pour Apache
a2enmod ssl proxy proxy_http proxy_wstunnel rewrite headers

systemctl enable apache2

# Installation de Certbot
apt install certbot python3-certbot-apache -y

# Installation de Node.js et de Yarn
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
cat /etc/apt/sources.list.d/nodesource.list
deb https://deb.nodesource.com/node_14.x focal main
deb-src https://deb.nodesource.com/node_14.x focal main

apt install nodejs build-essential -y

curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update && apt install yarn

# Installation de PM2
npm install pm2@latest -g
pm2 startup systemd