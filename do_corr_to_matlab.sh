#!/bin/bash

source ensembles.sh

redstar_dat_mom_snk() {
	echo "${1}${2}${3}"
}

redstar_dat_mom_src() {
	echo "${4}${5}${6}"
}

noblanks() {
	local a="${@}"
	echo -n ${a// /}
}

# Load redstar environment
redstar_env_file="`mktemp`"
echo "$slurm_script_prologue_redstar" > $redstar_env_file
. $redstar_env_file

tmp_dat_dir="`mktemp -d`"
for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue

	if [ ${redstar_2pt} == yes -a ${redstar_3pt} == yes ] ; then
		echo "Unsupported to compute 2pt and 3pt on the fly at once"
		exit 1
	fi
	mom_groups="`
		(
			[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms"
			[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom"
		) | while read momij; do
			[ $(num_args $momij) -gt 0 ] && mom_word $( mom_fly $momij )
		done | sort -u
	`"

	mom_leaders="$(
		k_split $max_moms_per_job $mom_groups | while read mom_group ; do
			mom_leader="$( take_first $mom_group )"
			echo $mom_leader
		done
	)"

	data="$PWD/${redstar_matlab_data_collection}"
	rm -f $data ${data}_*

	num_insertion_operators=1
	[ $redstar_3pt == yes ] && num_insertion_operators="$( num_args $redstar_insertion_operators)"
	num_mom_leaders="$( num_args $mom_leaders )"
	max_combo_lines="$(( num_insertion_operators*num_mom_leaders ))"
	max_combo_lines="$(( max_combo_lines > slurm_procs_per_node*redstar_slurm_nodes ? slurm_procs_per_node*redstar_slurm_nodes : max_combo_lines ))"

	for zphase in $prop_zphases; do
		for (( insertion_op=0 ; insertion_op < max_combo_lines ; ++insertion_op )) ; do
			for momw in $mom_leaders; do
				mom="${momw//_/ }"

				for t_source in $prop_t_sources ; do
					for cfg in $confs; do
						c="`corr_file_name`"
						[ -f $c ] || echo $c
						[ -f $c ] || continue
						(
							tmp_dat_dira="${tmp_dat_dir}_${t_source}"
							mkdir -p $tmp_dat_dira
							rm $tmp_dat_dira/*
							cd ${tmp_dat_dira}
							$dbutil $c keysxml a
							OMP_NUM_THREADS=1 $dbutil $c get a
							if [ ${redstar_2pt} == yes ] ; then
								echo "$redstar_2pt_moms" | while read momij ; do
									[ $( num_args $momij ) != 3 ] && continue
									momi="$( noblanks $momij )"
									momtypei="$( noblanks $( momtype $momij ) )"
									operators="$( get_ops $momij )"
									for opi in $operators ; do
									for rowi in 1 2 ; do
									for opj in $operators ; do
									for rowj in 1 2 ; do
										ff="tm2,fI1Y3i1,r${rowi},${momi},${opi}__${momtypei}.t0,fI1Y3i1,r${rowj},${momi},${opj}__${momtypei}.dat"
										#[ -f $ff ] || echo failed $ff
										[ -f $ff ] || continue
										echo -n "v.('${momi}_${opi}_${rowi}_${momj}_${opj}_${rowj}').('${cfg} ${t_source}')=[" >> ${data}_${t_source}
										awk '
											BEGIN { l=0; }
											{ if (l>0) printf("%s+%sj ",$2,$3); l++ ; }
										' $ff >> ${data}_${t_source}
										echo "];" >> ${data}_${t_source}
									done
									done
									done
									done
								done
							elif [ ${redstar_3pt} == yes ] ; then
								echo "$redstar_3pt_snkmom_srcmom" | while read snk_src_mom ; do
									[ $( num_args $snk_src_mom ) != 6 ] && continue
									echo "$redstar_insertion_disps" | while read disp_label disp ; do 
										[ x$disp_label == x ] && continue
										momarray=( $snk_src_mom )
										momi="${momarray[0]} ${momarray[1]} ${momarray[2]}"
										momj="${momarray[3]} ${momarray[4]} ${momarray[5]}"
										operatorsi="$( get_ops $momi )"
										operatorsj="$( get_ops $momj )"
										momk="$( insertion_mom $momi $momj )"
										momtypei="$( noblanks $( momtype $momi ) )"
										momtypej="$( noblanks $( momtype $momj ) )"
										momtypek="$( noblanks $( momtype $momk ) )"
										momi="$( noblanks $momi )"
										momj="$( noblanks $momj )"
										momk="$( noblanks $momk )"
										disp_str=",$( noblanks $disp )"
										[ x"$disp" == x ] && disp_str=""
										for opi in $operatorsi ; do
										for rowi in 1 2 ; do
										for opj in $operatorsj ; do
										for rowj in 1 2 ; do
										for insop in $redstar_insertion_operators ; do
										for rowk in $( operator_rows $insop ) ; do	
										for tsep in $gprop_t_seps ; do
											f="t${tsep},fI1Y3i1,r${rowi},${momi},${opi}__${momtypei}.tm3,fI0Y0i0,r${rowk},${momk},${insop}__${momtypek}${disp_str}.t0,fI1Y3i1,r${rowj},${momj},${opj}__${momtypej}.dat"
											[ -f $f ] || echo $t_source $f
											[ -f $f ] || continue
											echo -n "v.('${momi}_${opi}_${rowi}_${momk}_${insop}_${rowk}_${momj}_${opj}_${rowj}').('tsep${tsep}').('d${disp}').('${cfg} ${t_source}')=[" >> ${data}_${t_source}
											awk '
												BEGIN { l=0; }
												{ if (l>0) printf("%s+%sj ",$2,$3); l++ ; }
											' $f >> ${data}_${t_source}
											echo "];" >> ${data}_${t_source}
										done
										done
										done
										done
										done
										done
										done
									done
								done
							fi
						)
					done & # cfg
				done # t_source
				wait
			done # momw
		done # insertion_op
	done # zphase

	cat ${data}_* > $data
	rm -f ${data}_*
done # ens

