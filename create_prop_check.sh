#!/bin/bash

runpath="$PWD/cl21_48_128_b6p5_m0p2070_m0p1750"

ok=0
fail=0
nan=0
running="`mktemp`"
squeue -u $USER > $running
for i in $runpath/run_prop_*/*.launched ; do
	[ -f ${i%.sh.launched}.verified ] && continue
	squeue -j `cat $i` &> /dev/null && continue
	if grep `cat $i` $running &> /dev/null ; then
		echo -n
	elif grep -q 'nan' ${i%.sh.launched}.out &> /dev/null ; then
		echo Removing $i
		nan="$(( nan+1 ))"
		rm -f $i
	elif grep -q 'CHROMA: ran successfully' ${i%.sh.launched}.out &> /dev/null ; then
		touch ${i%.sh.launched}.verified
		ok="$(( ok+1 ))"
	else
		echo Removing $i
		fail="$(( fail+1 ))"
		rm -f $i
	fi
done
echo OK: $ok  Fails: $fail  nan: $nan
