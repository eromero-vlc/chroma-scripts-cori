#!/bin/bash

confsdir="/global/project/projectdirs/hadron/b6p3"
confsdir="$SCRATCH/b6p5"

t="`mktemp`"
for i in `find -L $confsdir -name '*.globus'` ; do
	echo checking $i
	cat $i | while read globus_task orig dest ; do
		if [ $globus_task == pending ]; then
			status="FAILED"
		else
			status="`globus task show --jq 'status' $globus_task`"
		fi
		case $status in
		*SUCCEEDED*) rm -f $i ${orig#*:} ;;
		*FAILED*) echo $orig $dest >> $t
		esac
	done
done

# Transfer files
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
