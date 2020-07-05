#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

for cfg in "$@" ; do
	i="$runpath/run_eigs_$cfg/run.bash.launched"
	[ -f $i ] || continue
	scancel `cat $i`
	rm $i
done
