#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

for cfg in "$@" ; do
	for i in `ls $runpath/run_prop_$cfg/*.launched` ; do
		[ -f $i ] || continue
		scancel `cat $i`
		rm $i
	done
done
