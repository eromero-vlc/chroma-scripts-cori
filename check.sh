#!/bin/bash

source ensembles.sh

# Gather the finished jobs
sq="`mktemp`"
squeue -u $USER --array > $sq
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
		grep -q "\<`cat $f`\>" $sq && continue
		if bash ${f%.launched} check; then
			echo >> $ok
			bash ${f%.launched} globus >> $t
			touch $f.verified
			echo ok $f
		else
			echo >> $fail
			rm -f `bash ${f%.launched} outs` $f
		fi
	done
	echo OK: `wc -l < $ok`  Failed: `wc -l < $fail`

	find -L ${confspath}/${confsprefix}/ -name '*.globus' | while read f; do
		cat $f | while read globus_task orig dest delete; do
			if [ $globus_task == pending ]; then
				status="FAILED"
			else
				status="`globus task show --jq 'status' $globus_task`"
			fi
			case $status in
			*SUCCEEDED*) [ $delete == yes ] && echo rm -f $f ;;
			*FAILED*) echo $f $orig $dest $delete >> $t
			esac
		done
	done
done
rm -f $sq $ok $fail

# Transfer files back
if [ -s $t ] ; then
        cat $t | while read f orig dest delete ; do
                echo pending $orig $dest $delete > $f
                echo $f $orig $dest $delete >> ${t}_${orig%:*}_${dest%:*}
        done
	for tod in ${t}_*; do
		origep="`head -1 $tod | while read f orig dest delete; do  echo ${orig%:*} ; done`"
		destep="`head -1 $tod | while read f orig dest delete; do  echo ${dest%:*} ; done`"
		cat $tod | while read f orig dest delete ; do
			dirname ${dest}
		done | sort -u | while read p ; do
			globus mkdir $p
		done
		split -l 100 $tod ${tod}_
		for tt in `ls ${tod}_*` ; do
			success=1
			cat $tt | while read f orig dest delete ; do
				echo ${orig#*:} ${dest#*:}
			done | globus transfer --batch ${origep} ${destep} > ${tt}_tsk || success=0
			if [ $success == 0 ]; then
				cat ${tt}_tsk
				exit 1
			fi
			globus_task="`cat ${tt}_tsk | grep "Task ID" | while read a b id; do echo $id; done`"
			echo $globus_task
			cat $tt | while read f orig dest delete ; do
				echo $globus_task $orig $dest $delete > $f
			done
		done || exit 1
	done
	rm -f $t ${t}_*
fi
