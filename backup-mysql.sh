#!/bin/bash

function echo_status(){
  printf '\r'; 
  printf ' %0.s' {0..100} 
  printf '\r'; 
  printf "$1"'\r'
}

# On initialise certaines variables.
TIMESTAMP = $(date +%F)
BACKUP_DIR = /home/backup/databases/$TIMESTAMP
KEEP_BACKUPS_FOR=30 # Jours
IGNORE_DB="(^mysql|_schema$)"
PATH=$PATH:/usr/local/mysql/bin

MYSQL_USER=root
MYSQL_PASS=

# On supprime les backup qui ont plus de 30jours.
find /home/backup/databases/*  -mtime +$KEEP_BACKUPS_FOR -exec rm {} \;

# On récupère les BDD
DATABASES = $(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "SHOW DATABASES WHERE \'Database'\ NOT REGEXP '$IGNORE_DB'" | awk -F " " '{if (NR!=1) print $1}')
TOTAL = $(echo $DATABASES | wc -w | xargs)
OUTPUT = ""
COUNT = 1

# On backup chaque base
for DATABASE in $DATABASES
do
    BACKUP_FILE = "$BACKUP_DIR/backup-$DATABASE-$TIMESTAMP.sql.gz"
    OUTPUT+= "$DATABASE => $BACKUP_FILE\n"
    echo_status "Back up de la BDD $DATABASE ($COUNT/$TOTAL)"
    $(mysqldump -u $MYSQL_USER -p$MYSQL_PASS $DATABASE | gzip -9 > $BACKUP_FILE)
    let COUNT++
done
echo -ne $OUTPUT | column -t