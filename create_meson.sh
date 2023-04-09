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

			meson_file="`meson_file_name`"
			mkdir -p `dirname ${meson_file}`

			#
			# Meson creation
			#

			meson_xml="$runpath/meson_${zphase}.xml"
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
        <t_source>0</t_source>
        <Nt_forward>$t_size</Nt_forward>
        <mom2_min>1</mom2_min>
        <mom2_max>2</mom2_max>
        <mom_list>
                <elem>0 0 0</elem>
                <elem>1 0 0</elem>
                <elem>-1 0 0</elem>
                <elem>0 1 0</elem>
                <elem>0 -1 0</elem>
                <elem>0 0 1</elem>
                <elem>0 0 -1</elem>
                <elem>2 0 0</elem>
                <elem>-2 0 0</elem>
                <elem>0 2 0</elem>
                <elem>0 -2 0</elem>
                <elem>0 0 2</elem>
                <elem>0 0 -2</elem>
                <elem>3 0 0</elem>
                <elem>-3 0 0</elem>
                <elem>0 3 0</elem>
                <elem>0 -3 0</elem>
                <elem>0 0 3</elem>
                <elem>0 0 -3</elem>
        </mom_list>
        <num_vecs>$nvec</num_vecs>
        <phase>0 0 $zphase</phase>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>
        <max_tslices_in_contraction>1</max_tslices_in_contraction>

        <!-- List of displacement arrays -->
        <displacement_list>
          <elem></elem>
          <elem>1</elem>
          <elem>2</elem>
          <elem>3</elem>
          <elem>1 1</elem>
          <elem>2 2</elem>
          <elem>3 3</elem>
          <elem>1 2</elem>
          <elem>1 3</elem>
          <elem>2 1</elem>
          <elem>2 3</elem>
          <elem>3 1</elem>
          <elem>3 2</elem>
        </displacement_list>
    
        <Should the smearing be the same as the colorvec? 
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

			output="$runpath/meson_${zphase}.out"
			cat << EOF > $runpath/meson_${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/meson_${zphase}.out0
#SBATCH -t 0:40:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH -J meson-${cfg}-${zphase}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $meson_file
	srun \$MY_ARGS -n 4 -N 1 $chroma -i ${meson_xml} -geom 1 1 2 2 $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $meson_file
}

class() {
	# class max_minutes nodes
	echo b 600 1
}

globus() {}

eval "\${1:-run}"
EOF
		done # zphase
	done # cfg
done # ens
