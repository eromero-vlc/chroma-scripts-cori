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
echo z 0 0 >> $jobsfile
sort $jobsfile | while read class max_mins nodes job; do
	c="${class}_${max_mins}_${nodes}"
	if [ $c != $last_c ]; then
		[ $last_c != _ ] && echo
		echo -n $tag $max_mins $nodes
		tag="$(( tag+1 ))"
		last_c="$c"
	fi
	echo -n " $job"
done | while read jobtag minutes_per_job num_nodes_per_job jobs; do
	# Remove the tracking for all files that are going to be created
	for j in $jobs; do
		for f in `bash $j outs`; do
			rm -f ${f}.launched
		done
	done
	
	# total jobs to run
	num_jobs="`echo $jobs | wc -w`"
	[ $num_jobs == 0 ] && continue
	# total SLURM jobs to launch
	num_bundle_jobs="$(( num_jobs<max_jobs ? num_jobs : max_jobs ))"
	# maximum number of jobs running on a single SLURM job
	max_jobs_in_bundle="$(( (num_jobs+num_bundle_jobs-1)/num_bundle_jobs ))"
	# maximum number of parallel jobs inside a SLURM job
	bundle_size="$(( (max_jobs_in_bundle*minutes_per_job + max_hours*60-1)/(max_hours*60) ))"
	# maximum number of jobs executed one after another in a SLURM job
	max_jobs_in_seq="$(( (max_jobs_in_bundle + bundle_size-1) / bundle_size ))"
	cat << EOF > $runpath/run_${jobtag}_script.sh
`
	jobs_in_bundle=0
	bundle_id=0
	for i in $jobs "lastjob"; do
		if [ $i == lastjob ]; then
			[ $jobs_in_bundle -gt 0 ] && echo
		else
			echo -n "$i "
			jobs_in_bundle="$(( jobs_in_bundle+1 ))"
			if [ $jobs_in_bundle -ge $max_jobs_in_bundle ]; then
				jobs_in_bundle=0
				echo
			fi
		fi
	done | while read bjs; do
		echo "if [ $bundle_id == \\\$SLURM_ARRAY_TASK_ID ] ; then"
		bundle_id="$((bundle_id + 1))"
		j="0"
		j_seq=0
		for i in $bjs lastjob; do
			if [ $i == lastjob ]; then
				[ $j -gt 0 ] && echo
			else
				echo -n "$i "
				j="$(( j+1 ))"
				if [ $j -ge $max_jobs_in_seq ]; then
					echo
					j=0;
				fi
			fi
		done | while read js; do
			echo "("
			for job in $js; do
				echo "MY_ARGS='-r $(( j_seq*num_nodes_per_job ))' bash -l $job run"
			done
			echo ") &"
			j_seq="$(( j_seq+1 ))"
		done
		echo fi
	done
`
wait
EOF

	# If the batch file is too large, slurm complains
	cat << EOF > $runpath/run_${jobtag}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/run_${jobtag}_%a.out
#SBATCH -t $(( minutes_per_job*max_jobs_in_seq ))
#SBATCH --nodes=$(( num_nodes_per_job * bundle_size ))
#SBATCH -J batch-${tag}
#SBATCH --array=0-$((num_bundle_jobs-1))%100
`
	dep_jobs="$(
		for j in $jobs; do
			for f in $( bash $j deps ); do
				[ -f ${f}.launched ] && cat ${f}.launched
			done
		done | sort -u | paste -sd ":"
	)"
	[ x$dep_jobs != x ] && echo "#SBATCH -d after:$dep_jobs"
`

bash -l $runpath/run_${jobtag}_script.sh
EOF

	until sbatch $runpath/run_${jobtag}.sh > $runpath/run_${jobtag}.sh.launched; do sleep 60; done && sleep 2
	echo Launched bath job ${runtag}-${jobtag} with $num_jobs jobs
	sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run_${jobtag}.sh.launched`"
	ji="0"
	for j in $jobs; do
		for f in $j $( bash $j outs ); do
			echo ${sbatch_job_id}_$((ji/max_jobs_in_bundle)) > ${f}.launched
		done
		ji="$(( ji+1 ))"
	done
done

rm -f $jobsfile
