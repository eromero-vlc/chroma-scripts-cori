#!/bin/bash

while true; do
	date
	echo "Current state of the queue"
	squeue -u $USER
	echo "Checking..."
	bash check.sh
	echo "Packing..."
	#bash do_pack.sh
	#bash launch.sh
	date
	echo "Going to sleep"
	sleep $(( 60*30 ))
done
