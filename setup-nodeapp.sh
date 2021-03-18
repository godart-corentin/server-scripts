#!/bin/bash

# Include parse_yaml function
. $(dirname "$0")/yaml.sh

# Vérifie si le repo git est bien donné.
# doitEtreBuild => boolean
if [ -z "$1" ]; then
  echo "Utilisation: sh ./setup-nodeapp.sh [git repo] [doitEtreBuild]"
  exit -1
fi

# Récupère le nom du repo git  
GIT_REPO=$1
FOLDER_NAME=$(basename "$GIT_REPO" ".${GIT_REPO##*.}")

# Copie le template site.conf
cp site-node.conf /home/site-$FOLDER_NAME.conf  

# Crée le répertoire /home/repositories s'il n'existe pas
mkdir -p /home/repositories

# Clone le repo git
cd /home/repositories
git clone $GIT_REPO

FOLDER_PATH="/home/repositories/$FOLDER_NAME"

# Fichiers ENV
HOME_FILES=/home/*

for f in $FILES
do
  if [[ "$f" == .env*  ]]; then
    mv /home/$f $FOLDER_PATH/$f
  fi
done

# Installe les dépendances Node
cd $FOLDER_NAME && npm i

# Build l'appli si l'argument 2 est "build"
if [ $2 = "true" ]; then
  npm run build
fi

# Ajoute l'appli à PM2
pm2 start pm2.json

# Vérifie la présence du fichier deploy.yml et le parse
if [[ ! -f "$FOLDER_PATH/deploy.yml" ]]; then
  echo "Le dossier /home/repositories/$FOLDER_NAME ne dispose pas d'un fichier deploy.yml"
  exit -1
fi

eval $(parse_yaml deploy.yml)

# Configure le template selon les variables
sed -i -e "s|DOMAIN|$DOMAIN|g" "/home/site-$FOLDER_NAME.conf"
sed -i -e "s|PORT|$PORT|g" "/home/site-$FOLDER_NAME.conf"
sed -i -e"s|PATH|$FOLDER_PATH|g" "/home/site-$FOLDER_NAME.conf"

# Déplace la conf du site dans les dossiers d'apache
mv /home/site-$FOLDER_NAME.conf /etc/apache2/sites-available/site-$FOLDER_NAME.conf

# Active le site sur Apache
a2ensite site-$FOLDER_NAME.conf

# Restart apache2
systemctl reload apache2

# Lancement du certbot apache pour le HTTPS
MAIL="youremail@gmail.com"
certbot -n --apache --agree-tos -d "$DOMAIN,www.$DOMAIN" -m $MAIL --redirect

# Restart apache2
systemctl reload apache2