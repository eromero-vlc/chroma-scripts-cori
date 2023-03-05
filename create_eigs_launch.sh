#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050_extension-backups-11900"
max_jobs=20
h_list="`mktemp`"
for i in `ls $runpath/run_eigs_*/*.sh|sort`; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

num_jobs="`cat $h_list | wc -l`"

tag="0"
runpath_eigs=""
while true; do
	runpath_eigs="$runpath/run_eigss_$tag"
	[ -d $runpath_eigs ] || break
	tag="$(( tag+1 ))"
done
runpath="$runpath_eigs"

mkdir -p $runpath

num_jobs="`cat $h_list | wc -w`"
num_bundle_jobs="$(( num_jobs<max_jobs ? num_jobs : max_jobs ))"
max_jobs_in_bundle="$(( (num_jobs+max_jobs-1)/max_jobs ))"
cat << EOF > $runpath/run.sh
#!/bin/bash -l
#SBATCH -o $runpath/run_${tag}_%a.out
#SBATCH --account=p200054
#SBATCH -t $(( 10*60 ))
#SBATCH --nodes=$(( 1 * max_jobs_in_bundle ))
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q default
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J eigs-batch-${tag}
#SBATCH --array=0-$((num_bundle_jobs-1))%100

`
	j="0"
	cat $h_list | while read i; do
		echo "if [ $(( j / max_jobs_in_bundle )) == \\\$SLURM_ARRAY_TASK_ID ] ; then bash -l $i & fi"
		j="$(( j+1 ))"
	done
`
wait
EOF

until sbatch $runpath/run.sh > $runpath/run.sh.launched; do sleep 60; done && sleep 2
echo Launched bath job $tag with $num_jobs jobs
sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run.sh.launched`"
j="1"
cat $h_list | while read i; do
	echo ${sbatch_job_id}_$j > ${i}.launched
	j="$(( j+1 ))"
done

rm $h_list	
