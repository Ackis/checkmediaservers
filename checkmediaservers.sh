#!/bin/bash

# These are the only variables you should need to change to customize your script
INTROMESSAGE="Checking run state of media/game servers."
CONFIG_DIR="/home/jpasula/.config/mediaservers"
SERVICES_FILE="${CONFIG_DIR}/services"
SCRIPT_NAME="checkmediaservers"
NOTIFICATION_SCRIPT="/opt/scripts/misc/pushbullet.sh"

# Constants used within the script.
# What type of character do you want to use to pad output?
PAD_CHARACTER="."
# How much padding do you want?
PAD_LENGTH=60 # How much padding do you want?
PAD=$(printf "%0.1s" "${PAD_CHARACTER}"{1..60})

# Internal script variables
SCRIPT_COMMAND="$0"
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Colours to use in the script
RED='\033[0;31m' # Red
GRN='\033[0;32m' # Green
YEL='\033[0;33m' # Yellow
NC="\\033[0m" # No Colour

# Display extra logging info
VERBOSE=false
LOG=true
NOTIFY=true

function display_help() {
	echo "Help WIP"
	echo "-v|--verbose:		Verbose mode"
	echo "-h|--help:		Display help"
}

function print_and_log() {
	# If we weren't passed an argument, fail.
	if [ -z "${1}" ] ; then
		echo "Error: No parameter passed to print_and_log. Function needs at least one string."
		return 1
	fi

	# If verbose is enabled, spout more text.
	if [ "${VERBOSE}" = true ] ; then
		# We can assume we have an argument here
		echo "${1}"
	fi

	# Do we want to log?
	if [ "${LOG}" = true ] ; then
		# Were we passed a second argmument?
		if [ ! -z "${2}" ] ; then
			logger -t "${SCRIPT_PATH}${SCRIPT_COMMAND}" -p "syslog.${2}" "${1}"
		else
			logger -t "${SCRIPT_PATH}${SCRIPT_COMMAND}" -p syslog.debug "$1"
		fi
	fi
}

# Command line parameters:
#	-v|--verbose:		Verbose mode
#	-h|--help:		Display help

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
		* )
			VERBOSE=false
			shift
	esac
done

# Read in the list of services from the services file.
# Check the directory where the script is being run for the file.
# Then check the default directory for the file.
# If we haven't found it, just check for nginx.

if [ -f "${SCRIPT_PATH}/services" ]; then
	print_and_log "${SCRIPT_NAME}: services file found at ${SCRIPT_PATH}/services." "debug"
        readarray -t SERVICES < "${SCRIPT_PATH}/services"
elif [ -f "${SERVICES_FILE}" ]; then
	print_and_log "${SCRIPT_NAME}: services file found at ${SERVICES_FILE}." "debug"
	readarray -t SERVICES < "${SERVICES_FILE}"
else
	print_and_log "${SCRIPT_NAME}: no services file found, using default." "debug"
	SERVICES=(
		"nginx"
	)
fi

# Sort the array
IFS=$'\n' SERVICES=($(sort <<<"${SERVICES[*]}"))
unset IFS

print_and_log "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	TEXT_LENGTH=${#SERVICES[index]}
	printf "%s " "${SERVICES[index]}"
	#systemctl status $1 | awk 'NR==3' | awk '{print $2}'
	if (( $(ps -ef | grep -v grep | grep -c -i "${SERVICES[index]}") > 0 ))
	then
		printf "${YEL}%*.*s${NC}" 0 $((PAD_LENGTH - TEXT_LENGTH - 4)) "$PAD"
		printf " [ $GRN%b$NC ]\n" "PASS"
		print_and_log "${SCRIPT_NAME}: ${SERVICES[index]} is running." "info"
	else
		printf "${YEL}%*.*s${NC}" 0 $((PAD_LENGTH - TEXT_LENGTH - 4)) "$PAD"
		printf " [ $RED%b$NC ]\n" "FAIL"
		print_and_log "${SCRIPT_NAME}: ${SERVICES[index]} is NOT running." "alert"
		if [ "${NOTIFY}" = true ] ; then
			if [ -f "${NOTIFICATION_SCRIPT}" ]; then
				"${NOTIFICATION_SCRIPT}" "Warning - ${SERVICES[index]} not warning" "This is a warning to let you know that ${SERVICES[index]} is currently not running."
			fi
		fi
	fi

done
