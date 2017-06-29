#!/bin/bash
SERVICES=(
	"ArchiSteamFarm"
	"calibre"
	"couchpotato"
	"sabnzbdplus"
	"minecraft"
	"mylar"
	"nginx"
	"ombi"
	"plexpy"
	"plexmediaserver"
	"sonarr"
	"starbound"
	"transmission"
	"ubooquity"
	"znc"
#	"zoneminder"
)


INTROMESSAGE="Checking run state of media/game servers."
RED="\033[0;31m"
NC="\033[0m" # No Color
GREEN="\033[0;32m"
NMAKEY="adfd0c0ccc32ffc5d558307a71fc946ae4a921e6572e1c80"

logger -t MediaServers -p syslog.info "${INTROMESSAGE}"
echo "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	#echo "Checking on ${SERVICES[index]}."
	#logger -t MediaServers -p syslog.notice "Checking on ${SERVICES[index]}."

	#service_status='stopped'
	#service ${SERVICES[index]} status &>/dev/null && service_status='running'
	#echo "${SERVICES[index]} is ${service_status}"

	if (( $(ps -ef | grep -v grep | grep "${SERVICES[index]}" | wc -l) > 0 ))
	then
		echo -e "${SERVICES[index]} running: ${GREEN}PASS${NC}"
		logger -t MediaServers -p syslog.notice "${SERVICES[index]} is running."
	else
		echo -e "${SERVICES[index]} running: ${RED}FAIL${NC}"
		logger -p syslog.error "${SERVICES[index]} is NOT running."
		/opt/scripts/notifymyandroid/nma.sh "MediaServers" "${SERVICES[index]}" "${SERVICES[index]} is not running." 2
	fi

done
