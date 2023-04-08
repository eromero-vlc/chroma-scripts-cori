#!/bin/bash

source ensembles.sh

t="`mktemp`"
success=1
if ! globus ls $this_ep &> $t ; then
	cat $t
	success=0
fi
if ! globus ls $jlab_ep &> $t ; then
	cat $t
	success=0
fi
rm -f $t
[ $success == 0 ] && exit 1
echo "is working"
