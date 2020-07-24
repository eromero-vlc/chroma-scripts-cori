#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

ok=0
fail=0
for i in $runpath/run_prop_*/*.launched ; do
	[ -f ${i%.sh.launched}.verified ] && continue
	squeue -j `cat $i` &> /dev/null && continue
	if grep -q 'CHROMA: ran successfully' ${i%.sh.launched}.out &> /dev/null ; then
		touch ${i%.sh.launched}.verified
		ok="$(( ok+1 ))"
	else
		echo Removing $i
		fail="$(( fail+1 ))"
		rm -f $i
	fi
done
echo OK: $ok  Fails: $fail
