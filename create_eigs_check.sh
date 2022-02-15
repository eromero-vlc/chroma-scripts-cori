#!/bin/bash

runpath="$PWD/cl21_48_128_b6p5_m0p2070_m0p1750"

for i in `ls $runpath/run_eigs{,phase}_*/*.launched` ; do
	[ -f ${i%.bash.launched}.verified ] && continue
	squeue -j `cat $i` &> /dev/null && continue
	
	if ( ! grep Killed -q ${i%.bash.launched}.out &&  grep -q 'FINISHED' ${i%.bash.launched}.out ) ; then
		touch ${i%.bash.launched}.verified
	else
		echo Removing $i
		rm -f $i
	fi
done
