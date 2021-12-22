#!/usr/bin/sh

# 0 - Installer msys2 https://www.msys2.org/ 
# 1 - Créer une variable d'environnement windows utilisateur HOME (ex : HOME = C:\Users\r.bienvenu.CERSA-RENER)
#   - Créer une variable d'environnement windows utilisateur SAUVEGARDE_CONF_DIR (ex : SAUVEGARDE_CONF_DIR = C:\Users\r.bienvenu.CERSA-RENER\Sauvegarde)
#   - Créer une variable d'environnement windows utilisateur SAUVEGARDE_SCRIPT_DIR (ex : SAUVEGARDE_SCRIPT_DIR = C:\repo\Scripts\Utilitaires\Sauvegarde)
# 2 - Copier les fichier sauvegarde_config.sh et sauvegarde_liste.txt dans le répertoire SAUVEGARDE_CONF_DIR
# 3 - Lister les fichiers et dossiers que vous souhaiter enregistrer dans le fichier sauvegarde_liste.txt que vous avez copié dans SAUVEGARDE_CONF_DIR
# 4 - Configurer les variables de base ci-dessous dans le fichier sauvegarde_config.sh que vous avez copié dans SAUVEGARDE_CONF_DIR
#		- RETENTION_1
#		- RETENTION_2 (facultatif)
#		- RETENTION_3 (facultatif)
# 5 - Créer une tache dans le planificateur de tache :
# 		Déclencheurs :
#		- Chaque jour
# 		Actions :
#		- Programmes/script : C:\\msys64\\usr\\bin\\env
#		- Ajouter des arguments : MSYSTEM=MSYS /usr/bin/sh -li "C:\repo\Scripts\Utilitaires\Sauvegarde\sauvegarde_start_main.sh"

################### CONFIGURATION ############################
# La rétention est le nombre de jour de conservation des archives
export RETENTION_1=25
export RETENTION_2=50
export RETENTION_3=180
############################################################

################### CONFIGURATION AVANCÉE ###################
# répertoire distant de sauvegarde de l'utilisateur
export BACKUP_DIR="//Nas-data-nosave/CERSA-RD"
export BACKUP_ROOT_SAVE_DIR="${BACKUP_DIR}/Sauvegardes"
export BACKUP_USER_DIR="${BACKUP_ROOT_SAVE_DIR}/${USER}"

# dossier temporaire de travail (par défaut "${SAUVEGARDE_CONF_DIR}/temp")
export WORKING_DIR="${SAUVEGARDE_CONF_DIR}/temp"

# dossier d'enregistrement des logs (par défaut "${SAUVEGARDE_CONF_DIR}/logs")
export LOG_DIR="${SAUVEGARDE_CONF_DIR}/logs"
# nombre le fichier de log conservés dans le temporaire de travail WORKING_DIR
export NB_LOG_FILE=50
# dossier de copie des fichiers de logs en erreur pour avertir l'utilisateur (par défaut "${HOME}/Desktop")
export LOG_ERROR_DIR="${HOME}/Desktop"

# chemin du fichier de la liste des dossiers et fichiers à sauvegarder (par défaut "${SAUVEGARDE_CONF_DIR}/sauvegarde_liste.txt")
export SAVE_LIST_FILE="${SAUVEGARDE_CONF_DIR}/sauvegarde_liste.txt"
############################################################
