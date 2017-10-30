#!/bin/bash

#wget "https://plex.tv/api/downloads/1.json" -O - 2>/dev/null | grep -oe '"label"[^}]*' | grep -v "Download" | grep "Ubuntu 64-bit" | sed 's/"label":"\([^"]*\)","build":"\([^"]*\)","distro":"\([^"]*\)","url":"\([^"]*\)".*/"\3" "\2" "\1" "\4"/' | uniq | sort

#sed 's/"url":"\([^"]*\)".*/"\1"/'

wget "https://plex.tv/api/downloads/1.json" -O - 2>/dev/null | grep -oe '"label"[^}]*' | grep -v "Download" | grep "Ubuntu 64-bit" | sed 's/"url":"\([^"]*\)".*/"\1"/' | uniq | sort

