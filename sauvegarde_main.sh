#!/usr/bin/sh

# todo : ajouter le controle md5 entre la copie sur le serveur et l'archive en local
# todo : ajouter un controle de la place dispo sur le serveur
# todo : ajouter une restriction sur la taille maximale utilisable par l'utilisateur
# todo : ajouter une mécanique de fonctionnement en local et de transfert des archives à la prochaine disponibilité du serveur
# todo : ajouter configuration mail pour envoie de rapport

# répertoire de travail temporaire
ARCHIVE_EXTENSION="tar"
COMPRESS_EXTENSION="gz"
COPYING_EXTENSION="copying"
ARCHIVE_NAME="${ARCHIVE_PREFIX_NAME}${INCREMENT_ARCHIVE}_du_${STR_DATE}.${ARCHIVE_EXTENSION}"
ARCHIVE_COMPRESS_NAME="${ARCHIVE_NAME}.${COMPRESS_EXTENSION}"
ARCHIVE_COPYING_NAME="${ARCHIVE_COMPRESS_NAME}.${COPYING_EXTENSION}"
ARCHIVE_LOCAL_PATH_NAME="${WORKING_DIR}/${ARCHIVE_NAME}"
ARCHIVE_COMPRESS_LOCAL_PATH_NAME="${WORKING_DIR}/${ARCHIVE_COMPRESS_NAME}"
# nombre d'heure de battement (correspondant à peu près à la durée total du script. 
# car si le script tourne tous les jours à la même heure il peut considérer qu'une archive n'est pas à refaire à l'instant t alors qu'elle le sera 1h plus tard.
BATTEMENT=4

ERREUR=0
START_TIME=0
END_TIME=0
START_PROCESS_TIME=0
END_PROCESS_TIME=0

datediff() {
	echo $(($1-$2)) | awk '{printf "%02dh:%02dm:%02ds\n", $1/3600, ($1/60)%60, $1%60}'
}

goto_end() {
	if [ $1 != 0 ]; then
		echo ""
		echo "Si vous ne comprenez pas les erreurs demandez à celui qui a écrit le script"
	fi
	echo "Fin de la sauvegarde le $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	END_TIME=$(date +%s)
	echo "Durée totale : $(datediff ${END_TIME} ${START_TIME})"
	exit $1
}

# avec le nombre de jours en paramètre $1 et le battement
trouver_la_premiere_archive_avant_x_jour() {
	find "${BACKUP_USER_DIR}" -type f  -name "*.${COMPRESS_EXTENSION}" -newermt "$((($1*24) - ${BATTEMENT})) hour ago" -printf "%T@ %p\n" | sort -n | sed -e "s/^[^ ]* //g" | head -n 1 | xargs -I {} basename "{}"
}

# avec le nombre de jours en paramètre $1 et le battement
trouver_la_premiere_archive_apres_x_jour() {
	find "${BACKUP_USER_DIR}" -type f  -name "*.${COMPRESS_EXTENSION}" -not -newermt "$((($1*24) - ${BATTEMENT})) hour ago" -printf "%T@ %p\n" | sort -rn | sed -e "s/^[^ ]* //g" | head -n 1 | xargs -I {} basename "{}"
}

