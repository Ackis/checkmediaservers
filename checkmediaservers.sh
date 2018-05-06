#!/bin/bash


# These are the only variables you should need to change to customize your script
# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp
INTROMESSAGE="Checking run state of media/game servers."
SCRIPT_HOME="/opt/scripts/mediaservers"
NMA_SCRIPT="/opt/scripts/notifymyandroid/nma.sh"

# Constants used within the script.
PAD_CHARACTER="." # What type of character do you want to use to pad output?
PAD_LENGTH=60 # How much padding do you want?

pad=$(printf "%0.1s" "${PAD_CHARACTER}"{1..60})
SCRIPT_NAME="$0"
MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Colours to use in the script
BLK='\033[0;30m' # Black
RED='\033[0;31m' # Red
GRN='\033[0;32m' # Green
BLU='\033[0;34m' # Blue
CYA='\033[0;36m' # Cyan
WHI='\033[0;37m' # White
YEL='\033[0;33m' # Yellow
PUR='\033[0;35m' # Purple
NC="\\033[0m" # No Colour

# Display extra logging info
VERBOSE=false
USE_NMA=false
LOG=true

function display_help() {
	echo "Help WIP"
	echo "-n|--usenma:		Use NMA to send notifications (NYI)"
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
			logger -t MediaServers -p "syslog.${2}" "${1}"
		else
			logger -t MediaServers -p syslog.debug "$1"
		fi
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
			shift
			echo "Using NMA to send notifications."
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
	print_and_log "${SCRIPT_NAME}: services file found at ${MY_PATH}/services." "debug"
        readarray -t SERVICES < "${MY_PATH}/services"
elif [ -f "${SCRIPT_HOME}/services" ]; then
	print_and_log "${SCRIPT_NAME}: services file found at ${SCRIPT_HOME}/services." "debug"
        readarray -t SERVICES < "${SCRIPT_HOME}/services"
else
	print_and_log "${SCRIPT_NAME}: no services file found, using default." "debug"
	SERVICES=(
		"nginx"
	)
fi

# Read in your Notify My Android key from the nmakey file.
# Notify My Android Script located here: http://www.notifymyandroid.com/dev.jsp

if [ -f "${MY_PATH}/nmakey" ]; then
	print_and_log "${SCRIPT_NAME}: nma key found at ${MY_PATH}/nmakey."
	NMA_KEY=$(head -n 1 "${MY_PATH}/nmakey")
elif [ -f "${SCRIPT_HOME}/nmakey" ]; then
	print_and_log "${SCRIPT_NAME}: nma key found at ${SCRIPT_HOME}/nmakey."
	NMA_KEY=$(head -n 1 "${SCRIPT_HOME}/nmakey")
else
	print_and_log "${SCRIPT_NAME}: No nma key found. Not using nma."
	NMA_KEY=""
	USE_NMA=false
fi

print_and_log "${INTROMESSAGE}"

# Do we want to use nma?
if [ "${USE_NMA}" = true ] ; then
	if [ -f "${NMA_SCRIPT}" ]; then
		USE_NMA=true
	else
		print_and_log  "${SCRIPT_NAME}: No NMA key found, and option to send notifications is enabled. Not sending a notification."
		USE_NMA=false
	fi
fi

for index in "${!SERVICES[@]}"; do
	TEXT_LENGTH=${#SERVICES[index]}
	printf "%s " "${SERVICES[index]}"
	#systemctl status $1 | awk 'NR==3' | awk '{print $2}'
	if (( $(ps -ef | grep -v grep | grep -c "${SERVICES[index]}") > 0 ))
	then
		printf "${YEL}%*.*s${NC}" 0 $((PAD_LENGTH - TEXT_LENGTH - 4)) "$pad"
		printf " [ $GRN%b$NC ]\n" "PASS"
		print_and_log "${SCRIPT_NAME}: ${SERVICES[index]} is running." "info"
	else
		printf "${YEL}%*.*s${NC}" 0 $((PAD_LENGTH - TEXT_LENGTH - 4)) "$pad"
		printf " [ $RED%b$NC ]\n" "FAIL"
		print_and_log "${SCRIPT_NAME}: ${SERVICES[index]} is NOT running." "alert"

		if [ "${USE_NMA}" = true ] ; then
			NMA_CMD="\"MediaServers\" ${SERVICES[index]} \"${SERVICES[index]} is not running.\""
			# For some reason the script errors out if I put all of that on one line.
			print_and_log "${SCRIPT_NAME}: Calling NMA: ${NMA_CMD}" "debug"
			# NMA script errors out if I pass NMA_CMD to it.
			/opt/scripts/notifymyandroid/nma.sh "MediaServers" "${SERVICES[index]}" "${SERVICES[index]} is not running."
		fi
	fi

done
