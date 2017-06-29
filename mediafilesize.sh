#!/bin/bash

MEDIADIR=(/media/*)

echo "Largest file sizes"

for index in "${!MEDIADIR[@]}"; do
	echo ""
	echo "${MEDIADIR[index]}"
	echo ""
	find "${MEDIADIR[index]}/" -type f -exec ls -sh {} \; | sort -h | tail -n 10
	echo ""
done

echo "Directory sizes"

for index in "${!MEDIADIR[@]}"; do
	du -sh "${MEDIADIR[index]}"/
done