creer_archive() {
	cd "${SAUVEGARDE_CONF_DIR}"
	# récupération de ligne non vide
	NB_FOLDERS_FILES_TO_SAVE=$(cat "${SAVE_LIST_FILE}" | awk 'NF' | wc -l)
	echo "Création de l'achive n°${INCREMENT_ARCHIVE}"
	echo "-> Début de l'archivage : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	START_PROCESS_TIME=$(date +%s)
	# création de l'archive
	cat "${SAVE_LIST_FILE}" | sed -E -e 's/^([[:alpha:]]):/"\/\1/' -e 's/\\/\//g' -e 's/$/"/' | xargs -t -n ${NB_FOLDERS_FILES_TO_SAVE} tar -vcf "${ARCHIVE_LOCAL_PATH_NAME}"
	if [ $? != 0 ]; then
		echo "	- ERREUR : impossible de créer l'archive ${ARCHIVE_LOCAL_PATH_NAME}"
		ERREUR=1
		goto_end ${ERREUR}
	fi
	echo "-> Fin de l'archivage : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	END_PROCESS_TIME=$(date +%s)
	echo "Durée de l'archivage : $(datediff ${END_PROCESS_TIME} ${START_PROCESS_TIME})"
	echo ""
	echo "Compression de l'achive ${ARCHIVE_LOCAL_PATH_NAME}"
	echo "-> Début de la compression : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	START_PROCESS_TIME=$(date +%s)
	# création de l'archive
	gzip -v "${ARCHIVE_LOCAL_PATH_NAME}"
	if [ $? != 0 ]; then
		echo "	- ERREUR : impossible de compresser l'archive ${ARCHIVE_LOCAL_PATH_NAME}"
		ERREUR=1
		goto_end ${ERREUR}
	fi
	echo "-> Fin de la compression : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	END_PROCESS_TIME=$(date +%s)
	echo "Durée de la compression : $(datediff ${END_PROCESS_TIME} ${START_PROCESS_TIME})"
	echo ""
	if [ ${ERREUR} != 0 ]; then
		goto_end ${ERREUR}
	fi

	# Copie de l'archive sur le dossier de sauvegarde
	echo "Copie de l'archive dans le dossier de sauvegarde"
	echo "-> Début de la copie : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	START_PROCESS_TIME=$(date +%s)
	# copie de l'archive sous une extention différente le temps de la copie
	cp -v "${ARCHIVE_COMPRESS_LOCAL_PATH_NAME}" "${BACKUP_USER_DIR}/${ARCHIVE_COPYING_NAME}"
	if [ $? != 0 ]; then
		echo "	- ERREUR : problème lors de la copie de l'archive ${ARCHIVE_COMPRESS_LOCAL_PATH_NAME} vers ${BACKUP_USER_DIR}"
		ERREUR=1
		goto_end ${ERREUR}
	fi
	# Si la copie c'est bien passée ont renomme correctement l'archive
	mv "${BACKUP_USER_DIR}/${ARCHIVE_COPYING_NAME}" "${BACKUP_USER_DIR}/${ARCHIVE_COMPRESS_NAME}"
	echo "-> Fin de la copie : $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
	END_PROCESS_TIME=$(date +%s)
	echo "Durée de la copie : $(datediff ${END_PROCESS_TIME} ${START_PROCESS_TIME})"
	echo ""
	
	return
}

START_TIME=$(date +%s)
echo "Début de la sauvegarde le $(date '+%A %d %B %Y %Hh:%Mm:%Ss')"
echo ""
echo "Configuration : "
echo "	- Dossier configuration de sauvegarde : ${SAUVEGARDE_CONF_DIR}"
echo "	- Répertoire distant de sauvegarde de l'utilisateur : ${BACKUP_USER_DIR}"
echo "	- La rétention se fait sur ${RETENTION_1}, ${RETENTION_2} et ${RETENTION_3} jours"
echo "	- Les ${NB_LOG_FILE} derniers fichiers de logs sont conservés"
echo "	- Liste des dossiers et fichiers à sauvegarder : ${SAVE_LIST_FILE}"

# Vérification du fichier de configuration
if [ ! -f "${SAVE_LIST_FILE}" ]; then
	echo "ERREUR : impossible d'accéder au fichier de configuration ${SAVE_LIST_FILE}"
	ERREUR=1
	goto_end ${ERREUR}
fi
# suppression des ligne vide du fichiers, des espaces en début et en fin de fichiers
sed -E -i -e '/^[[:space:]]*$/d' -e 's/\s*$//' -e 's/^\s*//' "${SAVE_LIST_FILE}"
sed -e "s/^/\t\t- /g" "${SAVE_LIST_FILE}"
echo ""

