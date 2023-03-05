#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050_extension-backups-11900"
max_jobs=50 # should be 100
max_hours=20 # should be 24
num_nodes_per_job=1
minutes_per_job=15

h_list="`mktemp`"
find $runpath/run_prop_* -name 'prop_create_run_*.sh' | sort | while read i; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

tag="0"
runpath_props=""
while true; do
	runpath_props="$runpath/run_props_$tag"
	[ -d $runpath_props ] || break
	tag="$(( tag+1 ))"
done
runpath="$runpath_props"

mkdir -p $runpath

num_jobs="`cat $h_list | wc -w`"
num_bundle_jobs="$(( num_jobs<max_jobs ? num_jobs : max_jobs ))"
max_jobs_in_bundle="$(( (num_jobs+num_bundle_jobs-1)/num_bundle_jobs ))"
bundle_size="$(( (max_jobs_in_bundle*minutes_per_job + max_hours*60-1)/(max_hours*60) ))"
max_jobs_in_seq="$(( (max_jobs_in_bundle + bundle_size-1) / bundle_size ))"
cat << EOF > $runpath/run.sh
#!/bin/bash -l
#SBATCH -o $runpath/run_${tag}_%a.out
#SBATCH --account=p200054
#SBATCH -t $(( minutes_per_job*max_jobs_in_seq ))
#SBATCH --nodes=$(( num_nodes_per_job * bundle_size ))
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q default
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J gprop-batch-${tag}
#SBATCH --array=0-$((num_bundle_jobs-1))%100

`
	jobs_in_bundle=0
	bundle_id=0
	cat $h_list | while read i; do
		echo -n "$i "
		jobs_in_bundle="$(( jobs_in_bundle+1 ))"
		if [ $jobs_in_bundle -ge $max_jobs_in_bundle ]; then
			jobs_in_bundle=0
			echo
		fi
	done | while read bjs; do
		echo "if [ $bundle_id == \\\$SLURM_ARRAY_TASK_ID ] ; then"
		bundle_id="$((bundle_id + 1))"
		j="0"
		j_seq=0
		for i in $bjs; do
			echo -n "$i "
			j="$(( j+1 ))"
			if [ $j -ge $max_jobs_in_seq ]; then
				echo
				j=0;
			fi
		done | while read js; do
			echo "("
			for job in $js; do
				echo "MY_ARGS='-r $(( j_seq*num_nodes_per_job ))' bash -l $job"
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
cat << EOF > $runpath/run0.sh
#!/bin/bash -l
#SBATCH -o $runpath/run_${tag}_%a.out
#SBATCH --account=p200054
#SBATCH -t $(( minutes_per_job*max_jobs_in_seq ))
#SBATCH --nodes=$(( num_nodes_per_job * bundle_size ))
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q default
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J gprop-batch-${tag}
#SBATCH --array=0-$((num_bundle_jobs-1))%100

bash -l $runpath/run.sh
EOF

until sbatch $runpath/run0.sh > $runpath/run.sh.launched; do sleep 60; done && sleep 2
echo Launched bath job $tag with $num_jobs jobs
sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run.sh.launched`"
j="0"
cat $h_list | while read i; do
	echo ${sbatch_job_id}_$((j/max_jobs_in_bundle)) > ${i}.launched
	j="$(( j+1 ))"
done

rm $h_list
