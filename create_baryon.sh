#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running baryons
	[ $run_baryons != yes ] && continue

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"

		for zphase in $baryon_zphases; do

			baryon_file="`baryon_file_name`"
			mkdir -p `dirname ${baryon_file}`

			#
			# Baryon creation
			#

			baryon_xml="$runpath/baryon_${zphase}.xml"
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
        <max_vecs>0</max_vecs>
        
        <use_derivP>true</use_derivP>
        <t_source>0</t_source>
        <Nt_forward>$t_size</Nt_forward>
        <num_vecs>$baryon_nvec</num_vecs>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>
        <phase>0.00 0.00 $zphase</phase>

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

			output="$runpath/baryon_${zphase}.out"
			cat << EOF > $runpath/baryon_${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/baryon_${zphase}.out0
#SBATCH -t $baryon_chroma_minutes
#SBATCH --nodes=$baryon_slurm_nodes
#SBATCH -J bar-${cfg}-${zphase}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $baryon_file
	srun \$MY_ARGS -n $(( slurm_procs_per_node*baryon_slurm_nodes )) -N $baryon_slurm_nodes $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $baryon_file
}

class() {
	# class max_minutes nodes
	echo b $baryon_chroma_minutes $baryon_slurm_nodes
}

globus() {
	[ $baryon_transfer_back == yes ] && echo ${baryon_file}.globus ${this_ep}${baryon_file#${confspath}} ${jlab_ep}${baryon_file#${confspath}} ${baryon_delete_after_transfer_back}
}

eval "\${1:-run}"

EOF
		done # zphase
	done # cfg
done # ens
