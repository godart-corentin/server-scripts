#!/bin/bash

# On récupère la distro linux
DISTRO=$(lsb_release -is)

# Installation des mises à jour du système
apt update -y && apt upgrade -y

# Installation d'Apache, PHP, MariaDB et autres
apt install apache2 php libapache2-mod-php mariadb-server php-mysql php-curl php-gd php-intl php-json php-mbstring php-xml php-zip curl git-all rsync cron -y

# Activation de mods pour Apache
a2enmod ssl proxy proxy_http proxy_wstunnel rewrite headers

systemctl enable apache2

# Installation de Certbot
apt install certbot python3-certbot-apache -y

# Installation de Node.js et de Yarn
if [$DISTRO = "Debian"]
then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
elif [$DISTRO = "Ubuntu"]
then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
else
    echo "Ce script ne fonctionne que sur Debian & Ubuntu."
    exit -1
fi

apt install nodejs -y

curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update && apt install yarn

# Installation de PM2
npm install pm2@latest -g
pm2 startup systemd