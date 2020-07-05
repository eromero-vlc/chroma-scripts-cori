#!/bin/bash

runpath="$PWD/cl21_32_64_b6p3_m0p2350_m0p2050"

for i in `ls $runpath/run_prop_*/*.launched` ; do
	squeue -j `cat $i` &> /dev/null || grep -q 'CHROMA: ran successfully' ${i%.sh.launched}.out || rm -f $i
done
