#!/bin/bash

chromaform="/qcd/work/JLabLQCD/eromero/chromaform-24s/alt_ompi5_gcc14"
adat="$chromaform/install/adat-pdf-superbblas"
dbavg="$adat/bin/dbavg"
dbdisco_vac_sub="$adat/bin/dbdisco_vac_sub"
dbmerge="$adat/bin/dbmerge"
dbutil="$adat/bin/dbutil"

. $chromaform/env_extra0.sh
source common.sh
redstar_000="NucleonMG1g1MxD0J0S_J1o2_G1g1"
redstar_n00="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1"
redstar_nn0="NucleonMG1g1MxD0J0S_J1o2_H1o2D2E"
redstar_nnn="NucleonMG1g1MxD0J0S_J1o2_H1o2D3E1"
redstar_nm0="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nm0E"
redstar_nnm="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nnmE"

data="${PWD}/data_2pt.m"
rm -f $data

tmp_dat_dir="`mktemp -d`"

noblanks() {
	local a="${@}"
	echo -n ${a// /}
}

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

for momz in 0 ; do
#for momz in 0 1 -1 2 -2 3 -3 ; do
	d=/qcd/cache/lqcdpdf/isoClover/chamness_disco/cl21_32_64_b6p3_m0p2350_m0p2050-5162/contractions/2pts/mom_$momz/
	cfg_number=1
	for cnf in `seq 5170 10 9990` ; do
		grep -q "\<$cnf\>" $failed_confs && continue
		c="$d/cl21_32_64_b6p3_m0p2350_m0p2050.nuc_p000.n64.t0_0.sdb$cnf"
		mkdir -p $tmp_dat_dir
		rm $tmp_dat_dir/*
		(
			cd ${tmp_dat_dir}
			$dbutil $c keysxml a
			OMP_NUM_THREADS=1 $dbutil $c get a
			mom="0 0 $momz"
			momi="$( noblanks $mom )"
			momtypei="$( noblanks $( momtype $mom ) )"
			operators="$( get_ops $mom )"
			for opi in $operators ; do
			for opj in $operators ; do
				rowi=1
				rowj=1
				ff="tm2,fI1Y3i1,r${rowi},${momi},${opi}__${momtypei}.t0,fI1Y3i1,r${rowj},${momi},${opj}__${momtypei}.dat"
				[ -f $ff ] || echo failed $cnf
				[ -f $ff ] || continue
				echo -n "v.('${momi}_${opi}_${rowi}_${momj}_${opj}_${rowj}')($cfg_number,:)=[" >> ${data}
				echo here
				awk '
					BEGIN { l=0; }
					{ if (l>0) printf("%s+%sj ",$2,$3); l++ ; }
				' $ff >> ${data}
				echo "];" >> ${data}
			done
			done
		)
		cfg_number="$(( cfg_number+1 ))"
	done
done
