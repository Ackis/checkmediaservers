#!/bin/bash

# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp

INTROMESSAGE="Checking run state of media/game servers."
RED="\\033[0;31m"
NC="\\033[0m" # No Color
GREEN="\\033[0;32m"

if [ ! -f services ]; then
	SERVICES=(
		"nginx"
	)
else
	readarray -t SERVICES < services
fi

if [ ! -f nmakey ]; then
	echo "No NMA Key"
	NMAKEY=""
else
	NMAKEY=$(head -n 1 nmakey)
fi

logger -t MediaServers -p syslog.info "${INTROMESSAGE}"
echo "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	if (( $(ps -ef | grep -v grep | grep -c "${SERVICES[index]}") > 0 ))
	then
		echo -e "${SERVICES[index]} running: ${GREEN}PASS${NC}"
		logger -t MediaServers -p syslog.notice "${SERVICES[index]} is running."
	else
		echo -e "${SERVICES[index]} running: ${RED}FAIL${NC}"
		logger -p syslog.error "${SERVICES[index]} is NOT running."
		if [ -z "$NMAKEY" ];
		then
			echo "No NMA key, skipping notification."
		else
			/opt/scripts/notifymyandroid/nma.sh "MediaServers" "${SERVICES[index]}" "${SERVICES[index]} is not running."
		fi
	fi

done
