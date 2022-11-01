#!/usr/bin/bash

# Author Yerbol Khassen
# 01 Jul 2022
# A script to automate backup local files to OneDrive using rclone
# Regular backups are run from crontab hourly.
# Checks are placed on connection so that script pauses an hour
# before retrying. Maximum trials are set to 12 to take into
# account some offline periods.
# New directories has to be added to the Backups array.
# rclone config is located at ~/.config/rclone/rclone.conf.
# Log files are stored at ~/.log directory.
# Repo is located https://gitlab.dataart.com/ykhassen/onedrive

function connected() {
	URL="https://microsoft.com"
	response=$(curl -L -s -w "%{http_code}" $URL)
	status=$(tail -n1 <<< "$response")
	echo ${status}
}

function backup() {
	declare -a Backups=("Documents" "Downloads" "gitlab" "Pictures" "Project")
	LOGS="${HOME}/.log/rclone-$(date +%Y%m%d).log"
   	if test -f "$LOGS"; then
		return 1
	else
		echo -n "" > $LOGS
    	TMP=`mktemp`
    	for folder in ${Backups[@]}; do
       		echo "=======================================" >> ${LOGS}
       		echo ${folder} >> ${LOGS}
       		rclone sync $HOME/${folder} onedrive:${folder} --progress --create-empty-src-dirs > ${TMP}
       		cat ${TMP} >> ${LOGS}
		done
    	echo "Sync completed " `date` >> ${LOGS}
    	rm ${TMP}
	fi
}

source /home/universe.dart.spb/ykhassen/.bashrc

for ((i=1; i<12; i++)); do
	if [ "$(connected)" == "200" ]; then
		backup
		exit
	else
		echo "No connection " `date` >> ${HOME}/.log/error.log 
	fi
	sleep 300
done

exit