# création des dossier de travail temporaire
if [ ! -d "${WORKING_DIR}" ] ; then
	echo "Création du dossier temporaire de travail ${WORKING_DIR}"
	mkdir "${WORKING_DIR}"
	if [ $? != 0 ]; then
		echo "ERREUR : impossible de créer le dossier temporaire de sauvegarde ${WORKING_DIR}"
		ERREUR=1
		goto_end ${ERREUR}
	fi
else
	echo "Nettoyage du dossier temporaire de travail ${WORKING_DIR}"
	rm -rfv "${WORKING_DIR}/*" # -f pour éviter d'avoir une erreur quand le dossier est vide
	if [ $? != 0 ] ; then
		echo "ERREUR : impossible nettoyer le dossier"
		ERREUR=1
	fi
fi;
echo ""

cd "${BACKUP_DIR}"
if [ $? != 0 ] ; then
	echo "ERREUR : impossible d'accéder au dossier distant de sauvegarde ${BACKUP_DIR}"
	ERREUR=1
	goto_end ${ERREUR}
fi

# création des dossier distant de sauvegarde
if [ ! -d "${BACKUP_ROOT_SAVE_DIR}" ] ; then
	echo "Création du dossier distant de sauvegarde ${BACKUP_ROOT_SAVE_DIR}"
	mkdir "${BACKUP_ROOT_SAVE_DIR}"
	if [ $? != 0 ]; then
		echo "ERREUR : impossible de créer le dossier distant de sauvegarde ${BACKUP_ROOT_SAVE_DIR}"
		ERREUR=2
		goto_end ${ERREUR}
	fi
fi

# création des dossier distant de sauvegarde
if [ ! -d "${BACKUP_USER_DIR}" ] ; then
	echo "Création du dossier distant de sauvegarde ${BACKUP_USER_DIR}"
	mkdir "${BACKUP_USER_DIR}"
	if [ $? != 0 ]; then
		echo "ERREUR : impossible de créer le dossier distant de sauvegarde ${BACKUP_USER_DIR}"
		ERREUR=2
		goto_end ${ERREUR}
	fi
fi

# on se place dans le dossier de sauvegarde
cd "${BACKUP_USER_DIR}"
if [ $? != 0 ] ; then
	echo "ERREUR : impossible d'accéder au dossier distant de sauvegarde ${BACKUP_USER_DIR}"
	ERREUR=1
	goto_end ${ERREUR}
fi

echo "La liste des archives : $(du -Sh)"
ls -thgG --time-style="+%A %d %B %Y %H:%M" | cut -d" " -f3- | sed -e "1d" -e "s/^/\t- /g"
echo ""

echo "- Suppression des archives dont la copie aurait échoué :"
find "${BACKUP_USER_DIR}" -type f -iname "*.${COPYING_EXTENSION}" -exec rm -v "{}" \;
if [ $? != 0 ] ; then
	echo "ERREUR : impossible de supprimer les archives temporaires"
	ERREUR=1
fi
echo ""

# Faut-il faire une sauvegarde ?
PREMIERE_ARCHIVE_AVANT_RETENTION_1="$(trouver_la_premiere_archive_avant_x_jour ${RETENTION_1})"
if [ -f "${PREMIERE_ARCHIVE_AVANT_RETENTION_1}" ] ; then
	echo "L'archive ${PREMIERE_ARCHIVE_AVANT_RETENTION_1} date de moins de ${RETENTION_1} jours"
	echo "Il n'est pas nécessaire de faire une nouvelle archive"
else
	echo "Aucune archive ne date de moins de ${RETENTION_1} jours"
	creer_archive
fi;

