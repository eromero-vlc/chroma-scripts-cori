#!/bin/bash

# GCR
(
	echo it res
	awk -e '
		BEGIN {p=1;}
		/^ MGPROTON GCR iteration/ {if (p) print 1+$5, $9}
		/^ MGPROTON GCR summary/ {p=0}
' 4_16_weak-basic/conf_1000/prop_t0_z0.00.out
) > prop_gcr.txt


# GCR + DD
for b in 2 4 8; do
(
	echo it res
	awk -e '
		BEGIN {p=1;}
		/^l0 MGPROTON GCR iteration/ {if (p) print 1+$6, $10}
		/^l0 MGPROTON GCR summary/ {p=0}
' 4_16_weak-bj$b/conf_1000/prop_t0_z0.00.out
) > prop_gcr_bj$b.txt
done

# GCR + RB
for b in 2 4 "4a" "4b" 8 "2s1"; do
(
	echo it res
	awk -e '
		BEGIN {p=1; s=0}
		/^schur MGPROTON MR iteration/ {s+=1}
		/^l0 MGPROTON GCR iteration/ {if (p) print 2*(1+$6+s), $10}
		/^l0 MGPROTON GCR summary/ {p=0}
' 4_16_weak-rb$b/conf_1000/prop_t0_z0.00.out
) > prop_gcr_rb$b.txt
done

# GCR + SEA-LAND
for b in "2"  "2l6" "4l3"; do
(
	echo it res
	awk -e '
		BEGIN {p=1; s=0}
		/^schur MGPROTON MR iteration/ {s+=1}
		/^l0 MGPROTON GCR iteration/ {if (p) print 2*(1+$6+s), $10}
		/^l0 MGPROTON GCR summary/ {p=0}
' 4_16_weak-si$b/conf_1000/prop_t0_z0.00.out
) > prop_gcr_si$b.txt
done

#
# First residual norm
#

for b in "p5rb" "p6rb" "p7rb"; do
	$HOME/PHY/src/chromaform/install-dg/adat/bin/dbutil weak/4_16_weak/prop_db/4_16_weak.prop.n4.light.t0_0_basic.sdb1000 compare weak/4_16_weak/prop_db/4_16_weak.prop.n4.light.t0_0_$b.sdb1000 | awk '/^key/ {t_slice=$4} /rel_error=/ {if (!(t_slice in a)) a[t_slice]=0.0;  a[t_slice]+=log(0.+$2)} END {for(t_slice in a) print t_slice, exp(a[t_slice]/16);}'| sort -n > acc_si$b.txt
done
