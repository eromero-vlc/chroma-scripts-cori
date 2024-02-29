#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running props
	[ $run_props != yes ] && continue

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $prop_t_sources; do
		for zphase in $prop_zphases; do

			# Find t_origin
			t_offset="`shuffle_t_source $cfg $t_size $t_source`"

			prop_file="`prop_file_name single`"

			#
			# Propagators creation
			#

			prefix="${runpath}/prop_t${t_source}_z${zphase}"
			prop_xml="${prefix}.xml"
			cat << EOF > $prop_xml
<?xml version="1.0"?>

<chroma>
<Param>
  <InlineMeasurements>

    <elem>
      <Name>PROP_AND_MATELEM_DISTILLATION_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <Contractions>
          <mass_label>${prop_mass_label}</mass_label>
          <num_vecs>$prop_nvec</num_vecs>
          <t_sources>$t_offset</t_sources>
          <Nt_forward>$prop_t_fwd</Nt_forward>
          <Nt_backward>$prop_t_back</Nt_backward>
          <decay_dir>3</decay_dir>
          <num_tries>-1</num_tries>
          <max_rhs>1</max_rhs>
          <phase>0.00 0.00 $zphase</phase>
          <use_superb_format>true</use_superb_format>
          <output_file_is_local>$( if [ $run_onthefly == yes ] ; then echo true ; else echo false; fi )</output_file_is_local>
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
        <prop_op_file>$prop_file</prop_op_file>
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
#SBATCH -o $runpath/prop_t${t_source}_z${zphase}.out0
#SBATCH -t $prop_chroma_minutes
#SBATCH --nodes=$prop_slurm_nodes -n $(( slurm_procs_per_node*prop_slurm_nodes ))  -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J prop-${cfg}-${t_source}-${zphase}

run() {
	$slurm_script_prologue
	cd $runpath
	mkdir -p `dirname ${prop_file}`
	rm -f $prop_file
	srun \$MY_ARGS -n $(( slurm_procs_per_node*prop_slurm_nodes )) -N $prop_slurm_nodes $chroma -i ${prop_xml} -geom $prop_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

blame() {
	if ! tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" ; then
		echo prop creation failed
		exit 1
	fi
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $prop_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo b $prop_chroma_minutes $prop_slurm_nodes 1 0
}

globus() {
	[ $prop_transfer_back == yes ] && echo ${prop_file}.globus ${this_ep}${prop_file#${confspath}} ${jlab_ep}${prop_file#${confspath}} ${prop_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # zphase
		done # t_source
	done # cfg
done # ens
