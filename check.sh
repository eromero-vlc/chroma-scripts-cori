#!/bin/bash

source ensembles.sh

# Gather the finished jobs
ok=0
fail=0
sq="`mktemp`"
squeue -u $USER --array > $sq
t="`mktemp`"
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for SLURM finished jobs
	runpathens="$PWD/${tag}"
	find $runpathens -name '*.sh.launched' | while read f; do
		[ -f $f.verified ] && continue
		grep -q "\<`cat $f`\>" $sq && continue
		if ${f%.launched} check; then
			ok="$(( ok+1 ))"
			${f%.launched} globus >> $t
			touch $f.verified
		else
			fail="$(( fail+1 ))"
			rm -f `${f%.launched} outs`
		fi
	done

	find -L ${confspath}/${confsprefix}/ -name '*.globus' | while read f; do
		cat $f | while read globus_task orig dest ; do
			if [ $globus_task == pending ]; then
				status="FAILED"
			else
				status="`globus task show --jq 'status' $globus_task`"
			fi
			case $status in
			*SUCCEEDED*) rm -f $f ;;
			*FAILED*) echo $orig $dest >> $t
			esac
		done
	done
done
rm -f $sq
echo OK: $ok  Failed: $fail

# Transfer files back
if [ -f $t ] ; then
        cat $t | while read orig dest ; do
                echo pending $orig $dest > ${orig#*:}.globus
        done
	origep="`head -1 $t | while read orig dest ; do  echo ${orig%:*} ; done`"
	destep="`head -1 $t | while read orig dest ; do  echo ${dest%:*} ; done`"
	cat $t | while read orig dest ; do
		echo `dirname ${dest}`
	done | sort -u | while read p ; do
		globus mkdir $p
	done
	split -l 100 $t ${t}_
	for tt in ${t}_* ; do
		cat $tt | while read orig dest ; do
			echo ${orig#*:} ${dest#*:}
		done | globus transfer --batch ${origep} ${destep} > ${tt}_tsk || exit 1
		globus_task="`cat ${tt}_tsk | grep "Task ID" | while read a b id; do echo $id; done`"
		echo $globus_task
		cat $tt | while read orig dest ; do
			echo $globus_task $orig $dest > ${orig#*:}.globus
		done
	done || exit 1
	rm -f $t ${t}_*
fi
rm -f $t
