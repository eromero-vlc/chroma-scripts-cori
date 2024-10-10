#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running on the fly
	[ $run_onthefly != yes -o $run_redstar != yes ] && continue

	# Get the number of nodes to run
	onthefly_slurm_nodes=1
	[ $run_props == yes -a $onthefly_slurm_nodes -lt $prop_slurm_nodes ] && onthefly_slurm_nodes="$prop_slurm_nodes"
	[ $run_gprops == yes -a $onthefly_slurm_nodes -lt $gprop_slurm_nodes ] && onthefly_slurm_nodes="$gprop_slurm_nodes"

	moms="`
		(
			[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms"
			[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom"
		) | while read momij; do
			[ $(num_args $momij) -gt 0 ] && mom_word $( mom_fly $momij )
		done | sort -u
	`"

	if [ ${redstar_3pt} == yes ] ; then
		tsep_groups="$( for tsep in $gprop_t_seps ; do echo $tsep ; done | sort -u -n )"
		[ x${max_tseps_per_job} == x ] && max_tseps_per_job="$( num_args $tsep_groups )"
		
	else
		tsep_groups=0
		max_tseps_per_job=1
	fi

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
		k_split $max_moms_per_job $moms | while read mom_group ; do
		k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do

			mom_leader="`take_first $mom_group`"
			tsep_leader="`take_first $tsep_group`"
			baryon_script="${runpath}/baryon_${zphase}_t0_${t_source}_mf${mom_leader}.sh.future"
			gprop_script="${runpath}/gprop_t${t_source}_z${zphase}_mf${mom_leader}_tsep${tsep_leader}.sh.future"
			prop_script="${runpath}/prop_t${t_source}_z${zphase}.sh.future"

			redstar_tasks="$( ls $runpath/redstar_t${t_source}_*_z${zphase}_mf${mom_leader}_tsep${tsep_leader}.sh.future )"
			num_redstar_tasks="$( num_args $redstar_tasks )"
			[ $num_redstar_tasks == 0 ] && continue

			prefix="onthfly_t${t_source}_z${zphase}_mf${mom_leader}_tsep${tsep_leader}"
			output="$runpath/${prefix}.out"
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

	$slurm_script_prologue_redstar
	srun -n $(( slurm_procs_per_node*onthefly_slurm_nodes )) -N $onthefly_slurm_nodes \$MY_ARGS --gpu-bind=closest -K0 -k -W0 bash -c '
`
	i=0
	k_split_lines $(( slurm_procs_per_node*onthefly_slurm_nodes )) $redstar_tasks | while read j ; do
		echo "[ \\\$SLURM_PROCID == $i ] && bash $j run"
		i="$((i+1))"
	done
`
'
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
		break
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

		done # tsep_group
		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
