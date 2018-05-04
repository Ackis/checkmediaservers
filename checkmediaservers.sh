#!/bin/bash


# These are the only variables you should need to change to customize your script
# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp
INTROMESSAGE="Checking run state of media/game servers."
SCRIPT_HOME="/opt/scripts/mediaservers"
NMA_SCRIPT="/opt/scripts/notifymyandroid/nma.sh"

# Constants used within the script.
RED="\\033[0;31m"
NC="\\033[0m" # No Color
GREEN="\\033[0;32m"
SCRIPT_NAME="$0"
MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Display extra logging info
VERBOSE=false
USE_NMA=false
LOG=true

# Do we want to use nma?
if [ -f "${NMA_SCRIPT}" ]; then
	USE_NMA=true
else
	USE_NMA=false
fi

function display_help() {
	echo "Help WIP"
	echo "-n|--usenma:		Use NMA to send notifications (NYI)"
	echo "-v|--verbose:		Verbose mode"
	echo "-h|--help:		Display help"
}

function print_and_log() {
	if [ "${VERBOSE}" = true ] ; then
		echo "$1"
	fi
	if [ "${LOG}" = true ] ; then
		logger -t MediaServers -p syslog.debug "$1"
	fi
}

# Command line parameters:
#	-v|--verbose:		Verbose mode
#	-h|--help:		Display help
#	-n|--usenma:		Use NMA.
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-v | --verbose )
			VERBOSE=true
			shift
			echo "Verbose mode enabled."
			;;
		-h | --help )
			display_help
			exit 2
			;;
		-n | --usenma )
			USE_NMA=true
			echo "Using NMA to send notifications."
			shift
			;;
		* )
			VERBOSE=false
			shift
	esac
done

# Read in the list of services from the services file.
# Check the directory where the script is being run for the file.
# Then check the default directory for the file.
# If we haven't found it, just check for nginx.

if [ -f "${MY_PATH}/services" ]; then
	print_and_log "${SCRIPT_NAME}: services file found at ${MY_PATH}/services."
        readarray -t SERVICES < "${MY_PATH}/services"
elif [ -f "${SCRIPT_HOME}/services" ]; then
	print_and_log "${SCRIPT_NAME}: services file found at ${SCRIPT_HOME}/services."
        readarray -t SERVICES < "${SCRIPT_HOME}/services"
else
	print_and_log "${SCRIPT_NAME}: no services file found, using default."
	SERVICES=(
		"nginx"
	)
fi

# Read in your Notify My Android key from the nmakey file.
# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp

if [ -f "${MY_PATH}/nmakey" ]; then
	print_and_log "${SCRIPT_NAME}: nma key found at ${MY_PATH}/nmakey."
	NMAKEY=$(head -n 1 "${MY_PATH}/nmakey")
elif [ -f "${SCRIPT_HOME}/nmakey" ]; then
	print_and_log "${SCRIPT_NAME}: nma key found at ${SCRIPT_HOME}/nmakey."
	NMAKEY=$(head -n 1 "${SCRIPT_HOME}/nmakey")
else
	print_and_log "${SCRIPT_NAME}: No nma key found. Not using nma."
	NMAKEY=""
fi

logger -t MediaServers -p syslog.info "${INTROMESSAGE}"
echo "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	if (( $(ps -ef | grep -v grep | grep -c "${SERVICES[index]}") > 0 ))
	then
		echo -e "${SERVICES[index]} running: ${GREEN}PASS${NC}"
		print_and_log "${SERVICES[index]} is running."
	else
		echo -e "${SERVICES[index]} running: ${RED}FAIL${NC}"
		logger -p syslog.error "${SERVICES[index]} is NOT running."
		if [ "${USE_NMA}" = true ] ; then
			echo '/opt/scripts/notifymyandroid/nma.sh "MediaServers" "${SERVICES[index]}" "${SERVICES[index]} is not running."'
		else
			echo "No NMA key, skipping notification."
		fi
	fi

done