echo ""
echo "Nettoyage du dossier de sauvegarde ${BACKUP_USER_DIR}"
echo "- On conserve toutes les archives les plus proche avant et après de chaque point de rétention et on supprime les autres"
echo ""
echo "- Recherche des archives à conserver"
START_PROCESS_TIME=$(date +%s)
cd "${BACKUP_USER_DIR}" 
PREMIERE_ARCHIVE_AVANT_RETENTION_1="$(trouver_la_premiere_archive_avant_x_jour ${RETENTION_1})"
PREMIERE_ARCHIVE_APRES_RETENTION_1="$(trouver_la_premiere_archive_apres_x_jour ${RETENTION_1})"
PREMIERE_ARCHIVE_AVANT_RETENTION_2="$(trouver_la_premiere_archive_avant_x_jour ${RETENTION_2})"
PREMIERE_ARCHIVE_APRES_RETENTION_2="$(trouver_la_premiere_archive_apres_x_jour ${RETENTION_2})"
PREMIERE_ARCHIVE_AVANT_RETENTION_3="$(trouver_la_premiere_archive_avant_x_jour ${RETENTION_3})"
PREMIERE_ARCHIVE_APRES_RETENTION_3="$(trouver_la_premiere_archive_apres_x_jour ${RETENTION_3})"
if [ -f "${PREMIERE_ARCHIVE_AVANT_RETENTION_1}" ] ; then
	echo "	- La première archive avant ${RETENTION_1} jours est ${PREMIERE_ARCHIVE_AVANT_RETENTION_1}"
else
	echo "	- Il n'y a aucune archive avant ${RETENTION_1} jours"
fi;

if [ -f "${PREMIERE_ARCHIVE_APRES_RETENTION_1}" ] ; then
	echo "	- La première archive après ${RETENTION_1} jours est ${PREMIERE_ARCHIVE_APRES_RETENTION_1}"
else
	echo "	- Il n'y a aucune archive après ${RETENTION_1} jours"
fi;

if [ -f "${PREMIERE_ARCHIVE_AVANT_RETENTION_2}" ] ; then
	echo "	- La première archive avant ${RETENTION_2} jours est ${PREMIERE_ARCHIVE_AVANT_RETENTION_2}"
else
	echo "	- Il n'y a aucune archive avant ${RETENTION_2} jours"
fi;

if [ -f "${PREMIERE_ARCHIVE_APRES_RETENTION_2}" ] ; then
	echo "	- La première archive après ${RETENTION_2} jours est ${PREMIERE_ARCHIVE_APRES_RETENTION_2}"
else
	echo "	- Il n'y a aucune archive après ${RETENTION_2} jours"
fi;

if [ -f "${PREMIERE_ARCHIVE_AVANT_RETENTION_3}" ] ; then
	echo "	- La première archive avant ${RETENTION_3} jours est ${PREMIERE_ARCHIVE_AVANT_RETENTION_3}"
else
	echo "	- Il n'y a aucune archive avant ${RETENTION_3} jours"
fi;

if [ -f "${PREMIERE_ARCHIVE_APRES_RETENTION_3}" ] ; then
	echo "	- La première archive après ${RETENTION_3} jours est ${PREMIERE_ARCHIVE_APRES_RETENTION_3}"
else
	echo "	- Il n'y a aucune archive après ${RETENTION_3} jours "
