#!/bin/bash

runpath="$PWD/cl21_48_128_b6p5_m0p2070_m0p1750*"

clean () {
	tsk="$1"
	grep "^#CREATE " $tsk | while read act files ; do
		for i in "${files}" ; do
			rm -f $i
		done
	done
}

t="`mktemp`"

transfer () {
	tsk="$1"
	grep "^#GLOBUS_COPY " $tsk | while read act orig dest ; do
		echo $orig $dest >> $t
	done
}

ok=0
fail=0
nan=0
sq="`mktemp`"
squeue -u $USER --array > $sq
for i in $runpath/run_gprop_*/*.launched ; do
	ir="${i%.sh.launched}"
	[ -f ${ir}.verified ] && continue
	#squeue -j `cat $i` &> /dev/null && continue
	grep "\<`cat $i`\>" $sq &> /dev/null && continue
	if grep -q 'nan' ${ir}.out &> /dev/null ; then
		echo Removing $i
		nan="$(( nan+1 ))"
		clean ${ir}.sh
		rm -f $i
	elif (! grep -q "slurmstepd: error" ${ir}.out &>/dev/null ) && grep -q 'CHROMA: ran successfully' ${ir}.out &> /dev/null ; then
		echo Transferring $i
		ok="$(( ok+1 ))"
		transfer ${ir}.sh
		touch ${ir}.verified
	else
		echo Removing $i
		fail="$(( fail+1 ))"
		clean ${ir}.sh
		rm -f $i
	fi
done
echo OK: $ok  Fails: $fail  nan: $nan

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

rm -f $sq
