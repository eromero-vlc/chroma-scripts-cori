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

# Syntax:
#  k_split n f0 f1 f2 ...
# Print the given fi arguments but maximum `n` on each line

k_split() {
	local n i f
	n="$1"
	shift
	i="0"
	for f in "$@" "__last_file__"; do
		if [ $f != "__last_file__" ]; then
			echo -n "$f "
			i="$(( i+1 ))"
			if [ $i == $n ]; then
				i="0"
				echo
			fi
		else
			[ $i != 0 ] && echo
		fi
	done
}

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
	# Remove the tracking for all files that are going to be created
	for j in $jobs; do
		for f in `bash $j outs`; do
			rm -f ${f}.launched
		done
	done

	# Wrap jobs that need a fraction of a node into full node jobs
	actual_jobs="$jobs"
	if [ $num_jobs_per_node != 1 ]; then
		k_split $num_jobs_per_node $actual_jobs | while read first_job jobs_in_a_node; do
			wrapup_job="${first_job%.sh}.sh_aux"
			wrapup_job_aux="${first_job%.sh}.sh_auxx"
			cat << EOF > $wrapup_job
#!/bin/bash
srun \$MY_ARGS -n 1 -N 1 bash -l $wrapup_job_aux
EOF

			cat << EOF > $wrapup_job
#!/bin/bash
`
			j="0"
			for job in $first_job $jobs_in_a_node; do
				echo "MY_JOB_INDEX=$j bash -l $job run &"
				j="$(( j+1 ))"
			done
`
wait
EOF
		done
		jobs="`k_split $num_jobs_per_node $actual_jobs | while read first_job jobs_in_a_node; do echo ${first_job%.sh}.sh_aux; done | tr '\n' ' '`"
	fi
	
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
	bundle_id=0
	k_split $max_jobs_in_bundle $jobs | while read bjs; do
		echo "if [ $bundle_id == \\\$SLURM_ARRAY_TASK_ID ] ; then"
		bundle_id="$((bundle_id + 1))"
		j_seq=0
		k_split $max_jobs_in_seq $bjs | while read js; do
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
		for j in $actual_jobs; do
			for f in $( bash $j deps ); do
				[ -f ${f}.launched ] && cat ${f}.launched
			done
		done | sort -u | awk '\$0 !~ /jlab-tape/ {print}' | paste -sd ":"
	)"
	[ x$dep_jobs != x ] && echo "#SBATCH -d after:$dep_jobs"
`

bash -l $runpath/run_${jobtag}_script.sh
EOF

	until sbatch $runpath/run_${jobtag}.sh > $runpath/run_${jobtag}.sh.launched; do sleep 60; done && sleep 2
	echo Launched bath job ${runtag}-${jobtag} with $num_jobs jobs
	sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run_${jobtag}.sh.launched`"
	ji="0"
	for j in $actual_jobs; do
		for f in $j $( bash $j outs ); do
			echo ${sbatch_job_id}_$((ji/(max_jobs_in_bundle*num_jobs_per_node))) > ${f}.launched
		done
		ji="$(( ji+1 ))"
	done
done

rm -f $jobsfile
