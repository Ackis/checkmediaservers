#!/bin/bash

if [ ~ -f netflixkey ]; then
	echo "No Netflix Key"
	exit 1
else
	readarry -t NETFLIXKEY < netflixkey
fi

plex2netflix -t "${NETFLIXKEY}" --country ca
