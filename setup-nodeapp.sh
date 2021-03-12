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
GIT_REPO = $1
BASENAME = $(basename $GIT_REPO)
FOLDER_NAME = $(basename%.*)

# Copie le template site.conf
cp site-node.conf /home/site-$FOLDER_NAME.conf  

# Crée le répertoire /home/repositories s'il n'existe pas
if [[ ! -f "/home/repositories" ]]
then
  mkdir /home/repositories
fi

# Clone le repo git
cd /home/repositories && git clone $GIT_REPO

PATH = "/home/repositories/$FOLDER_NAME"

# Fichiers ENV
HOME_FILES = /home/*

for f in $FILES
do
  if [[ "$f" == .env*  ]]
  then
    mv /home/$f $PATH/$f
  fi
done

# Installe les dépendances Node
cd $FOLDER_NAME && npm i

# Build l'appli si l'argument 2 est "build"
if [$2 = "true"]
then
  npm run build
fi

# Ajoute l'appli à PM2
pm2 start pm2.json

# Vérifie la présence du fichier deploy.yml et le parse
if [[ ! -f "$PATH/deploy.yml" ]]
then
  echo "Le dossier /home/repositories/$FOLDER_NAME ne dispose pas d'un fichier deploy.yml"
  exit -1
fi

eval $(parse_yaml deploy.yml "CONFIG_")

# Configure le template selon les variables
sed -i "s/{{DOMAIN}}/$CONFIG_DOMAIN/g" /home/site-$FOLDER_NAME.conf
sed -i "s/{{PORT}}/$CONFIG_PORT/g" /home/site-$FOLDER_NAME.conf
sed -i "s/{{PATH}}/$PATH/g" /home/site-$FOLDER_NAME.conf

# Déplace la conf du site dans les dossiers d'apache
mv /home/site-$FOLDER_NAME.conf /etc/apache2/sites-available/site-$FOLDER_NAME.conf

# Active le site sur Apache
a2ensite site-$FOLDER_NAME.conf

# Restart apache2
systemctl reload apache2

# Lancement du certbot apache pour le HTTPS
certbot -n --apache --agree-tos -d "$CONFIG_DOMAIN,www.$CONFIG_DOMAIN" -m $CONFIG_MAIL --redirect

# Restart apache2
systemctl reload apache2