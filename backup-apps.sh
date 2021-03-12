#!/bin/bash

function echo_status(){
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

# On vérifie que les arguments ont bien été entrés.
if [[ -z $1 || -z $2 || -z $3 ]]
then
  echo "Utilisation: sh ./backup-apps.sh [username] [ip] [port]"
  exit -1
fi

# On initialise certaines variables
TIMESTAMP=$(date +%F)
BACKUP_DIR=/home/backup/repositories/$TIMESTAMP
KEEP_BACKUPS_FOR=30 #Jours
SSH_USER=$1
SSH_IP=$2
SSH_PORT=$3
TOTAL=$(find /home/repositories/* -maxdepth 0 -type d | wc -l)
OUTPUT=""
COUNT=1

# Création du dossier backup du jour
mkdir -p $BACKUP_DIR

# On supprime les backup qui ont plus de 30jours.
find /home/backup/repositories/*  -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;

# On loop sur tous les dossiers présents dans /home/repositories
for dir in /home/repositories/*
do
    if [-d "$dir"]
    then
        FOLDER_NAME=$(basename "$dir")
        BACKUP_FILE="backup-$FOLDER_NAME-$TIMESTAMP.tar.gz"
        OUTPUT+="$FOLDER_NAME => $BACKUP_FILE\n"
        echo_status "Back up du dossier $FOLDER_NAME ($COUNT/$TOTAL)"
        tar -czvf $BACKUP_DIR/$BACKUP_FILE /home/repositories/$FOLDER_NAME --exclude='/home/backup/repositories'
        let COUNT++
    fi
done
echo -ne $OUTPUT | column -t

# On envoie toutes les archives sur un serveur distant (nécessite une clef ssh pour ne pas prompt un password)
rsync -e "ssh -p $SSH_PORT" -avl --delete --stats --progress $SSH_USER@$SSH_IP:/home/backup/repositories $BACKUP_DIR/