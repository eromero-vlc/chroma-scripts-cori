#!/bin/bash

runpath="$PWD/cl21_48_96_b6p3_m0p2416_m0p2050*"

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

queue="`mktemp`"
bjobs &> $queue
ok=0
fail=0
nan=0
for i in $runpath/run_gprop_*/*.launched ; do
	[ -f ${i%.sh.launched}.verified ] && continue
	grep -q `cat $i` $queue &> /dev/null && continue
	if grep -q 'nan' ${i%.sh.launched}.out &> /dev/null ; then
		echo Removing $i
		nan="$(( nan+1 ))"
		clean ${i%.sh.launched}.sh
		rm -f $i
	elif grep -q 'CHROMA: ran successfully' ${i%.sh.launched}.out &> /dev/null ; then
		ok="$(( ok+1 ))"
		transfer ${i%.sh.launched}.sh
		touch ${i%.sh.launched}.verified
	else
		echo Removing $i
		fail="$(( fail+1 ))"
		clean ${i%.sh.launched}.sh
		rm -f $i
	fi
done
echo OK: $ok  Fails: $fail  nan: $nan

# Transfer files
if [ -f $t ] ; then
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
