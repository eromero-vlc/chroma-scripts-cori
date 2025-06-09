#!/bin/bash

check() {
	while true ; do
		bash check.sh &
		program_pid=$!
		sleep $(( 60*10 ))
		if ps -p $program_pid > /dev/null ; then
    			kill -9 $program_pid
		else
			break
		fi
	done
}

while true; do
	date
	echo "Current state of the queue"
	squeue -u $USER
	echo "Checking..."
	#check
	bash check.sh
	#echo "Packing..."
	#bash do_pack.sh
	#bash launch.sh
	date
	echo "Going to sleep"
	sleep $(( 60*30 ))
done
