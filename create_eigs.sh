#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running eigs
	[ $run_eigs != yes ] && continue

	for cfg in $confs; do
		colorvec_file="`colorvec_file_name`"
		
		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		# Create the directory to store the eigenvectors
		mkdir -p `dirname ${colorvec_file}`
		
		#
		# Basis creation
		#
		
		cat << EOF > $runpath/eigs.xml
<?xml version="1.0"?>
<chroma>
 <Param>
  <InlineMeasurements>
    <elem>
      <Name>CREATE_COLORVECS_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <num_vecs>$max_nvec</num_vecs>
        <decay_dir>3</decay_dir>
        <write_fingerprint>true</write_fingerprint>
        <LinkSmearing>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>${eigs_smear_rho}</link_smear_fact>
          <link_smear_num>${eigs_smear_steps}</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </LinkSmearing>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <colorvec_out>${colorvec_file}</colorvec_out>
      </NamedObject>
    </elem>
  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
  </Param>
  <RNG>
    <Seed>
      <elem>$cfg</elem>
      <elem>3189</elem>
      <elem>2855</elem>
      <elem>707</elem>
    </Seed>
  </RNG>
  <Cfg>
    <cfg_type>DISORDERED</cfg_type>
    <cfg_file>caca</cfg_file>
  </Cfg>
</chroma>
EOF

		output="$runpath/eigs.out"
		cat << EOF > $runpath/eigs.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/eigs.out0
#SBATCH -t $eigs_chroma_minutes
#SBATCH --nodes=$eigs_slurm_nodes
#SBATCH -J eig-${cfg}

run() {
	$slurm_script_prologue
	
	cd $runpath
	rm -f $colorvec_file
	$chroma -i $runpath/eigs.xml $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo $lime_file
}

outs() {
	echo $colorvec_file
}

class() {
	# class max_minutes nodes jobs_per_node
	echo a $eigs_chroma_minutes $eigs_slurm_nodes 1
}

globus() {
	[ $eigs_transfer_back == yes ] && echo ${colorvec_file}.globus ${this_ep}${colorvec_file#${confspath}} ${jlab_ep}${colorvec_file#${confspath}} ${eigs_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF
	done # cfg
done # ens
