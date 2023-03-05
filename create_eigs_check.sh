#!/bin/bash

runpath="$PWD/cl21_48_96_b6p3_m0p2416_m0p2050-djm-3"

ok=0
fail=0
nan=0
running="`mktemp`"
squeue --array -u $USER > $running
for i in $runpath/run_eigs_*/*.launched ; do
	[ -f ${i%.sh.launched}.verified ] && continue
	output="${i%run.sh.launched}eig_create_run.out"
	if grep -E "\<`cat $i`\>" $running &> /dev/null ; then
		echo -n
	elif grep -q 'nan' $output &> /dev/null ; then
		echo Removing $i
		nan="$(( nan+1 ))"
		rm -f $i
	elif grep -q 'CHROMA: ran successfully' $output &> /dev/null ; then
		touch ${i%.sh.launched}.verified
		ok="$(( ok+1 ))"
	else
		echo Removing $i
		fail="$(( fail+1 ))"
		rm -f $i
	fi
done
echo OK: $ok  Fails: $fail  nan: $nan
