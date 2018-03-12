#!/bin/bash

INTROMESSAGE="Providing service status for mediaservers."
RED="\\033[0;31m"
NC="\\033[0m" # No Color
GREEN="\\033[0;32m"

# Display extra logging info
VERBOSE=FALSE

MY_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Read in the list of services from the services file.
# If it doesn't exist, we'll just check for nginx
if [ ! -f "${MY_PATH}/services" ]; then
	SERVICES=(
		"nginx"
	)
else
	readarray -t SERVICES < "${MY_PATH}/services"
fi

logger -t MediaServers -p syslog.info "${INTROMESSAGE}"
echo "${INTROMESSAGE}"

for index in "${!SERVICES[@]}"; do
	if (( $(ps -ef | grep -v grep | grep -c "${SERVICES[index]}") > 0 ))
	then
		service "${SERVICES[index]}" status
		# If we've selected verbose output, log the passing services to syslog.
		if [ "$VERBOSE" = TRUE ] ; then
			logger -t MediaServers -p syslog.notice "${SERVICES[index]} is running."
		fi
	else
		# Print out the service with a red fail beside it, and then log it to our syslog error log.
		echo -e "${SERVICES[index]} running: ${RED}FAIL${NC}"
		logger -p syslog.error "${SERVICES[index]} is NOT running."
	fi

done
