#!/bin/bash

# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp

INTROMESSAGE="Checking run state of media/game servers."
RED="\\033[0;31m"
NC="\\033[0m" # No Color
GREEN="\\033[0;32m"
SCRIPT_HOME="/opt/scripts/mediaservers"

# Display extra logging info
VERBOSE=FALSE

# Command line parameters:
#	-v:		Verbose mode
#	-h:		Display help
MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ "$1" != "" ]; do
	case $1 in
		-v | --verbose )		shift
						VERBOSE=TRUE
						echo "Verbose mode enabled."
						;;
		-h | --help )			echo "Help TBD"
						exit
						;;
		* )				shift
						VERBOSE=FALSE
	esac
	shift
done

# Read in the list of services from the services file.
# Check the directory where the script is being run for the file.
# Then check the default directory for the file.
# If we haven't found it, just check for nginx.
if [ -f "${MY_PATH}/services" ]; then
        readarray -t SERVICES < "${MY_PATH}/services"
elif [ -f "${SCRIPT_HOME}/services" ]; then
        readarray -t SERVICES < "${SCRIPT_HOME}/services"
else
	SERVICES=(
		"nginx"
	)
fi

# Read in your Notify My Android key from the nmakey file.
# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp

if [ -f "${MY_PATH}/nmakey" ]; then
	NMAKEY=$(head -n 1 "${MY_PATH}/nmakey")
elif [ -f "${SCRIPT_HOME}/nmakey" ]; then
	NMAKEY=$(head -n 1 "${SCRIPT_HOME}/nmakey")
else
	echo "No NMA Key"
	NMAKEY=""
fi

logger -t MediaServers -p syslog.info "${INTROMESSAGE}"
echo "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	if (( $(ps -ef | grep -v grep | grep -c "${SERVICES[index]}") > 0 ))
	then
		# Print out the service with a green pass.
		echo -e "${SERVICES[index]} running: ${GREEN}PASS${NC}"
		# If we've selected verbose output, log the passing services to syslog.
		if [ "$VERBOSE" = TRUE ] ; then
			logger -t MediaServers -p syslog.notice "${SERVICES[index]} is running."
		fi
	else
		# Print out the service with a red fail beside it, and then log it to our syslog error log.
		echo -e "${SERVICES[index]} running: ${RED}FAIL${NC}"
		logger -p syslog.error "${SERVICES[index]} is NOT running."
		# If we have a Notify My Android key, send a notification.
		if [ -z "$NMAKEY" ];
		then
			echo "No NMA key, skipping notification."
		else
			echo '/opt/scripts/notifymyandroid/nma.sh "MediaServers" "${SERVICES[index]}" "${SERVICES[index]} is not running."'
		fi
	fi

done
