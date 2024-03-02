#!/bin/bash

source ensembles.sh

redstar_files="`mktemp`"
merge_files="`mktemp`"
merge_cfgs="`mktemp`"
err="`mktemp`"
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue

	all_moms_2pt=""
	all_moms_3pt=""
	if [ $redstar_2pt == yes ]; then
		all_moms_2pt="`
			echo "$redstar_2pt_moms" | while read mom; do
				[ $(num_args $mom) == 3 ] && mom_word $mom
			done | sort -u
		`"

	fi
	if [ $redstar_3pt == yes ]; then
		all_moms_3pt="`
			echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
				[ $(num_args $momij) == 6 ] && mom_word $momij
			done | sort -u
		`"
	fi

	num_t_sources="`num_args $prop_t_sources`"
	cfg="@CFG"
	t_source="@SRC"
	for zphase in $prop_zphases; do
		for insertion_op in "_2pt_" $redstar_insertion_operators; do
			[ ${redstar_2pt} != yes -a ${insertion_op} == _2pt_ ] && continue
			[ ${redstar_3pt} != yes -a ${insertion_op} != _2pt_ ] && continue
			all_moms="$all_moms_2pt"
			[ ${insertion_op} != _2pt_ ] && all_moms="$all_moms_3pt"

			echo "$all_moms" | while read momw; do
				mom="${momw//_/ }"
				[ $(num_args $mom) == 0 ] && continue
				corr_file_name
			done # momw
		done # insertion_op
	done > $redstar_files  # zphase

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue
		file="$( for t_source in $prop_t_sources ; do
			sed "s/@CFG/${cfg}/g;s/@SRC/${t_source}/g" ${redstar_files}
		done )"
		if ls $files &> /dev/null ; then
			echo $cfg
		else
			echo Excluding $cfg >&2
		fi
	done > $merge_cfgs 2> $err
	cat $err

	for zphase in $prop_zphases; do
		for insertion_op in "_2pt_" $redstar_insertion_operators; do
			[ ${redstar_2pt} != yes -a ${insertion_op} == _2pt_ ] && continue
			[ ${redstar_3pt} != yes -a ${insertion_op} != _2pt_ ] && continue
			all_moms="$all_moms_2pt"
			[ ${insertion_op} != _2pt_ ] && all_moms="$all_moms_3pt"

			echo "$all_moms" | while read momw; do
				mom="${momw//_/ }"
				[ $(num_args $mom) == 0 ] && continue

				for t_source in $prop_t_sources ; do
					cfg_number=0
					for cfg in `cat $merge_cfgs`; do
						echo $cfg_number `corr_file_name`
						cfg_number="$(( cfg_number+1 ))"
					done > ${merge_files}
					corr_file_avg="`cfg= corr_file_name | sed 's/sdb/edb/g'`"
					echo creating $corr_file_avg
					mkdir -p `dirname $corr_file_avg`
					rm -f $corr_file_avg
					$dbmerge $corr_file_avg $merge_files 4000
				done

				corr_file_avg="`cfg= t_source=avg corr_file_name | sed 's/sdb/edb/g'`"
				echo creating final $corr_file_avg
				mkdir -p `dirname $corr_file_avg`
				rm -f $corr_file_avg
				$dbavgsrc $corr_file_avg `for t_source in $prop_t_sources ; do cfg= corr_file_name | sed 's/sdb/edb/g' ; done`

				# Extract the content
				(
					cd `dirname $corr_file_avg`
					$dbutil $corr_file_avg keysxml keys.xml
					$dbutil $corr_file_avg get keys.xml
				)
			done # momw
		done # insertion_op
	done # zphase
done # ens
