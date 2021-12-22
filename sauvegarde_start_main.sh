#!/usr/bin/sh

# formatage des variables d'environnement windows SAUVEGARDE_CONF_DIR et SAUVEGARDE_SCRIPT_DIR au format linux 
export SAUVEGARDE_CONF_DIR="$(echo "${SAUVEGARDE_CONF_DIR}" | sed -E -e 's/^([[:alpha:]]):/\/\1/' -e 's/\\/\//g')"
export SAUVEGARDE_SCRIPT_DIR="$(echo "${SAUVEGARDE_SCRIPT_DIR}" | sed -E -e 's/^([[:alpha:]]):/\/\1/' -e 's/\\/\//g')"

# fichier de la liste des dossiers et fichiers à sauvegarder
export CONFIG_FILE="${SAUVEGARDE_CONF_DIR}/sauvegarde_config.sh"
source "${CONFIG_FILE}"

# Date pour le nom du fichier de sauvegarde
export STR_DATE=$(date '+%A_%d_%B_%Y_%Hh%Mm%Ss')
export ARCHIVE_PREFIX_NAME="archive_"
export INCREMENT_ARCHIVE=$(($(find "${BACKUP_USER_DIR}" -type f -name "archive*.gz" | sed -E -e "s/.*${ARCHIVE_PREFIX_NAME}([[:digit:]]*)_.*/\1/g" | sort -rn | head -1) + 1))
# nom du fichier de sauvegarde
export LOG_FILE_NAME="${ARCHIVE_PREFIX_NAME}${INCREMENT_ARCHIVE}_${STR_DATE}.log"
export LOG_FILE_PATH_NAME="${LOG_DIR}/${LOG_FILE_NAME}"

# création des dossier de log
if [ ! -d "${LOG_DIR}" ] ; then
	echo "Création du dossier de log ${LOG_DIR}"
	mkdir "${LOG_DIR}"
	if [ $? != 0 ]; then
		echo "	- ERREUR : impossible de créer dossier de log des sauvegarde ${LOG_DIR}"
	fi
fi

# création des dossier de log d'erreur
if [ ! -d "${LOG_ERROR_DIR}" ] ; then
	echo "Création du dossier de log d'erreur ${LOG_ERROR_DIR}"
	mkdir "${LOG_ERROR_DIR}"
	if [ $? != 0 ]; then
		echo "	- ERREUR : impossible de créer dossier de log d'erreur ${LOG_ERROR_DIR}"
	fi
fi

# exécution du script et redirection de la sortie dans le fichier de log
touch "${LOG_FILE_PATH_NAME}"
cd "${SAUVEGARDE_SCRIPT_DIR}"
./sauvegarde_main.sh 2>&1 | tee "${LOG_FILE_PATH_NAME}"

# si il y a une erreur sur l'execution du script sauvegarde_main.sh on copie le fichier de logs dans le dossier des logs d'erreurs
if [ ${PIPESTATUS[0]} != 0 ]; then
	cp -v "${LOG_FILE_PATH_NAME}" "${LOG_ERROR_DIR}/ERREUR_${LOG_FILE_NAME}.txt"
	mv -v "${LOG_FILE_PATH_NAME}" "${LOG_DIR}/ERREUR_${LOG_FILE_NAME}"
	exit ${PIPESTATUS[0]}
fi

exit 0
