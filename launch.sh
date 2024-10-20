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

# Gather the current jobs running
sq="`mktemp`"
squeue -u $USER --array > $sq

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
echo z 0 0 0 0 >> $jobsfile
sort $jobsfile | while read class max_mins nodes jobs_per_node max_concurrent_jobs job; do
	c="${class}_${max_mins}_${nodes}_${jobs_per_node}_${max_concurrent_jobs}"
	if [ $c != $last_c ]; then
		[ $last_c != _ ] && echo
		echo -n $tag $max_mins $nodes $jobs_per_node ${max_concurrent_jobs}
		tag="$(( tag+1 ))"
		last_c="$c"
	fi
	echo -n " $job"
done | while read jobtag minutes_per_job num_nodes_per_job num_jobs_per_node max_concurrent_jobs jobs; do
	# Remove the tracking for all files that are going to be created
	for j in $jobs; do
		rm -f $( for f in `bash $j outs`; do echo ${f}.launched; done )
	done

	# Wrap jobs that need a fraction of a node into full node jobs
	actual_jobs="$jobs"
	if [ $num_jobs_per_node != 1 ]; then
		k_split $num_jobs_per_node $actual_jobs | while read first_job jobs_in_a_node; do
			wrapup_job="${runpath}/${first_job//\//_}.sh_aux"
			cat << EOF > $wrapup_job
#!/bin/bash -l
. $first_job environ
srun \$MY_ARGS -N1 -n$num_jobs_per_node --gpu-bind=closest -K0 -k -W0  bash $BASH_INVOCATION_OPTIONS -c "$(
			j="0"
			for job in $first_job $jobs_in_a_node; do
				echo -n "[ \\\$SLURM_PROCID == $j ] && MY_JOB_INDEX=$j bash $BASH_INVOCATION_OPTIONS $job run; "
				j="$(( j+1 ))"
			done
)"
EOF
		done
		jobs="`k_split $num_jobs_per_node $actual_jobs | while read first_job jobs_in_a_node; do echo -n "${runpath}/${first_job//\//_}.sh_aux "; done`"
		max_concurrent_jobs="$(( max_concurrent_jobs / num_jobs_per_node ))"
	fi
	
	# total jobs to run
	num_jobs="`echo $jobs | wc -w`"
	[ $num_jobs == 0 ] && continue
	# Max sequential jobs in a SLURM job
	max_jobs_in_seq="$(( max_hours*60 / minutes_per_job ))"
	# minimum number of jobs to run
	max_concurrent_jobs="$(( max_concurrent_jobs == 0 ? slurm_max_bundled_jobs : ( max_concurrent_jobs < slurm_max_bundled_jobs ? max_concurrent_jobs : slurm_max_bundled_jobs ) ))"
	min_slurm_jobs="$(( max_concurrent_jobs == 0 ? 0 : num_jobs / (max_concurrent_jobs*max_jobs_in_seq) ))"
	# total SLURM jobs to launch
	num_slurm_jobs="$(( num_jobs<max_jobs ? num_jobs : max_jobs ))"
	num_slurm_jobs="$(( num_slurm_jobs < min_slurm_jobs ? min_slurm_jobs : num_slurm_jobs ))"
	# maximum number of jobs running on a single SLURM job
	max_jobs_in_bundle="$(( (num_jobs+num_slurm_jobs-1)/num_slurm_jobs ))"
	# maximum number of parallel jobs inside a SLURM job
	bundle_size="$(( (max_jobs_in_bundle + max_jobs_in_seq-1)/max_jobs_in_seq ))"
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
				echo "MY_ARGS='-r $(( j_seq*num_nodes_per_job ))' bash $BASH_INVOCATION_OPTIONS $job run"
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
	while true; do
		cat << EOF > $runpath/run_${jobtag}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/run_${jobtag}_%a.out
#SBATCH -t $(( minutes_per_job*max_jobs_in_seq ))
#SBATCH --nodes=$(( num_nodes_per_job * bundle_size )) --ntasks-per-node=$(( num_jobs_per_node == 1 ? slurm_procs_per_node : num_jobs_per_node ))
#SBATCH --threads-per-core=1 --cpus-per-task=$(( slurm_cores_per_node/(num_jobs_per_node == 1 ? slurm_procs_per_node : num_jobs_per_node) )) # number of cores per task
#SBATCH --gpus-per-task=$(( slurm_gpus_per_node/(num_jobs_per_node == 1 ? slurm_procs_per_node : num_jobs_per_node) ))
#SBATCH -J batch-${tag}
#SBATCH --array=0-$((num_slurm_jobs-1))
`
	dep_jobs="$(
		# Update the queued jobs
		squeue -u $USER --array > $sq
		for j in $actual_jobs; do
			for f in $( bash $j deps ); do
				echo $f
			done
		done | sort -u | while read f; do
			[ -f ${f}.launched ] && cat ${f}.launched
		done | sort -u | while read slurm_job; do
			grep -q "\<${slurm_job}\>" $sq && echo $slurm_job
		done | paste -sd ":"
	)"
	[ x$dep_jobs != x ] && echo "#SBATCH -d afterok:$dep_jobs"
`

# Launching ${num_jobs}
bash $BASH_INVOCATION_OPTIONS $runpath/run_${jobtag}_script.sh
exit 0 # always return ok no matter the actual result
EOF

		sbatch $runpath/run_${jobtag}.sh > $runpath/run_${jobtag}.sh.launched && break
		sleep 60
	done
	echo Launched bath job ${runtag}-${jobtag} with $num_jobs jobs
	sleep 10
	sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run_${jobtag}.sh.launched`"
	ji="0"
	for j in $actual_jobs; do
		for f in $j $( bash $j outs ); do
			echo ${sbatch_job_id}_$((ji/(max_jobs_in_bundle*num_jobs_per_node))) > ${f}.launched
		done
		ji="$(( ji+1 ))"
	done
	# Update the queued jobs
	squeue -u $USER --array > $sq
done

rm -f $jobsfile
