DATE_LOG=`date '+%Y_%m_%d_%H_%M_%S'`
echo "#######################################"  > log_$DATE_LOG.log
echo "     NETTOYAGE TEMP DEBUT"  >> log_$DATE_LOG.log

BASE_DIR_TEMP=/c/CersaCob
BACKUP_DIR=/d/Sauvegarde
SAVE_NAME=JR
MAIL=

echo "#######################################" >> log_$DATE_LOG.log

rm $BASE_DIR_TEMP/Temp/*  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log

echo "#######################################"
echo "     SAUVEGARDE"

echo "#######################################" >> log_$DATE_LOG.log
echo "     SAUVEGARDE" >> log_$DATE_LOG.log
echo " Date / heure début archive locale : `date`" >> log_$DATE_LOG.log

DATE_SAVE=`date '+%Y_%m_%d_%H_%M_%S'`
echo $DATE_SAVE 

#====================================================================
echo "#=============c:\Travail===============" >> log_$DATE_LOG.log
tar -cvf $BASE_DIR_TEMP/Temp/Travail.tar /c/Travail >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
if [ $? != 0 ] 
 then 
 echo "@@@ Erreur d'ajout de fichiers dans $SAVE_NAME.$DATE_SAVE.tar " >> log_$DATE_LOG.log 
 fi
#====================================================================


#====================================================================
echo "#######################################" >> log_$DATE_LOG.log
echo "     CREATION TAR UNIQUE  " >> log_$DATE_LOG.log
echo " Date / heure début archive unique : `date`" >> log_$DATE_LOG.log

tar -cvf $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar $BASE_DIR_TEMP/Temp  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
if [ $? != 0 ]
then
	echo " @@@ Erreur Gros tar $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar "  >> log_$DATE_LOG.log
fi
# cryptage
gpg --output $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar.gpg --encrypt --recipient $MAIL $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
if [ $? == 0 ]
then
	echo " On ecrase l'archive cryptée sur le fichier $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar "  >> log_$DATE_LOG.log
	cp -f $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar.gpg $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
fi

#====================================================================
echo "#######################################" >> log_$DATE_LOG.log
echo "     COPY DISTANT DU TAR UNIQUE  " >> log_$DATE_LOG.log
echo " Date / heure début copy vers disckstation : `date`" >> log_$DATE_LOG.log

cp $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar $BACKUP_DIR  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
echo "cp $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar $BACKUP_DIR"  >> log_$DATE_LOG.log
if [ $? != 0 ]
then
	echo " @@@ Erreur de copie $SAVE_NAME.$DATE_SAVE.tar vers le Backup"  >> log_$DATE_LOG.log
fi
#====================================================================

echo $BASE_DIR_TEMP/Temp/$SAVE_NAME.$DATE_SAVE.tar
echo " Date / heure fin copy vers disckstation : `date`" >> log_$DATE_LOG.log

echo "#######################################"  >> log_$DATE_LOG.log
echo "     NETTOYAGE REPERTOIRE BACKUP"  >> log_$DATE_LOG.log

IN=`ls -t $BACKUP_DIR/ | grep $SAVE_NAME | tail -n +4     `
echo $IN
for x in $IN
do
    echo "*** Suppression du fichier $BACKUP_DIR/$x ***"  >> log_$DATE_LOG.log
    rm $BACKUP_DIR/$x  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
	if [ $? != 0 ]
	then
		echo " @@@ Erreur suppression du fichier $x "  >> log_$DATE_LOG.log
	fi
done

echo "#######################################"  >> log_$DATE_LOG.log
echo "     NETTOYAGE TEMP FIN"  >> log_$DATE_LOG.log

rm $BASE_DIR_TEMP/Temp/*  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log

echo " Date / heure fin du script : `date`" >> log_$DATE_LOG.log


echo " *** Suppression des fichiers *** "  >> log_$DATE_LOG.log
IN=`ls -t $BASE_DIR_TEMP | grep log_ | tail -n +11    `
echo $IN
for x in $IN
do
    echo " *** Suppression du fichiers log $x "  >> log_$DATE_LOG.log
    rm -v $BASE_DIR_TEMP/$x  >> log_$DATE_LOG.log 2>> log_$DATE_LOG.log
	if [ $? != 0 ]
	then
		echo " @@@ Erreur suppression du fichier $x "  >> log_$DATE_LOG.log
	fi
done


echo "===============     FIN DU SCRIPT ================="  >> log_$DATE_LOG.log
echo "log_$DATE_LOG.log" > logfile.info

