#!/bin/bash

runpath="$PWD/cl21_48_128_b6p5_m0p2070_m0p1750"

h_list="`mktemp`"
for i in `ls $runpath/run_gprop_*/gprop_create_run_*.sh|sort`; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

num_jobs="`cat $h_list | wc -l`"

tag="0"
runpath_props=""
while true; do
	runpath_props="$runpath/run_genprops_$tag"
	[ -d $runpath_props ] || break
	tag="$(( tag+1 ))"
done
runpath="$runpath_props"

mkdir -p $runpath

num_jobs="`cat $h_list | wc -w`"
account="cib@gpu" # with --constraint=v100-16g
account="qjs@gpu" # with --constraint=v100-16g
cat << EOF > $runpath/run.sh
#!/bin/bash
#SBATCH -o $runpath/run_${tag}_%a.out
#SBATCH --account=$account
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=10
#SBATCH --hint=nomultithread
#SBATCH --time=3:00:00
#SBATCH --gres=gpu:4
#SBATCH -N 32
#SBATCH -J gprop-batch-${tag}
#SBATCH --exclusive
#SBATCH --constraint=v100-16g
#SBATCH --array=1-${num_jobs}%100

`
	j="1"
	cat $h_list | while read i; do
		echo "if [ \\\$SLURM_ARRAY_TASK_ID == $j ] ; then bash $i ; fi"
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
