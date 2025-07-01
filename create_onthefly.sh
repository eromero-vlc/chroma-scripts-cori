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
		[ -f ${runpath}.tar.gz ] && continue
		mkdir -p $runpath

		for phase in $( get_all_phases ) ; do
		k_split $max_moms_per_job $( get_fly_moms $phase ) | while read mom_group ; do
		k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do
		for t_source in $gprop_t_sources; do

			mom_leader="`take_first $mom_group`"
			tsep_leader="`take_first $tsep_group`"
			baryon_script="$runpath/baryon_ph${phase}_t0_${t_source}_mf${mom_leader}.sh.future"
			gprop_script="${runpath}/gprop_t${t_source}_phase${phase}_mf${mom_leader}_tsep${tsep_leader}.sh.future"
			prop_script="${runpath}/prop_t${t_source}_phase${phase}.sh.future"

			redstar_tasks="$( ls $runpath/redstar_t${t_source}_ph${phase}_insop*_mf${mom_leader}_tsep${tsep_leader}.sh.future )"
			num_redstar_tasks="$( num_args $redstar_tasks )"
			[ $num_redstar_tasks == 0 ] && continue
			redstar_procs="$(( num_redstar_tasks < slurm_procs_per_node*onthefly_slurm_nodes ? num_redstar_tasks : slurm_procs_per_node*onthefly_slurm_nodes ))"
			redstar_nodes="$(( num_redstar_tasks < onthefly_slurm_nodes ? num_redstar_tasks : onthefly_slurm_nodes ))"

			prefix="onthfly_t${t_source}_ph${phase}_mf${mom_leader}_tsep${tsep_leader}"
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
	#rm -rf $localpath/*
	[ \$SLURM_PROCID == 0 ] && echo starting > $output
	if [ $run_gprops == yes -a -f $gprop_script ] ; then
		bash $gprop_script run
	fi
	[ \$SLURM_PROCID == 0 ] && echo after gprop >> $output
	[ \$SLURM_PROCID == 0 ] && find ${localpath} &>> $output
	if [ $run_baryons == yes ] ; then
		bash $baryon_script run
	fi
	[ \$SLURM_PROCID == 0 ] && echo after baryon >> $output
	[ \$SLURM_PROCID == 0 ] && find ${localpath} &>> $output
	if [ $run_props == yes ] ; then
		bash $prop_script run
	fi
	[ \$SLURM_PROCID == 0 ] && echo after prop >> $output
	[ \$SLURM_PROCID == 0 ] && find ${localpath} &>> $output

	$slurm_script_prologue_redstar
	export ROCR_VISIBLE_DEVICES=\$SLURM_PROCID
`
	i=0
	k_split_lines $(( slurm_procs_per_node*onthefly_slurm_nodes )) $redstar_tasks | while read j ; do
		echo "[ \\\$SLURM_PROCID == $i ] && bash $BASH_INVOCATION_OPTIONS $j run"
		i="$((i+1))"
	done
`
}

check() {
	[ $run_gprops != yes -o ! -f $gprop_script ] || bash $gprop_script check || exit 1
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
	[ $run_gprops != yes  -o ! -f $gprop_script ] || bash $gprop_script blame || exit 1
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

		done # t_source
		done # tsep_group
		done # mom_group
		done # phase
	done # cfg
done # ens
