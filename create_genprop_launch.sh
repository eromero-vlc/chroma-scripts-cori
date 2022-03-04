#!/bin/bash

nodes_per_job=72
max_jobs=1      # maximum jobs running at the same time from a user
max_nodes=1100   # maximum nodes running at the same time from a user

runpath="$PWD/cl21_48_96_b6p3_m0p2416_m0p2050"
runpath="$PWD/cl21_48_96_b6p3_m0p2416_m0p2050-1000"
runpath="$PWD/cl21_48_96_b6p3_m0p2416_m0p2050-1200"

h_list="`mktemp`"
for i in `ls $runpath/run_gprop_*/gprop_create_run_*.sh|sort`; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

num_jobs="`cat $h_list | wc -l`"
batch_size="$(( (num_jobs + max_jobs - 1) / max_jobs ))"
if [ $(( batch_size * nodes_per_job )) -gt $max_nodes ]; then
	batch_size="$((max_nodes / nodes_per_job ))"
fi

tag="0"
runpath_props=""
while true; do
	runpath_props="$runpath/run_genprops_$tag"
	[ -d $runpath_props ] || break
	tag="$(( tag+1 ))"
done
runpath="$runpath_props"

mkdir -p $runpath

jobi="0"
(
	j="0"
	for i in `cat $h_list`; do
		echo -n "$i "
		j="$(( j+1 ))"
		[ "$(( j % batch_size ))" -ne 0 ] || echo
	done
	echo
) | while read batch_jobs ; do

	echo "BATCH" $batch_jobs
	batch_jobs_size="`echo $batch_jobs | wc -w`"
	[ $batch_jobs_size -gt 0 ] || continue

	cat << EOF > $runpath/run_${jobi}.sh
#!/bin/bash
#SBATCH -o $runpath/run_${jobi}.out
#SBATCH -t 06:30:00
#SBATCH -N $(( batch_jobs_size * nodes_per_job ))
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH --ntasks-per-node=4
#SBATCH --constraint=knl
#SBATCH -J gprop-batch-${tag}-${jobi}
`
	cat $batch_jobs | awk '
		BEGIN {d="";a[0]=0;}
		/^#DEPENDENCY/ {if ($2 && !($2 in a)) {a[$2]=0;if (d) d=d ":" $2; else d=$2;}}
		END { if (d) print "#SBATCH -d afterok:" d;}'
`

`
	j="0"
	for i in $batch_jobs; do
		echo MY_OFFSET=\"-r $j\" bash $i "&"
		j="$(( j+nodes_per_job ))"
	done
`
wait
EOF

	echo Launching bath job $jobi with $batch_jobs_size jobs
	until sbatch $runpath/run_${jobi}.sh > $runpath/run_${jobi}.sh.launched; do sleep 60; done && sleep 2
	sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run_${jobi}.sh.launched`"
	for i in $batch_jobs; do
		echo $sbatch_job_id > ${i}.launched
	done
	
	jobi="$(( jobi+1 ))"
done

rm $h_list
