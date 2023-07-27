#!/bin/bash

# Create the runpatch
runtag="0"
runpath=""
while true; do
	runpath="$PWD/runs/$runtag"
	[ -d $runpath ] || break
	runtag="$(( runtag+1 ))"
done
mkdir -p $runpath

source ensembles.sh

# Gather jobs to run
jobsfile=".jobs"
rm -f $jobsfile
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	runpathens="$PWD/${tag}"
	find $runpathens -name '*.sh' | while read f; do
		[ -f $f.launched ] || echo `bash $f class` $f >> $jobsfile
	done
done

last_c="_"
tag="0"
echo z 0 0 0 >> $jobsfile
sort $jobsfile | while read class max_mins nodes jobs_per_node job; do
	c="${class}_${max_mins}_${nodes}_${jobs_per_node}"
	if [ $c != $last_c ]; then
		[ $last_c != _ ] && echo
		echo -n $tag $max_mins $nodes $jobs_per_node
		tag="$(( tag+1 ))"
		last_c="$c"
	fi
	echo -n " $job"
done | while read jobtag minutes_per_job num_nodes_per_job num_jobs_per_node jobs; do
	# Execute the jobs
	for job in $jobs; do
		echo Executing $job
		bash $job
		touch ${job}.launched
	done
done

rm -f $jobsfile
