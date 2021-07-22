#!/bin/bash

#. ~/py3/bin/activate
export LANG=en_US.utf8

while true; do
	date
	echo "Current state of the queue"
	bjobs
	echo "Checking..."
	bash chroma-scripts-cori/create_genprop_check.sh
	bash chroma-scripts-cori/create_genprop_clean.sh
	date
	echo "Going to sleep"
	sleep $(( 60*30 ))
done
