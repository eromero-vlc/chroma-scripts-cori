#!/bin/bash

source ensembles.sh
source common.sh

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

failed_confs="`mktemp`"
cat << EOF > $failed_confs
5220
5240
5290
5310
5330
5350
5380
5390
5470
5500
5560
5590
5620
5680
5710
5750
5860
5880
5900
5970
6030
6070
6110
6180
6270
6280
6290
6300
6310
6320
6350
6370
6390
6410
6490
6560
6640
6700
6740
6790
6960
7060
7080
7120
7180
7190
7210
7320
7330
7340
7380
7400
7410
7420
7480
7490
7560
7650
7670
7690
7720
7730
7740
7770
7800
7870
7930
7940
8030
8130
8140
8160
8190
8230
8240
8280
8420
8520
8560
8570
8590
8650
8710
8730
8770
8820
8850
8890
8950
9130
9380
9560
9820
9950
8870
8880
8910
8980
9070
9080
9100
9200
9210
9250
9300
9390
9470
9550
9660
9710
9740
9780
9790
9810
9940
EOF

data="$PWD/data_disco.m"
echo "%v(conf,tslice,disp)" > $data
echo "v=[]; cnf=0;" >> $data

keys="`mktemp`"
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	for cfg in $confs; do
		grep -q "\<$cfg\>" $failed_confs && continue
		c="`disco_file_name`"
		if [ ! -f $c ] || ! $dbutil $c keysxml $keys ; then
			echo failed $cfg
			continue
		fi
		t_origin="$( shuffle_t_source $cfg $t_size 0 )"
        	echo "cnf=cnf+1;" >> $data
		OMP_NUM_THREADS=1 $dbutil $c get $keys | awk -v t_origin=${t_origin} -v t_size=${t_size} '
                	/mom= 0 0 0/ {
                	        split($0,a,"value= ");
                	        v=gensub(/\(([^,]+),([^,]+)\)/, "\\1+\\2i","g",a[2]);
                	        split(a[1],b);
                	        t=0+b[4];
                	        disp=0;
                	        for(i=5; b[i] !~ /mom=/ && i<20; i++) {
                	                if (0+b[i] == -3) disp--;
                	                if (0+b[i] == 3) disp++;
                	        }
                	        printf("v(cnf,%d,%d,1:16)=[%s];\n", (t+t_origin)%t_size+1,disp+9,v);
                	}
        	' >> ${data}
	done # cfg
done # ens
