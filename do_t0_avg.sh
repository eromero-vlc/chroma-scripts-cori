#!/bin/bash

source ensembles.sh

redstar_dat_mom() {
	echo "${1}${2}${3}"
}

redstar_dat_mom_snk() {
	echo "${1}${2}${3}"
}

redstar_dat_mom_src() {
	echo "${4}${5}${6}"
}

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

redstar_files="`mktemp`"
merge_files="`mktemp`"
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

	if [ ${redstar_2pt} == yes -a ${redstar_3pt} == yes ] ; then
		echo "Unsupported to compute 2pt and 3pt on the fly at once"
		exit 1
	fi
	mom_groups="`
		(
			[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms"
			[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom"
		) | while read momij; do
			[ $(num_args $momij) -gt 0 ] && mom_word $( mom_fly $momij )
		done | sort -u
	`"

	mom_leaders="$(
		k_split $max_moms_per_job $mom_groups | while read mom_group ; do
			take_first $mom_group
		done
	)"

	if [ ${redstar_3pt} == yes ] ; then
		tsep_groups="$( for tsep in $gprop_t_seps ; do echo $tsep ; done | sort -u -n )"
		[ x${max_tseps_per_job} == x ] && max_tseps_per_job="$( num_args $tsep_groups )"
	else
		tsep_groups=0
		max_tseps_per_job=1
	fi

	tsep_leaders="$(
		k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do
			take_first $tsep_group
		done
	)"

	num_insertion_operators=1
	[ $redstar_3pt == yes ] && num_insertion_operators="$( num_args $redstar_insertion_operators)"
	num_mom_leaders="$( num_args $mom_groups )"
	max_combo_lines="$(( num_insertion_operators*num_mom_leaders ))"
	max_combo_lines="$(( max_combo_lines > slurm_procs_per_node*redstar_slurm_nodes ? slurm_procs_per_node*redstar_slurm_nodes : max_combo_lines ))"
	num_t_sources="`num_args $prop_t_sources`"
	cfg="@CFG"
	t_source="@SRC"
	for zphase in $prop_zphases; do
		for (( insertion_op=0 ; insertion_op < max_combo_lines ; ++insertion_op )) ; do
			for momw in $mom_leaders; do
				for tsep in $tsep_leaders; do
					mom="${momw//_/ }" corr_file_name
				done # tsep
			done # momw
		done # insertion_op
	done > $redstar_files  # zphase

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		if ! [ -f $lime_file ] ; then
			echo Excluding $cfg >&2
			continue
		fi
		files="$( for t_source in $prop_t_sources ; do
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
		for (( insertion_op=0 ; insertion_op < max_combo_lines ; ++insertion_op )) ; do
			for tsep in $tsep_leaders; do
				for momw in $mom_leaders; do
					mom="${momw//_/ }"

					for t_source in $prop_t_sources ; do
						cfg_number=0
						for cfg in `cat $merge_cfgs`; do
							echo $cfg_number `corr_file_name`
							cfg_number="$(( cfg_number+1 ))"
						done > ${merge_files}
						corr_file_avg="`cfg= corr_file_name | sed 's/sdb/edb/g'`"
						echo creating $corr_file_avg
						echo ">" $dbmerge $corr_file_avg $merge_files 4000
						cat $merge_files
						mkdir -p `dirname $corr_file_avg`
						rm -f $corr_file_avg
						$dbmerge $corr_file_avg $merge_files 4000
					done

					corr_file_avg="`cfg= t_source=avg corr_file_name | sed 's/sdb/edb/g'`"
					echo creating final $corr_file_avg
					mkdir -p `dirname $corr_file_avg`
					rm -f $corr_file_avg
					$dbavgsrc $corr_file_avg $( for t_source in $prop_t_sources ; do echo $( cfg= corr_file_name | sed 's/sdb/edb/g' ) ; done )

					# Extract the content
					(
						cd $tmp_dat_dir
						rm $tmp_dat_dir/*
						$dbutil $corr_file_avg keysxml $keys
						$dbutil $corr_file_avg get $keys
						if [ ${redstar_2pt} == yes ] ; then
							echo "$redstar_2pt_moms" | while read mom ; do
								[ $( num_args $mom ) -ne 3 ] && continue
								proper_corr_file_avg="`cfg= t_source=avg corr_file_name`"
								new_dat_files_dir="`dirname $proper_corr_file_avg`"
								mkdir -p $new_dat_files_dir
								mv *,$( redstar_dat_mom $mom ),*,$( redstar_dat_mom $mom ),*.dat $new_dat_files_dir
							done
						elif [ ${redstar_3pt} == yes ] ; then
							echo "$redstar_3pt_snkmom_srcmom" | while read snk_src_mom ; do
								[ $( num_args $snk_src_mom ) -ne 6 ] && continue
								proper_corr_file_avg="`cfg= t_source=avg mom="$snk_src_mom" corr_file_name`"
								new_dat_files_dir="`dirname $proper_corr_file_avg`"
								mkdir -p $new_dat_files_dir
								mv *,$( redstar_dat_mom_snk $snk_src_mom ),*,$( redstar_dat_mom_src $snk_src_mom ),*.dat $new_dat_files_dir
							done
						fi
					)
				done # momw
			done # tsep
		done # insertion_op
	done # zphase
done # ens
