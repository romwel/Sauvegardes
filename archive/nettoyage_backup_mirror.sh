#!/bin/sh




echo "#######################################"
echo "     NETTOYAGE REPERTOIRE BACKUP"

IN=`ls -t /volume1/Backup | grep Backup_hebdo | tail -n +8`
for x in $IN
do
    echo "*** Suppression du fichier /volume1/Backup_hebdo/$x ***"
    rm /volume1/Backup/$x
done



