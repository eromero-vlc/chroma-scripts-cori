#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running eigs
	[ $run_eigs != yes ] && continue

	# Create the directory to store the eigenvectors
	mkdir -p ${confspath}/${confsprefix}/eig

	for cfg in $confs; do
		lime_file_name="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue
		
		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath
		
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
        <write_fingerprint>false</write_fingerprint>
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
      <elem>2551</elem>
      <elem>3189</elem>
      <elem>2855</elem>
      <elem>707</elem>
    </Seed>
  </RNG>
  <Cfg>
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>
</chroma>
EOF

		output="$runpath/eigs.out"
		cat << EOF > $runpath/eigs.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/eigs.out0
#SBATCH -t 10:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-task=1
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J eig-${cfg}

run() {
	$slurm_script_prologue
	
	cd $runpath
	rm -f $colorvec_file
	srun \$MY_ARGS -n 4 -N 1 $chroma -i $runpath/eigs.xml -geom 1 1 2 2 $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} && exit 0
	exit 1
}

deps() {
	echo $lime_file
}

outs() {
	echo $colorvec_file
}

class() {
	# class max_minutes nodes
	echo a 600 1
}

globus() {
	[ $eigs_transfer_back == yes ] && echo ${colorvec_file}.globus ${this_ep}${colorvec_file#${confspath}} ${jlab_ep}${colorvec_file#${confspath}} ${eigs_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF
	done # cfg
done # ens
