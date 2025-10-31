#!/bin/bash

source ensembles.sh

t="`mktemp`"
success=1
if ! globus ls $this_ep &> $t ; then
	cat $t
	success=0
	echo "You may have to run: globus session consent 'urn:globus:auth:scope:transfer.api.globus.org:all[*https://auth.globus.org/scopes/${this_ep/:*/}/data_access]'"
fi
if ! globus ls $jlab_ep &> $t ; then
	cat $t
	success=0
	echo "You may have to run: globus session consent 'urn:globus:auth:scope:transfer.api.globus.org:all[*https://auth.globus.org/scopes/${jlab_ep/:*/}/data_access]'"
fi
rm -f $t
[ $success == 0 ] && exit 1
echo "globus is working"
