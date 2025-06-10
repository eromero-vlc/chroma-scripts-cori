#!/bin/bash

source ensembles.sh

redstar_dat_mom() {
	ph=( $( mom_auto_phase $@ ) )
	mt="$( momtype $@ | tr -d ' ' )"
	if [ ${ph[0]}${ph[1]}${ph[2]} == 000 ] ; then
		echo "${1}${2}${3},*__${mt}"
	else
		echo "${1}${2}${3},*__${mt}ph${ph[0]}${ph[1]}${ph[2]}"
	fi
}

redstar_dat_mom_snk() {
	redstar_dat_mom ${1} ${2} ${3}
}

redstar_dat_mom_src() {
	redstar_dat_mom ${4} ${5} ${6}
}

rename_moms() {
	[ $# == 3 ] && echo "mom$1.$2.$3"
	[ $# == 6 ] && echo "snk$1.$2.$3src$4.$5.$6"
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

		k_split $max_moms_per_job $( get_fly_moms $phase ) | while read this_all_moms ; do
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
	#for cfg in $confs; do
	#	lime_file="`lime_file_name`"
	#	if ! [ -f $lime_file ] ; then
	#		echo Excluding $cfg >&2
	#		continue
	#	fi
	#	files="$( for t_source in $prop_t_sources ; do
	#		sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" ${redstar_files}
	#	done )"
	#	if ls $files &> /dev/null ; then
	#		echo $cfg
	#	else
	#		echo Excluding $cfg >&2
	#	fi
	#done > $merge_cfgs 2> $err
	#cat $err

	#for t_source in $prop_t_sources ; do
	#for redstar_file in `cat ${redstar_files}` ; do 
	#(
	#	merge_files="`mktemp`"
	#	cfg_number=0
	#	for cfg in `cat $merge_cfgs`; do
	#		echo $cfg_number $( echo $redstar_file | sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" )
	#		cfg_number="$(( cfg_number+1 ))"
	#	done > ${merge_files}
	#	corr_file_avg="$( echo $redstar_file | sed "s/t0_/tavg_/g;s/@CFG/all/g;s/@SRC/${t_source}/g" )"
	#	mkdir -p `dirname $corr_file_avg`
	#	echo creating $corr_file_avg
	#	echo ">" $dbmerge $corr_file_avg $merge_files 4000
	#	#cat $merge_files
	#	rm -f $corr_file_avg
	#	$dbmerge $corr_file_avg $merge_files 4000 || exit -1
	#	rm -f $merge_files
	#) &
	#done # redstar_file
	#wait
	#done # t_source

	#for redstar_file in `cat ${redstar_files}` ; do 
	#	files="$( for t_source in $prop_t_sources ; do
	#		echo $redstar_file | sed "s/t0_/tavg_/g;s/@CFG/all/g;s/@SRC/${t_source}/g"
	#	done )"
	#	corr_file_avg="$( echo $redstar_file | sed "s/t0_/tavg_/g;s/@CFG/all/g;s/@SRC/all/g" )"
	#	mkdir -p `dirname $corr_file_avg`
	#	echo creating final $corr_file_avg
	#	rm -f $corr_file_avg
	#	$dbavgsrc $corr_file_avg $files
	#done # redstar_file

	# Extract the content
	corr_file="$PWD/corr.tar"
	rm -f $corr_file
	tar cf $corr_file ensembles.sh
	for redstar_file in `cat ${redstar_files}` ; do 
		cd $tmp_dat_dir
		rm $tmp_dat_dir/*
		corr_file_avg="$( echo $redstar_file | sed "s/t0_/tavg_/g;s/@CFG/all/g;s/@SRC/all/g" )"
		echo openning $corr_file_avg
		$dbutil $corr_file_avg keysxml $keys
		$dbutil $corr_file_avg get $keys
		if [ ${redstar_3pt} == yes ] ; then
			echo "$redstar_3pt_snkmom_srcmom" | while read snk_src_mom ; do
				[ $( num_args $snk_src_mom ) -ne 6 ] && continue
				new_dat_files_dir="$( rename_moms $snk_src_mom )"
				mkdir -p $new_dat_files_dir
				if mv *,$( redstar_dat_mom_snk $snk_src_mom ).*,$( redstar_dat_mom_src $snk_src_mom ).dat $new_dat_files_dir &> /dev/null ; then
					ls $new_dat_files_dir
					tar rf $corr_file $new_dat_files_dir/
				fi
				rm -r $new_dat_files_dir
			done
		fi
		if [ ${redstar_2pt} == yes ] ; then
			echo "$redstar_2pt_moms" | while read mom ; do
				[ $( num_args $mom ) -ne 3 ] && continue
				new_dat_files_dir="$( rename_moms $mom )"
				mkdir -p $new_dat_files_dir
				echo mv "*,$( redstar_dat_mom $mom ).*,$( redstar_dat_mom $mom ).dat"
				if mv *,$( redstar_dat_mom $mom ).*,$( redstar_dat_mom $mom ).dat $new_dat_files_dir &> /dev/null ; then
					ls $new_dat_files_dir
					tar rf $corr_file $new_dat_files_dir/
				fi
				rm -r $new_dat_files_dir
			done
		fi
		echo missing
		ls
	done # redstar_file
done # ens