fi;
echo ""
# pour que la commande ls et sed fonction correctement il ne doit pas y avoir de variable vide 
# sinon on a le message $ ls: cannot access '': No such file or directory
# PREMIERE_ARCHIVE_AVANT_RETENTION_1 ne peut pas être vide 
# si la variable est vide on la substitue par PREMIERE_ARCHIVE_AVANT_RETENTION_1
PREMIERE_ARCHIVE_APRES_RETENTION_1="${PREMIERE_ARCHIVE_APRES_RETENTION_1:-${PREMIERE_ARCHIVE_AVANT_RETENTION_1}}"
PREMIERE_ARCHIVE_AVANT_RETENTION_2="${PREMIERE_ARCHIVE_AVANT_RETENTION_2:-${PREMIERE_ARCHIVE_AVANT_RETENTION_1}}"
PREMIERE_ARCHIVE_APRES_RETENTION_2="${PREMIERE_ARCHIVE_APRES_RETENTION_2:-${PREMIERE_ARCHIVE_AVANT_RETENTION_1}}"
PREMIERE_ARCHIVE_AVANT_RETENTION_3="${PREMIERE_ARCHIVE_AVANT_RETENTION_3:-${PREMIERE_ARCHIVE_AVANT_RETENTION_1}}"
PREMIERE_ARCHIVE_APRES_RETENTION_3="${PREMIERE_ARCHIVE_APRES_RETENTION_3:-${PREMIERE_ARCHIVE_AVANT_RETENTION_1}}"

echo "Les archives à conserver sont : "
ls -1 -t "${PREMIERE_ARCHIVE_AVANT_RETENTION_1}" "${PREMIERE_ARCHIVE_APRES_RETENTION_1}" "${PREMIERE_ARCHIVE_AVANT_RETENTION_2}" "${PREMIERE_ARCHIVE_APRES_RETENTION_2}" "${PREMIERE_ARCHIVE_AVANT_RETENTION_3}" "${PREMIERE_ARCHIVE_APRES_RETENTION_3}" | uniq | sed -e "s/^/\t- /g"

echo "Les archives à supprimer sont : "
ls -1 -t | sed -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_1}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_1}"/d -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_2}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_2}"/d -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_3}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_3}"/d -e "s/^/\t- /g"

ls -1 -t | sed -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_1}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_1}"/d -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_2}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_2}"/d -e /"${PREMIERE_ARCHIVE_AVANT_RETENTION_3}"/d -e /"${PREMIERE_ARCHIVE_APRES_RETENTION_3}"/d | xargs -I {} rm -v "{}"
echo ""
echo "La liste des archives : $(du -Sh)"
ls -thgG --time-style="+%A %d %B %Y %H:%M" | cut -d" " -f3- | sed -e "1d" -e "s/^/\t- /g"
echo "Fin du nettoyage du dossier de sauvegarde ${BACKUP_USER_DIR}"
END_PROCESS_TIME=$(date +%s)
echo "Durée du nettoyage : $(datediff ${END_PROCESS_TIME} ${START_PROCESS_TIME})"
echo ""

echo ""
echo "Nettoyage du dossier de log ${LOG_DIR}"
echo "- On conserve seulement les ${NB_LOG_FILE} fichiers de logs les plus récents"
START_PROCESS_TIME=$(date +%s)
cd "${LOG_DIR}"
ls -t -1 *.log | tail -n +$((${NB_LOG_FILE} + 1)) | xargs -I {} rm -v "${LOG_DIR}/{}"
if [ $? != 0 ] ; then
	echo "ERREUR : impossible de supprimer les fichiers de log"
	ERREUR=1
fi
echo ""

cd "${WORKING_DIR}"
echo "- On supprime toutes les archives temporaires"
find "${WORKING_DIR}" -type f -iname "*.${COMPRESS_EXTENSION}" -exec rm -v "{}" \;
if [ $? != 0 ] ; then
	echo "ERREUR : impossible de supprimer les fichiers compresser"
	ERREUR=1
fi

find "${WORKING_DIR}" -type f -iname "*.${ARCHIVE_EXTENSION}" -exec rm -v "{}" \;
if [ $? != 0 ] ; then
	echo "ERREUR : impossible de supprimer les archives"
	ERREUR=1
fi
END_PROCESS_TIME=$(date +%s)
echo "Fin du nettoyage du dossier temporaire de travail ${WORKING_DIR}"
echo "Durée du nettoyage : $(datediff ${END_PROCESS_TIME} ${START_PROCESS_TIME})"
echo ""
goto_end ${ERREUR}
