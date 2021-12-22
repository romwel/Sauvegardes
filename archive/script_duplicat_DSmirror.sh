#!/bin/sh

echo "------------- START -------------"

INREP=`ls -c /volume2/Backup | grep ^B` 
echo "liste  $INREP" > /volume2/Tmp/Script/log_duplicat.txt


echo "***********"

RESULT=`echo $INREP | awk -F" " '{print $3}'`
echo $RESULT >> /volume2/Tmp/Script/log_duplicat.txt
echo "*********** boucle sur fichier" >> /volume2/Tmp/Script/log_duplicat.txt



for fichier in $INREP
do
	echo "[$fichier]" >> /volume2/Tmp/Script/log_duplicat.txt
	break
done

echo "$fichier" >> /volume2/Tmp/Script/log_duplicat.txt

echo "scp -v /volume2/Backup/$fichier admin@192.168.0.4:/volume1/Backup" >> /volume2/Tmp/Script/log_duplicat.txt

# scp $fichier admin@192.168.0.4:/volume1/Backup
# scp -v $fichier admin@192.168.0.4:/volume1/Backup >> /volume2/DailyBackup/Marc/log.txt 2>&1
scp -v /volume2/Backup/$fichier admin@192.168.0.4:/volume1/Backup >> /volume2/Tmp/Script/log_duplicat.txt 2>&1
echo "-------------- FIN --------------" >> /volume2/Tmp/Script/log_duplicat.txt


