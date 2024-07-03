#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running disco
	[ $run_discos != yes ] && continue

	# Create the directory to store the results
	mkdir -p ${confspath}/${confsprefix}/disco

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue
		
		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		num_color_parts="$(( (disco_max_colors + disco_max_colors_at_once-1) / disco_max_colors_at_once ))"
		
		for t_source in $disco_t_sources; do
		for color_part in `seq 0 $(( num_color_parts-1 ))`; do
			disco_file="`disco_file_name`"

			# Find t_origin
			t_offset="`shuffle_t_source $cfg $t_size $t_source`"
		
			prefix="$runpath/disco_t${t_source}_p${color_part}"
			cat << EOF > ${prefix}.xml
<?xml version="1.0"?>
<chroma>
<Param>
  <InlineMeasurements>
   <elem>
    <Name>DISCO_PROBING_3D_DEFLATION_SUPERB</Name>
      <Param>
        <Displacements>
`
	echo "$disco_insertions" | while read name disp; do
		[ x$name != x ] && echo "<elem>$disp</elem>"
	done
`
        </Displacements>
        <mom_list>
           <elem>0 0 0</elem>
        </mom_list>
        <mass_label>${prop_mass_label}</mass_label>
        <probing_distance>${disco_probing_displacement}</probing_distance>
        <probing_power>${disco_probing_power}</probing_power>
	<first_color>$(( color_part*disco_max_colors_at_once ))</first_color>
	<num_colors>${disco_max_colors_at_once}</num_colors>
        <noise_vectors>${disco_noise_vectors}</noise_vectors>
	<t_sources>${t_offset}</t_sources>
        <max_rhs>1</max_rhs>
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
        <Projector>
          $disco_proj
        </Projector>
        <use_ferm_state_link>true</use_ferm_state_link>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <sdb_file>${disco_file}</sdb_file>
      </NamedObject>
    </elem>
  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
  </Param>
  <RNG>
    <Seed>
      <elem>11</elem>
      <elem>11</elem>
      <elem>${t_source}</elem>
      <elem>$cfg</elem>
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
		cat << EOF > ${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o ${prefix}.out0
#SBATCH -t $disco_chroma_minutes
#SBATCH --nodes=$disco_slurm_nodes -n $(( slurm_procs_per_node*disco_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J disco-${cfg}-${color_part}

run() {
	$slurm_script_prologue
	
	cd $runpath
	mkdir -p `dirname ${disco_file}`
	rm -f $disco_file
	srun \$MY_ARGS -n $(( slurm_procs_per_node*disco_slurm_nodes )) -N $disco_slurm_nodes $chroma -i ${prefix}.xml -geom $disco_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

blame() {
	if ! tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" ; then
		echo disco creation failed
		exit 1
	fi
	exit 0
}

deps() {
	echo $lime_file
}

outs() {
	echo $disco_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo a $disco_chroma_minutes $disco_slurm_nodes 1 0
}

globus() {
	[ $disco_transfer_back == yes ] && echo ${disco_file}.globus ${this_ep}${disco_file#${confspath}} ${jlab_ep}${disco_file#${confspath}} ${disco_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF
		done # color_part
		done # t_source
	done # cfg
done # ens
