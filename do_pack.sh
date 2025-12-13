#!/bin/bash

source ensembles.sh

redstar_dat_mom_snk() {
	echo "${1}${2}${3}"
}

redstar_dat_mom_src() {
	echo "${4}${5}${6}"
}

redstar_files="`mktemp`"
merge_cfgs="`mktemp`"

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue
	[ ${redstar_2pt} != yes -a ${redstar_3pt} != yes ] && continue

	if [ ${redstar_3pt} == yes ] ; then
		tsep_groups="$( for tsep in $gprop_t_seps ; do echo $tsep ; done | sort -u -n )"
		[ x${max_tseps_per_job} == x ] && max_tseps_per_job="$( num_args $tsep_groups )"
	else
		tsep_groups=0
		max_tseps_per_job=1
	fi

	num_t_sources="`num_args $prop_t_sources`"
	cfg="@CFG"
	t_source="@SRC"
	for phase in $( get_all_phases ); do
	k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do
		tsep_leader="`take_first $tsep_group`"

		k_split $max_moms_per_job $( word_moms_filtered_by_phases $phase ) | while read this_all_moms ; do
			mom_leader="`take_first $this_all_moms`"
			combo_line=0
			k_split_lines $(( slurm_procs_per_node*redstar_slurm_nodes )) $( get_corr_lines $phase $this_all_moms ) | while read insert_op_mom_combos ; do
				mom="${mom_leader//_/ }" insertion_op=${combo_line} tsep=$tsep_leader corr_file_name
				combo_line="$(( combo_line+1 ))"
			done # insert_op_mom_combos
		done # this_all_moms
	done # tsep_group
	done > $redstar_files # phase

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		if ! [ -f $lime_file ] ; then
			continue
		fi
		runpath="$PWD/${tag}/conf_${cfg}"
		[ -f ${runpath}.tar.gz ] && continue

		# Check that all jobs finished
		s="$(
			find $runpath -name '*.sh' | while read f; do
				if [ ! -f $f.launched.verified ] ; then
					echo pending 
					break
				fi
			done
		)" 
		[ x$s == xpending ] && continue

		files="$( for t_source in $prop_t_sources ; do
			sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" ${redstar_files}
		done )"
		ls $files &> /dev/null || continue

		echo packing $cfg
		p="$( dirname $( pack_file_name ) )"
		tar czf `pack_file_name` -C $p ${files//$p\//} || exit -1
		rm $files
		tar czf ${runpath}.tar.gz -C $runpath . || exit -1
		rm -r $runpath
	done # cfg
done # ens
