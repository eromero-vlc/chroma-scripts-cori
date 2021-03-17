#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

for i in `ls $runpath/run_eigs{,phase}_*/*.launched` ; do
	[ -f ${i%.bash.launched}.verified ] && continue
	squeue -j `cat $i` &> /dev/null && continue
	if grep -q 'FINISHED' ${i%.bash.launched}.out ; then
		touch ${i%.bash.launched}.verified
	else
		echo Removing $i
		rm -f $i
	fi
done
