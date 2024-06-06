#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running baryons
	[ $run_baryons != yes ] && continue

	moms="all"
	if [ $run_onthefly == yes ]; then
		if [ ${redstar_2pt} == yes -a ${redstar_3pt} == yes ] ; then
			echo "Unsupported to compute 2pt and 3pt on the fly at once"
			exit 1
		fi
		moms="`
			(
				[ ${redstar_2pt} == yes ] && echo "$redstar_2pt_moms"
				[ ${redstar_3pt} == yes ] && echo "$redstar_3pt_snkmom_srcmom"
			) | while read momij; do
				[ $(num_args $momij) -gt 0 ] && mom_word $( mom_fly $momij )
			done | sort -u
		`"
	fi
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for zphase in $baryon_zphases; do

			#
			# Baryon creation
			#

			t_sources="all"
			[ ${run_onthefly} == yes -a ${onthefly_all_tsources_per_job} != yes ] && t_sources="$gprop_t_sources"
			[ ${run_onthefly} != yes ] && max_moms_per_job=1
			for t_source in $t_sources; do
			k_split $max_moms_per_job $moms | while read mom_group ; do

			baryon_moms_xml="
<mom_list>
	`
		if [ ${redstar_2pt} == yes ] ; then
			for momij in $mom_group ; do
				mom_split ${momij//_/ }
			done
		elif [ ${redstar_3pt} == yes ] ; then
			echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
				for this_momij in $mom_group ; do
					[ $( mom_word $( mom_fly $momij ) ) == $this_momij ] && mom_split $momij
				done
			done
		fi | sort -u | while read mom; do
			echo "<elem>$mom</elem>"
		done
	`
</mom_list>"
			if [ ${run_onthefly} == yes -a ${onthefly_all_tsources_per_job} != yes ] ; then
				# Find t_origin
				baryon_t_source="`shuffle_t_source $cfg $t_size $t_source`"
				Nt_forward=$(( redstar_t_corr + 2  ))
			else
				baryon_t_source=0
				Nt_forward=$t_size
			fi
			if [ ${run_onthefly} == yes ] ; then
				mom_leader="`take_first $mom_group`"
				prefix_extra="_t0_${t_source}_mf${mom_leader}"
			else
				prefix_extra=""
			fi

			baryon_file="`baryon_file_name single`"
			[ $run_onthefly != yes ] && mkdir -p `dirname ${baryon_file}`

			prefix="$runpath/baryon_${zphase}${prefix_extra}"
			baryon_xml="${prefix}.xml"
			cat << EOF > $baryon_xml
<?xml version="1.0"?>
<chroma>
<Param>
  <InlineMeasurements>
    <elem>
      <Name>BARYON_MATELEM_COLORVEC_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>2</version>
        <max_tslices_in_contraction>${baryon_chroma_max_tslices_in_contraction}</max_tslices_in_contraction>
        <max_moms_in_contraction>${baryon_chroma_max_moms_in_contraction}</max_moms_in_contraction>
        <max_vecs>${baryon_chroma_max_vecs}</max_vecs>
        
        <use_derivP>true</use_derivP>
        <t_source>$baryon_t_source</t_source>
        <Nt_forward>$Nt_forward</Nt_forward>
        <num_vecs>$baryon_nvec</num_vecs>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>
        <phase>0.00 0.00 $zphase</phase>
        <use_superb_format>true</use_superb_format>
        <output_file_is_local>$( if [ $run_onthefly == yes ] ; then echo true ; else echo false; fi )</output_file_is_local>

	$baryon_moms_xml
        $baryon_extra_xml

        <LinkSmearing>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>$eigs_smear_rho</link_smear_fact>
          <link_smear_num>$eigs_smear_steps</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </LinkSmearing>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <colorvec_files><elem>${colorvec_file}</elem></colorvec_files>
        <baryon_op_file>${baryon_file}</baryon_op_file>
      </NamedObject>
    </elem>
  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
</Param>

 <RNG>
  <Seed>
    <elem>11</elem>
    <elem>11</elem>
    <elem>11</elem>
    <elem>0</elem>
  </Seed>
</RNG>

 <Cfg>
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
 </Cfg>
</chroma>
EOF

			output="${prefix}.out"
			script="${prefix}.sh"
			[ $run_onthefly == yes ] && script="${script}.future"
			cat << EOF > ${script}
$slurm_sbatch_prologue
#SBATCH -o ${prefix}.out0
#SBATCH -t $baryon_chroma_minutes
#SBATCH --nodes=$baryon_slurm_nodes -n $(( slurm_procs_per_node*baryon_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J bar-${cfg}-${zphase}-${baryon_file_index}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $baryon_file
	mkdir -p `dirname ${baryon_file}`
	srun \$MY_ARGS -n $(( slurm_procs_per_node*baryon_slurm_nodes )) $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

blame() {
	if ! tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" ; then
		echo baryon creation failed
		exit 1
	fi
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $baryon_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo b $baryon_chroma_minutes $baryon_slurm_nodes 1 0
}

globus() {
	[ $baryon_transfer_back == yes ] && echo ${baryon_file}.globus ${this_ep}${baryon_file#${confspath}} ${jlab_ep}${baryon_file#${confspath}} ${baryon_delete_after_transfer_back}
}

eval "\${1:-run}"

EOF
			done # mom_group
			done # t_source
		done # zphase
	done # cfg
done # ens
