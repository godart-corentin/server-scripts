#!/bin/bash

# Include parse_yaml function
. parse_yaml.sh

# Vérifie si le repo git est bien donné.
# doitEtreBuild => boolean
if [ -z "$1" ]
then
  echo "Utilisation: sh ./setup-nodeapp.sh [git repo] [doitEtreBuild]"
  exit -1
fi

# Récupère le nom du repo git  
git_repo = $1
basename = $(basename $git_repo)
folder_name = $(basename%.*)

# Copie le template site.conf
cp site-node.conf /home/site-$folder_name.conf

# Crée le répertoire /home/repositories s'il n'existe pas
if [[ ! -f "/home/repositories" ]]
then
  mkdir /home/repositories
fi

# Clone le repo git
cd /home/repositories && git clone git_repo

PATH = "/home/repositories/${folder_name}"

# Installe les dépendances Node
cd folder_name && npm i

# Build l'appli si l'argument 2 est "build"
if [$2 = "true"]
then
  npm run build
fi

# Ajoute l'appli à PM2
pm2 start pm2.json

# Vérifie la présence du fichier deploy.yml et le parse
if [[ ! -f "${PATH}/deploy.yml" ]]
then
  echo "Le dossier /home/repositories/${folder_name} ne dispose pas d'un fichier deploy.yml"
  exit -1
fi

eval $(parse_yaml deploy.yml "config_")

# Configure le template selon les variables
sed -i "s/{{DOMAIN}}/${config_domain}/g" /home/site-$folder_name.conf
sed -i "s/{{PORT}}/${config_port}/g" /home/site-$folder_name.conf
sed -i "s/{{PATH}}/${PATH}/g" /home/site-$folder_name.conf

# Déplace la conf du site dans les dossiers d'apache
mv /home/site-$folder_name.conf /etc/apache2/sites-available/site-$folder_name.conf

# Active le site sur Apache
a2ensite site-$folder_name.conf

# Restart apache2
systemctl reload apache2

# Lancement du certbot apache pour le HTTPS
certbot -n --apache --agree-tos -d "${config_domain},www.${config_domain}" -m $config_mail --redirect

# Restart apache2
systemctl reload apache2