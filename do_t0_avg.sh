#!/bin/bash

source ensembles.sh

redstar_dat_mom() {
	echo "${1}${2}${3}"
}

redstar_dat_mom_snk() {
	redstar_dat_mom ${1} ${2} ${3}
}

redstar_dat_mom_src() {
	redstar_dat_mom ${4} ${5} ${6}
}

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

redstar_files="`mktemp`"
merge_cfgs="`mktemp`"
err="`mktemp`"
keys="`mktemp`"
tmp_dat_dir="`mktemp -d`"

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue
	[ ${redstar_2pt} != yes -a ${redstar_3pt} != yes ] && continue

	get_grouping_vars

	num_t_sources="`num_args $prop_t_sources`"
	cfg="@CFG"
	t_source="@SRC"
	k_split $max_phases_per_job $phase_groups | while read phase_group ; do
	phase_leader="`take_first $phase_group`"
	k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do
		tsep_leader="`take_first $tsep_group`"

		k_split $max_moms_per_job $( get_fly_moms $phase_group ) | while read this_all_moms ; do
			mom_leader="`take_first $this_all_moms`"
			combo_line=0
			k_split_lines $(( slurm_procs_per_node*redstar_slurm_nodes )) $( get_corr_lines $this_all_moms ) | while read insert_op_mom_combos ; do
				mom="${mom_leader//_/ }" insertion_op=${combo_line} tsep=$tsep_leader corr_file_name
				combo_line="$(( combo_line+1 ))"
			done # insert_op_mom_combos
		done # this_all_moms
	done # tsep_group
	done > $redstar_files # phase_group

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		if ! [ -f $lime_file ] ; then
			echo "Excluding $cfg : missing lime file $lime_file" >&2
			continue
		fi
		files="$( for t_source in $prop_t_sources ; do
			sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" ${redstar_files}
		done )"
		if ls $files &> /dev/null ; then
			echo $cfg
		else
			echo Excluding $cfg >&2
			for f in $files ; do [ ! -f $f ] && echo "Missing file" $f >&2 ; done
		fi
	done > $merge_cfgs 2> $err
	cat $err

	corr_dir="$( dirname $( cfg= corr_file_name ) )/aux"
	rm -rf $corr_dir
	mkdir -p $corr_dir
	for redstar_file in `cat ${redstar_files}` ; do 
	for t_source in $prop_t_sources ; do
	(
		merge_files="`mktemp`"
		cfg_number=0
		for cfg in `cat $merge_cfgs`; do
			echo $cfg_number $( echo $redstar_file | sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" )
			cfg_number="$(( cfg_number+1 ))"
		done > ${merge_files}
		corr_file_avg="$corr_dir/$( basename $( echo $redstar_file | sed "s/@CFG/all/g;s/@SRC/${t_source}/g" ) )"
		mkdir -p `dirname $corr_file_avg`
		echo creating $corr_file_avg
		echo ">" $dbmerge $corr_file_avg $merge_files 4000
		#cat $merge_files
		rm -f $corr_file_avg
		$dbmerge $corr_file_avg $merge_files 4000 || exit -1
	) &
	done # t_source
	done # redstar_file
	wait

	for redstar_file in `cat ${redstar_files}` ; do 
		files="$( for t_source in $prop_t_sources ; do
			echo $corr_dir/$( basename $( echo $redstar_file | sed "s/@CFG/all/g;s/@SRC/${t_source}/g" ) )
		done )"
		corr_file_avg="$corr_dir/$( basename $( echo $redstar_file | sed "s/@CFG/all/g;s/@SRC/all/g" ) )"
		echo creating final $corr_file_avg
		rm -f $corr_file_avg
		$dbavgsrc $corr_file_avg $files
	done # redstar_file

	# Extract the content
	for redstar_file in `cat ${redstar_files}` ; do 
		cd $tmp_dat_dir
		rm -f $tmp_dat_dir/*
		corr_file_avg="$corr_dir/$( basename $( echo $redstar_file | sed "s/@CFG/all/g;s/@SRC/all/g" ) )"
		echo openning $corr_file_avg
		$dbutil $corr_file_avg keysxml $keys
		$dbutil $corr_file_avg get $keys
		if [ ${redstar_3pt} == yes ] ; then
			echo "$redstar_3pt_snkmom_srcmom" | while read snk_src_mom ; do
				[ $( num_args $snk_src_mom ) -ne 6 ] && continue
				proper_corr_file_avg="`cfg= t_source=avg mom="$snk_src_mom" corr_file_name`"
				new_dat_files_dir="`dirname $proper_corr_file_avg`"
				mkdir -p $new_dat_files_dir
				mv *,$( redstar_dat_mom_snk $snk_src_mom ),*,$( redstar_dat_mom_src $snk_src_mom ),*.dat $new_dat_files_dir &> /dev/null
			done
		fi
		if [ ${redstar_2pt} == yes ] ; then
			echo "$redstar_2pt_moms" | while read mom ; do
				[ $( num_args $mom ) -ne 6 ] && continue
				proper_corr_file_avg="`cfg= t_source=avg corr_file_name`"
				new_dat_files_dir="`dirname $proper_corr_file_avg`"
				mkdir -p $new_dat_files_dir
				mv *,$( redstar_dat_mom_snk $mom ),*,$( redstar_dat_mom_src $mom ),*.dat $new_dat_files_dir &> /dev/null
			done
		fi
		ls
	done # redstar_file
done # ens
