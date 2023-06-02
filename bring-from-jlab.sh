#!/bin/bash

source ensembles.sh

sq="`mktemp`"
squeue -u $USER --array > $sq

tq="`mktemp`"
$jlab_ssh srmPendingRequest | grep -E -e "-> (pending|running)" | while read f crap; do echo $f; done > $tq
tape_reg="`mktemp`"
cache_reg="`mktemp`"
transfer_q="`mktemp`"
srmget_q="`mktemp`"

check_do_transfer() {
	do_transfer=1
	if ! [ -s ${1}.launched ]; then
		do_transfer=1
	else
		jobid="`cat ${1}.launched`"
		if [ $jobid == jlab-tape ]; then
			do_transfer=1
		elif grep -q "\<$jobid\>" $sq ; then
			do_transfer=0
		else
			do_transfer=1
		fi
	fi
	if [ $do_transfer == 1 ] && grep -q "\<${1#${confspath}/}\>" $tape_reg ; then
		echo ${1#${confspath}/} >> $transfer_q
	fi
}

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Get the files relevant for the ensemble that are on tape
	zphase=0.00 # set to a dummy value
	path_to_inspect=""
	[ $lime_transfer_from_jlab == yes ] && path_to_inspect+="$( dirname `lime_file_name` )"
	[ $eigs_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `eig_file_name` )"
	for t_source in $prop_t_sources; do
		for zphase in $prop_zphases; do
			[ $prop_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `prop_file_name` )"
		done
	done
	for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
			[ $gprop_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `gprop_file_name` )"
		done
	done
	for zphase in $baryon_zphases; do
		[ $baryon_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `baryon_file_name` )"
	done
	for zphase in $meson_zphases; do
		[ $meson_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `meson_file_name` )"
	done
	[ $disco_transfer_from_jlab == yes ] && path_to_inspect+=" $( dirname `disco_file_name` )"

	path_to_inspect="`for i in $path_to_inspect ; do echo $i; done | sort -u`"

	jlab_path_to_inspect=""
	for i in $path_to_inspect ; do
		jlab_path_to_inspect+=" $jlab_tape_registry/${i#${confspath}/}"
	done
	$jlab_ssh find $jlab_path_to_inspect -type f | sed "s@${jlab_tape_registry}/@@" > $tape_reg

	jlab_path_to_inspect=""
	for i in $path_to_inspect ; do
		jlab_path_to_inspect+=" $jlab_local/${i#${confspath}/}"
	done
	$jlab_ssh find $jlab_path_to_inspect -type f | sed "s@${jlab_local}/@@" > $cache_reg

	# Get all the files to transfer from jlab
	echo -n > $transfer_q
	for cfg in $confs; do
		[ $lime_transfer_from_jlab == yes ] && check_do_transfer "`lime_file_name`"
		[ $eigs_transfer_from_jlab == yes ] && check_do_transfer "`eigs_file_name`"
		for t_source in $prop_t_sources; do
			for zphase in $prop_zphases; do
				[ $prop_transfer_from_jlab == yes ] && check_do_transfer "`prop_file_name`"
			done
		done
		for t_source in $gprop_t_sources; do
			for zphase in $gprop_zphases; do
				[ $gprop_transfer_from_jlab == yes ] && check_do_transfer "`gprop_file_name`"
			done
		done
		for zphase in $baryon_zphases; do
			[ $baryon_transfer_from_jlab == yes ] && check_do_transfer "`baryon_file_name`"
		done
		for zphase in $meson_zphases; do
			[ $meson_transfer_from_jlab == yes ] && check_do_transfer "`meson_file_name`"
		done
		[ $disco_transfer_from_jlab == yes ] && check_do_transfer "`disco_file_name`"
	done # cfg

	# Gather the files to be brought back from tape with srmGet and do globus for the rest
	echo -n > $srmget_q
	cat $transfer_q | while read f; do
		# If the file is being back from tape, do nothing
		grep -q "\<$f\>" $tq && continue

		# If the file is not in cache, bring it back, otherwise start note the globus process
		if ! grep -q "\<$f\>" $cache_reg ; then
			echo ${jlab_local}/$f >> $srmget_q
		else
			mkdir -p `dirname ${confspath}/$f`
			echo ${confspath}/$f.globus ${jlab_ep}${f} ${this_ep}${f} nop > ${confspath}/$f.globus
			echo jlab-tape > ${confspath}/$f.launched 
		fi
	done

	# Call srmGet
	echo Files to recover from tape
	cat $srmget_q
	[ -s $srmget_q ] && $jlab_ssh srmGet `cat $srmget_q`
done # ens

rm -f $sq $tq $tape_reg $cache_reg $transfer_q $srmget_q
