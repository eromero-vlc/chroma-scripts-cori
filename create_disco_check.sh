#!/bin/bash

runpath="$PWD/cl21_48_128_b6p5_m0p2070_m0p1750"

ok=0
fail=0
nan=0
running="`mktemp`"
squeue -u $USER > $running
for i in $runpath/run_disco_*/*.launched ; do
	[ -f ${i%.sh.launched}.verified ] && continue
	if grep `cat $i` $running &> /dev/null ; then
		if ( tail -1 ${i%.sh.launched}.out | grep 'INFO: Creating HaloCB' &> /dev/null ) ; then
			scancel `cat $i`
			echo Removing $i
			fail="$(( fail+1 ))"
			rm -f $i
		fi
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
