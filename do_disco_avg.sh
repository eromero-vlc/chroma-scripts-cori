#!/bin/bash

source ensembles.sh

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

merge_cfgs="`mktemp`"
err="`mktemp`"

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	num_color_parts="$(( (disco_max_colors + disco_max_colors_at_once-1) / disco_max_colors_at_once ))"

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		for t_source in $disco_t_sources; do
			disco_files="$(
				for color_part in `seq 0 $(( num_color_parts-1 ))`; do
					disco_file_name
				done
			)"
			if ! ls $lime_file $disco_files &> /dev/null ; then
				echo Excluding $cfg
				continue
			fi

			disco_file_avg="`color_part=avg disco_file_name`"
			$dbavg_disco $disco_file_avg $disco_files
		done
	done
done
