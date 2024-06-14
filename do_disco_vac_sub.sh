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

	# Checking for configurations with all expected correlation functions
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		disco_file="`disco_file_name`"
		if [ ! -f $lime_file -o ! -f $disco_file ] ; then
			echo Excluding $cfg >&2
			continue
		fi
		echo $cfg
	done > $merge_cfgs 2> $err
	cat $err

	disco_vac="`disco_stage=vac cfg=vac disco_file_name`"
	mkdir -p $( dirname $disco_vac )
	$dbdisco_vac_sub $disco_vac average $(
		for cfg in `cat $merge_cfgs`; do
			echo "`disco_file_name`"
		done
	)
	$dbdisco_vac_sub $disco_vac subtract $(
		for cfg in `cat $merge_cfgs`; do
			echo "`disco_file_name`" "`disco_stage=vac disco_file_name`"
		done
	)
done
