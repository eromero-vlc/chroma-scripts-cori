#!/bin/bash

source ensembles.sh

# mom_flip momx0 momy0 momz0
# Return the momentum negated

mom_flip() {
	echo $(( -$1 )) $(( -$2 )) $(( -$3 ))
}

get_moms() {
	local phase="$1"
	shift
	local l
	local m
	get_all_corr | while read l ; do
		[ $(num_args $l ) == 0 -o $( mom_word $( get_phase_from_corr_line $l ) ) != $phase ] && continue
		local this_mom="$( mom_word $( mom_fly $( get_mom_from_corr_line $l ) ) )"
		for m in $@ ; do
			if [ $this_mom == $m ] ; then
				mom_flip $( get_sink $( get_mom_from_corr_line $l ) )
				mom_flip $( get_source $( get_mom_from_corr_line $l ) )
				break
			fi
		done
	done
}


for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running baryons
	[ $run_baryons != yes ] && continue

	for phase in $( get_all_phases ); do

		#
		# Baryon creation
		#

		t_sources="all"
		[ ${run_onthefly} == yes ] && t_sources="$gprop_t_sources"
		[ ${run_onthefly} != yes ] && max_moms_per_job=1
		for t_source in $t_sources; do
		k_split $max_moms_per_job $( get_fly_moms $phase ) | while read mom_group ; do

		for cfg in $confs; do
			lime_file="`lime_file_name`"
			colorvec_file="`colorvec_file_name`"
			[ -f $lime_file ] || continue
	
			runpath="$PWD/${tag}/conf_${cfg}"
			[ -f ${runpath}.tar.gz ] && continue
			mkdir -p $runpath


			if [ ${run_onthefly} == yes ] ; then
				# Find t_origin
				baryon_t_source="`shuffle_t_source $cfg $t_size $t_source`"
				Nt_forward=$(( redstar_t_corr + 2  ))
				mom_leader="`take_first $mom_group`"
				prefix_extra="_t0_${t_source}_mf${mom_leader}"
			else
				baryon_t_source=0
				Nt_forward=$t_size
				prefix_extra=""
			fi

			baryon_file="`baryon_file_name single`"
			[ $run_onthefly != yes ] && mkdir -p `dirname ${baryon_file}`

			phase_snk="$( get_sink ${phase//_/ } )"
			phase_src="$( get_source ${phase//_/ } )"
			prefix="$runpath/baryon_ph${phase}${prefix_extra}"
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
        <phases><elem>${phase_src}</elem><elem>${phase_snk}</elem></phases>
        <use_superb_format>true</use_superb_format>
        <output_file_is_local>$( if [ $run_onthefly == yes ] ; then echo true ; else echo false; fi )</output_file_is_local>
        <mom_list>
$(
	get_moms $phase $mom_group | sort -u | while read mom ; do
		echo "<elem>$mom</elem>"
	done
)	
        </mom_list>
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
#SBATCH -J bar-${cfg}-${phase}-${baryon_file_index}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $baryon_file
	mkdir -p `dirname ${baryon_file}`
	[ \$SLURM_PROCID == 0 ] && $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args &> $output
	[ \$SLURM_PROCID != 0 ] && $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args
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
		done # cfg
		done # mom_group
		done # t_source
	done # phase
done # ens
