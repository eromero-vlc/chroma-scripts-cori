#!/bin/bash

#. ~/py3/bin/activate
export PATH=$HOME/.local/bin:$PATH

while true; do
	date
	echo "Current state of the queue"
	squeue -u $USER
	echo "Checking..."
	bash create_genprop_check.sh
	bash create_genprop_clean.sh
	date
	echo "Going to sleep"
	sleep $(( 60*30 ))
done
