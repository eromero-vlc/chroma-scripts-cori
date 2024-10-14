#!/bin/bash

source ensembles.sh

unpack_moms() {
	echo $1 $2 $3
	echo $(( -$1 )) $(( -$2 )) $(( -$3 ))
}

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running genprops
	[ $run_gprops != yes ] && continue

	moms="all"
	if [ $run_onthefly == yes ]; then
		moms="`
			echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
				mom_word $( mom_fly $momij )
			done | sort -u
		`"
	fi

	tsep_groups="$( for tsep in $gprop_t_seps ; do echo $tsep ; done | sort -u -n )"
	[ x${max_tseps_per_job} == x ] && max_tseps_per_job="$( num_args $tsep_groups )"

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
		[ ${run_onthefly} != yes ] && max_moms_per_job=1
		k_split $max_moms_per_job $moms | while read mom_group ; do
		k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do

			# Find t_origin
			t_offset="`shuffle_t_source $cfg $t_size $t_source`"

			gprop_file="`tseps="${tsep_group}" gprop_file_name single`"
			[ $run_onthefly != yes ] && mkdir -p `dirname ${gprop_file}`

			#
			# Genprops creation
			#
			if [ $run_onthefly == yes ]; then
				gprop_moms="$( for mom in $mom_group; do unpack_moms ${mom//_/ }; done )"
				mom_leader="`take_first $mom_group`"
				tsep_leader="`take_first $tsep_group`"
				prefix_extra="_mf${mom_leader}_tsep${tsep_leader}"
			else
				prefix_extra=""
			fi
			prefix="${runpath}/gprop_t${t_source}_z${zphase}${prefix_extra}"
			gprop_xml="${prefix}.xml"
			cat << EOF > $gprop_xml
<?xml version="1.0"?>
<chroma>
  <Param>
    <InlineMeasurements>
      <elem>
        <Name>UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB</Name>
        <Frequency>1</Frequency>
        <Param>
          <Displacements>
`
	echo "$gprop_insertion_disps" | while read name disp; do
		[ z$name != z ] && echo "<elem>$disp</elem>"
	done
`
          </Displacements>
          <Moms>
`
	echo "$gprop_moms" | while read mom; do
		[ "z$mom" != z ] && echo "<elem>$mom</elem>"
	done
`
          </Moms>
          <LinkSmearing>
            <version>1</version>
            <LinkSmearingType>NONE</LinkSmearingType>
          </LinkSmearing>
          <SinkSourcePairs>
`
	for tsep in ${tsep_group}; do
	echo "<elem>
              <t_source>${t_offset}</t_source>
              <t_sink>$(( (t_offset+tsep)%t_size ))</t_sink>
              <Nt_forward>${redstar_t_corr}</Nt_forward>
              <Nt_backward>0</Nt_backward>
            </elem>"
	done
`
          </SinkSourcePairs>
          <Contractions>
            <num_vecs>${gprop_nvec}</num_vecs>
            <use_derivP>false</use_derivP>
            <mass_label>${prop_mass_label}</mass_label>
            <decay_dir>3</decay_dir>
            <displacement_length>1</displacement_length>
            <num_tries>0</num_tries>
            <phase>0.00 0.00 ${zphase}</phase>
            <max_rhs>${gprop_max_rhs}</max_rhs>
            <use_multiple_writers>false</use_multiple_writers>
            <use_genprop4_format>false</use_genprop4_format>
            <use_genprop5_format>true</use_genprop5_format>
            <output_file_is_local>$( if [ $run_onthefly == yes ] ; then echo true ; else echo false; fi )</output_file_is_local>
            <max_moms_in_contraction>${gprop_max_mom_in_contraction}</max_moms_in_contraction>
            <max_tslices_in_contraction>${gprop_max_tslices_in_contraction}</max_tslices_in_contraction>
          </Contractions>
          <Propagator>
            <version>10</version>
            <quarkSpinType>FULL</quarkSpinType>
            <obsvP>false</obsvP>
            <numRetries>1</numRetries>
            <FermionAction>
              <FermAct>CLOVER</FermAct>
              <Mass>${prop_mass}</Mass>
              <clovCoeff>${prop_clov}</clovCoeff>
              <AnisoParam>
                <anisoP>false</anisoP>
                <t_dir>3</t_dir>
                <xi_0>1</xi_0>
                <nu>1</nu>
              </AnisoParam>
              <FermState>
                <Name>STOUT_FERM_STATE</Name>
                <rho>0.125</rho>
                <n_smear>1</n_smear>
                <orthog_dir>-1</orthog_dir>
                <FermionBC>
                  <FermBC>SIMPLE_FERMBC</FermBC>
                  <boundary>1 1 1 -1</boundary>
                </FermionBC>
              </FermState>
            </FermionAction>
            <InvertParam>
               $prop_inv
            </InvertParam>
          </Propagator>
        </Param>
        <NamedObject>
          <gauge_id>default_gauge_field</gauge_id>
          <colorvec_files><elem>$colorvec_file</elem></colorvec_files>
          <dist_op_file>${gprop_file}</dist_op_file>
        </NamedObject>
      </elem>
    </InlineMeasurements>
    <nrow>$s_size $s_size $s_size $t_size</nrow>
  </Param>
  <RNG>
    <Seed>
      <elem>2551</elem>
      <elem>3189</elem>
      <elem>2855</elem>
      <elem>707</elem>
    </Seed>
  </RNG>
  <Cfg>
    <cfg_type>SZINQIO</cfg_type>
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
#SBATCH -t $gprop_chroma_minutes
#SBATCH --nodes=$gprop_slurm_nodes -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J gprop-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	mkdir -p `dirname ${gprop_file}`
	rm -f ${gprop_file}*
	srun -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS $chroma -i ${gprop_xml} -geom $gprop_chroma_geometry $chroma_extra_args &> $output
}

blame() {
	if ! tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" ; then
		echo gprop creation failed
		exit 1
	fi
	exit 0
}

check() {
	tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" || exit 1
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $gprop_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo b $gprop_chroma_minutes $gprop_slurm_nodes 1 0
}

globus() {
	[ $gprop_transfer_back == yes ] && echo ${gprop_file}.globus ${this_ep}${gprop_file#${confspath}} ${jlab_ep}${gprop_file#${confspath}} ${gprop_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # tsep_group
		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
