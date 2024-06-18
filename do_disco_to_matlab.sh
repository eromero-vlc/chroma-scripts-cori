#!/bin/bash

source ensembles.sh
source common.sh

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

keys="`mktemp`"
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	data="$PWD/${disco_matlab_data_collection}"
	echo "%v.('disp').('cnf t')" > $data

	for cfg in $confs; do
		c="`disco_file_name`"
		if [ ! -f $c ] || ! $dbutil $c keysxml $keys ; then
			echo failed $cfg
			continue
		fi
		t_origin="$( shuffle_t_source $cfg $t_size 0 )"
		OMP_NUM_THREADS=1 $dbutil $c get $keys | awk -v t_origin=${t_origin} -v t_size=${t_size} -v cfg=$cfg $'
                	/mom= 0 0 0/ {
                	        split($0,a,"value= ");
                	        v=gensub(/\\(([^,]+),([^,]+)\\)/, "\\\\1+\\\\2i","g",a[2]);
                	        split(a[1],b);
                	        t=0+b[4];
                	        disp="";
                	        for(i=6; b[i] !~ /mom=/ && i<20; i++) {
                	                if (disp) disp=disp " " b[i]; else disp=b[i]
                	        }
                	        printf("v.(\'d%s\').(\'%d %d\')=[%s];\\n", disp, cfg, (t-t_origin+t_size)%t_size,v);
                	}
        	' >> ${data}
	done # cfg
done # ens
