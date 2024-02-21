#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running on the fly
	[ $run_onthefly != yes -o $run_redstar != yes ] && continue

	moms="`
		(
			[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms"
			[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom"
		) | while read momij; do
			[ $(num_args $momij) -gt 0 ] && mom_word $( mom_fly $momij )
		done | sort -u
	`"

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
		k_split $max_moms_per_job $moms | while read mom_group ; do

			mom_leader="`take_first $mom_group`"
			baryon_script="${runpath}/baryon_${zphase}_t0_${t_source}_mf${mom_leader}.sh.future"
			gprop_script="${runpath}/gprop_t${t_source}_z${zphase}_mf${mom_leader}.sh.future"
			prop_script="${runpath}/prop_t${t_source}_z${zphase}.sh.future"

			redstar_tasks="$( for mom in $mom_group; do ls $runpath/redstar_t${t_source}_*_z${zphase}_mf${mom}.sh.future; done )"
			num_redstar_tasks="$( num_args $redstar_tasks )"
			[ $num_redstar_tasks == 0 ] && continue

			prefix="onthfly_t${t_source}_z${zphase}_mf${mom_leader}"
			output="$runpath/${prefix}.out"
			local_aux="${localpath}/${runpath//\//_}_${prefix}.aux"
			cat << EOF > $runpath/${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/${prefix}.out0
#SBATCH -t $onthefly_chroma_minutes
#SBATCH --nodes=$onthefly_slurm_nodes -n $(( slurm_procs_per_node*onthefly_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J onthefly-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	if [ $run_gprops == yes ] ; then
		bash $gprop_script run
		sleep 30
	fi
	if [ $run_baryons == yes ] ; then
		bash $baryon_script run
		sleep 30
	fi
	if [ $run_props == yes ] ; then
		bash $prop_script run
		sleep 30
	fi
	if [ $run_gprops == yes -a $gprop_slurm_nodes -gt 1 ] || [ $run_baryons == yes -a $baryon_slurm_nodes -gt 1 ] ; then
		$anarchofs &
		sleep 10
	fi

	cat << EOFo > ${local_aux}
`
	i=0
	k_split $(( (num_redstar_tasks + slurm_procs_per_node*gprop_slurm_nodes-1 ) / (slurm_procs_per_node*gprop_slurm_nodes) )) $redstar_tasks | while read js ; do
		echo "$i bash -c 'for t in $js; do bash \\\\\\\$t run; done'"
		i="$((i+1))"
	done
`
EOFo
	srun -n $(( num_redstar_tasks < slurm_procs_per_node*gprop_slurm_nodes ? num_redstar_tasks : slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS --gpu-bind=closest -K0 -k -W0 --multi-prog ${local_aux}
}

check() {
	[ $run_gprops != yes ] || bash $gprop_script check || exit 1
	[ $run_baryons != yes ] || bash $baryon_script check || exit 1
	[ $run_props != yes ] || bash $prop_script check || exit 1
`
	for t in $redstar_tasks; do
		echo "bash $t check || exit 1"
	done
`
	exit 0
}

blame() {
	[ $run_gprops != yes ] || bash $gprop_script blame || exit 1
	[ $run_baryons != yes ] || bash $baryon_script blame || exit 1
	[ $run_props != yes ] || bash $prop_script blame || exit 1
`
	for t in $redstar_tasks; do
		echo "bash $t check || echo fail $t"
	done
`
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
`
	for t in $redstar_tasks; do
		echo bash $t deps
	done
`
}

outs() {
	echo -n
`
	for t in $redstar_tasks; do
		echo bash $t outs
	done
`
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo d $onthefly_chroma_minutes $onthefly_slurm_nodes 1 0
}

globus() {
	echo -n
`
	for t in $redstar_tasks; do
		echo bash $t globus
	done
`
}

eval "\${1:-run}"
EOF

		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
