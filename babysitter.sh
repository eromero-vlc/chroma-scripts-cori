#!/bin/bash

while true; do
	date
	echo "Current state of the queue"
	squeue -u $USER
	echo "Checking..."
	bash check.sh
	date
	echo "Going to sleep"
	sleep $(( 60*15 ))
done
