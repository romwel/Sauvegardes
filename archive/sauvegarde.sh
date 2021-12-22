#!/usr/bin/sh

WORKING_DIR=/c/CersaCob
BACKUP_DIR=/d/Sauvegarde
SAVE_NAME=JR
MAIL=

echo "#######################################"
echo "     NETTOYAGE TEMP DEBUT"
rm $WORKING_DIR/Temp/* 
echo "#######################################"

echo "#######################################"
echo "     SAUVEGARDE"
echo " Date / heure début archive locale : `date`"

STR_DATE=`date '+%Y%m%d_%Hh%Mm%Ss'`
echo ${STR_DATE} 

echo "#=============c:\Travail==============="
tar -cvf $WORKING_DIR/Temp/Travail.tar /c/Travail 
if [ $? != 0 ] 
 then 
 echo "@@@ Erreur d'ajout de fichiers dans $SAVE_NAME.${STR_DATE}.tar " 
 fi

echo "#######################################"
echo "     CREATION TAR UNIQUE  "
echo " Date / heure début archive unique : `date`"

tar -cvf $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar $WORKING_DIR/Temp 
if [ $? != 0 ]
then
	echo " @@@ Erreur Gros tar $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar "
fi
# cryptage
gpg --output $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar.gpg --encrypt --recipient $MAIL $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar 
if [ $? == 0 ]
then
	echo " On ecrase l'archive cryptée sur le fichier $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar "
	cp -f $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar.gpg $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar 
fi

echo "#######################################"
echo "     COPY DISTANT DU TAR UNIQUE  "
echo " Date / heure début copy vers disckstation : `date`"

cp $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar $BACKUP_DIR 
echo "cp $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar $BACKUP_DIR"
if [ $? != 0 ]
then
	echo " @@@ Erreur de copie $SAVE_NAME.${STR_DATE}.tar vers le Backup"
fi

echo $WORKING_DIR/Temp/$SAVE_NAME.${STR_DATE}.tar
echo " Date / heure fin copy vers disckstation : `date`"

echo "#######################################"
echo "     NETTOYAGE REPERTOIRE BACKUP"

IN=`ls -t $BACKUP_DIR/ | grep $SAVE_NAME | tail -n +4     `
echo $IN
for x in $IN
do
    echo "*** Suppression du fichier $BACKUP_DIR/$x ***"
    rm $BACKUP_DIR/$x 
	if [ $? != 0 ]
	then
		echo " @@@ Erreur suppression du fichier $x "
	fi
done

echo "#######################################"
echo "     NETTOYAGE TEMP FIN"

rm $WORKING_DIR/Temp/* 

echo " Date / heure fin du script : `date`"


echo " *** Suppression des fichiers *** "
IN=`ls -t $WORKING_DIR | grep log_ | tail -n +11    `
echo $IN
for x in $IN
do
    echo " *** Suppression du fichiers log $x "
    rm -v $WORKING_DIR/$x 
	if [ $? != 0 ]
	then
		echo " @@@ Erreur suppression du fichier $x "
	fi
done


echo "===============     FIN DU SCRIPT ================="

