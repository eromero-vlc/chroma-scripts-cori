#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running mesons
	[ $run_mesons != yes ] && continue

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"

		for zphase in $meson_zphases; do

			meson_files="`meson_file_name`"
			meson_file_index=0
			meson_file_num="`echo $meson_files | wc -w`"
			for meson_file in $meson_files; do
				mkdir -p `dirname ${meson_file}`

				#
				# Meson creation
				#

				t_source="$(( t_size/meson_file_num*meson_file_index ))"
				if [ $meson_file_index != $(( meson_file_num-1 )) ]; then
					Nt_forward="$(( t_size/meson_file_num ))"
				else
					Nt_forward="$(( t_size - t_source ))"
				fi
				meson_xml="$runpath/meson_${zphase}_${meson_file_index}.xml"
				cat << EOF > $meson_xml
<?xml version="1.0"?>
<chroma>
<Param>
  <InlineMeasurements>
    <elem>
      <Name>MESON_MATELEM_COLORVEC_SUPERB</Name>
      <Frequency>1</Frequency>
      
      <Param>
        <version>4</version>
        <use_derivP>true</use_derivP>
        <t_source>$t_source</t_source>
        <Nt_forward>$Nt_forward</Nt_forward>
        <num_vecs>$meson_nvec</num_vecs>
        <mom2_min>0</mom2_min>
        <mom2_max>0</mom2_max>
        <phase>0 0 $zphase</phase>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>
        <max_tslices_in_contraction>$meson_chroma_max_tslices_in_contraction</max_tslices_in_contraction>

        $meson_extra_xml

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
        <meson_op_file>${meson_file}</meson_op_file>
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

				output="$runpath/meson_${zphase}_${meson_file_index}.out"
				cat << EOF > $runpath/meson_${zphase}_${meson_file_index}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/meson_${zphase}.out0
#SBATCH -t $meson_chroma_minutes
#SBATCH --nodes=$meson_slurm_nodes -n $(( slurm_procs_per_node*meson_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J meson-${cfg}-${zphase}-${meson_file_index}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $meson_file
	srun \$MY_ARGS -n $(( slurm_procs_per_node*meson_slurm_nodes )) -N $meson_slurm_nodes $chroma -i ${meson_xml} -geom $meson_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $meson_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo b $meson_chroma_minutes $meson_slurm_nodes 1 0
}

globus() { echo -n; }

eval "\${1:-run}"
EOF
				meson_file_index="$(( meson_file_index+1 ))"
			done # meson_file
		done # zphase
	done # cfg
done # ens
