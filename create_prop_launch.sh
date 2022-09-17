#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2390_m0p2050"
max_jobs=100
h_list="`mktemp`"
for i in `ls $runpath/run_prop_*/prop_create_run_*.sh|sort`; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

num_jobs="`cat $h_list | wc -l`"

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
max_jobs_in_bundle="$(( (num_jobs+max_jobs-1)/max_jobs ))"
cat << EOF > $runpath/run.sh
#!/bin/bash -l
#SBATCH -o $runpath/run_${tag}_%a.out
#SBATCH --account=p200054
#SBATCH -t $(( 30*max_jobs_in_bundle ))
#SBATCH --nodes=1
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q default
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J gprop-batch-${tag}
#SBATCH --array=0-$((num_bundle_jobs-1))%100

`
	j="0"
	cat $h_list | while read i; do
		echo "if [ $(( j / max_jobs_in_bundle )) == \\\$SLURM_ARRAY_TASK_ID ] ; then bash -l $i ; fi"
		j="$(( j+1 ))"
	done
`
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
