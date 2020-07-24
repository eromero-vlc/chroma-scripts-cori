#!/bin/bash

nodes_per_job=1
max_jobs=1      # maximum jobs running at the same time from a user
max_nodes=4   # maximum nodes running at the same time from a user

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

h_list="`mktemp`"
for i in `ls $runpath/run_eigs_*/run.bash`; do
	[ -f ${i}.launched ] || echo $i
done > $h_list

num_jobs="`cat $h_list | wc -l`"
batch_size="$(( (num_jobs + max_jobs - 1) / max_jobs ))"
if [ $(( batch_size * nodes_per_job )) -gt $max_nodes ]; then
	batch_size="$((max_nodes / nodes_per_job ))"
fi

tag="0"
runpath_eigs=""
while true; do
	runpath_eigs="$runpath/run_eigss_$tag"
	[ -d $runpath_eigs ] || break
	tag="$(( tag+1 ))"
done
runpath="$runpath_eigs"

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
#SBATCH -t 2:00:00
#SBATCH --nodes $(( batch_jobs_size * nodes_per_job ))
#SBATCH --ntasks-per-node=32
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH --constraint=haswell
#SBATCH -J eigs-batch-${tag}-${jobi}
#DW jobdw capacity=$(( 16 * batch_size ))GB access_mode=striped type=scratch

`
	j="0"
	for i in $batch_jobs; do
		echo MY_OFFSET=\"-r $j\" bash $i "&> ${i%.bash}.out &"
		j="$(( j+1 ))"
	done
`
wait
EOF

	echo Launching bath job $jobi with $batch_jobs_size jobs
	until sbatch $runpath/run_${jobi}.sh > $runpath/run_${jobi}.sh.launched; do sleep 60; done
	sbatch_job_id="`awk '/Submitted/ {print $4}' $runpath/run_${jobi}.sh.launched`"
	for i in $batch_jobs; do
		echo $sbatch_job_id > ${i}.launched
	done
	sleep 1
	
	jobi="$(( jobi+1 ))"
done

rm $h_list	
