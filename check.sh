#!/bin/bash

source ensembles.sh

# Gather the finished jobs
t="`mktemp`"
ok="`mktemp`"
fail="`mktemp`"

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for SLURM finished jobs
	runpathens="$PWD/${tag}"
	echo -n > $ok
	echo -n > $fail
	find $runpathens -name '*.sh.launched' | while read f; do
		[ -f $f.verified ] && continue
		if bash ${f%.launched} check; then
			echo >> $ok
			bash ${f%.launched} globus >> $t
			touch $f.verified
			echo ok $f
		else
			echo >> $fail
			rm -f `bash ${f%.launched} outs` $f
			echo fail $f
		fi
	done
	echo OK: `wc -l < $ok`  Failed: `wc -l < $fail`
done
rm -f $ok $fail
