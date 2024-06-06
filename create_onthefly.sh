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

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		t_sources="all"
		[ ${onthefly_all_tsources_per_job} != yes ] && t_sources="$gprop_t_sources"

		for t_source in $t_sources; do
		for zphase in $gprop_zphases; do
		k_split $max_moms_per_job $moms | while read mom_group ; do

			mom_leader="`take_first $mom_group`"
			real_t_source="${t_source}"
			[ ${onthefly_all_tsources_per_job} == yes ] && real_t_source="$gprop_t_sources"

			baryon_script="${runpath}/baryon_${zphase}_t0_${t_source}_mf${mom_leader}.sh.future"
			gprop_scripts=""
			[ $run_gprops == yes ] && gprop_scripts="$( for t in $real_t_source; do echo ${runpath}/gprop_t${t}_z${zphase}_mf${mom_leader}.sh.future ; done )"
			prop_scripts=""
			[ $run_props == yes ] && prop_scripts="$( for t in $real_t_source; do echo ${runpath}/prop_t${t}_z${zphase}.sh.future ; done )"

			redstar_tasks="$( for t in $real_t_source ; do ls $runpath/redstar_t${t}_*_z${zphase}_mf${mom_leader}.sh.future ; done )"
			num_redstar_tasks="$( num_args $redstar_tasks )"
			[ $num_redstar_tasks == 0 ] && continue

			prefix="onthfly_t${t_source}_z${zphase}_mf${mom_leader}"
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
`
	for gprop_script in $gprop_scripts ; do
		echo bash $gprop_script run
		echo sleep 30
	done
`
	if [ $run_baryons == yes ] ; then
		bash $baryon_script run
		sleep 30
	fi
`
	for prop_script in $prop_scripts ; do
		echo bash $prop_script run
		echo sleep 30
	done
`

	$slurm_script_prologue_redstar
	t="\$(mktemp)"
	cat << 'EOFA' > \$t
`
	i=0
	k_split_lines $(( slurm_procs_per_node*onthefly_slurm_nodes )) $redstar_tasks | while read js ; do
		for j in $js ; do
			echo "[ \\\$OMPI_COMM_WORLD_LOCAL_RANK == $i ] && bash $j run"
		done
		i="$((i+1))"
	done
`
true # return success!
EOFA
	srun -n $(( slurm_procs_per_node*onthefly_slurm_nodes )) \$MY_ARGS bash \$t
	rm -fr $localpath/*
}

check() {
	[ $run_baryons != yes ] || bash $baryon_script check || exit 1
`
	for t in $gprop_scripts $prop_scripts $redstar_tasks; do
		echo "bash $t check || exit 1"
	done
`
	exit 0
}

blame() {
	[ $run_baryons != yes ] || bash $baryon_script blame || exit 1
`
	for t in $gprop_scripts $prop_scripts $redstar_tasks; do
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

		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
