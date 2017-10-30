#!/bin/bash

if [ ! -f plextoken ]; then
	echo "No Plex Token"
	exit 1
else
	readarray -t PLEXTOKEN < plextoken
fi

plex2netflix -t "${PLEXTOKEN}" --country ca
