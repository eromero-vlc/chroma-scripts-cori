#!/bin/bash

source ensembles.sh

mom_word() {
	echo ${1}_${2}_${3}
}

mom_fly() {
	if [ $1 -gt $4 ] || [ $1 -eq $4 -a $2 -gt $5 ] || [ $1 -eq $4 -a $2 -eq $5 -a $3 -ge $6 ]; then
		echo $(( $1-$4 )) $(( $2-$5 )) $(( $3-$6 ))
	else
		echo $(( $4-$1 )) $(( $5-$2 )) $(( $6-$3 ))
	fi
}

mom_split() {
	echo $1 $2 $3
	echo $4 $5 $6
}


for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running baryons
	[ $run_baryons != yes ] && continue

	moms="all"
	if [ $gprop_are_local == yes ]; then
		moms="`
			echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
				mom_word $( mom_fly $momij )
			done | sort -u
		`"
	else
		gprop_max_moms_per_job=1
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
			[ ${gprop_are_local} == yes ] && t_sources="$gprop_t_sources"
			for gprop_t_source in $t_sources; do
			for momf in $moms; do

			if [ ${gprop_are_local} == yes ] ; then
				first_t_source=$gprop_t_source
				Nt_forward_total=$redstar_t_corr
				baryon_moms_xml="
<mom_list>
	`
		echo "$redstar_3pt_snkmom_srcmom" | while read momij; do
			[ $( mom_word $( mom_fly $momij ) ) == $momf ] && mom_split $momij
		done | sort -u | while read mom; do
			echo "<elem>$mom</elem>"
		done
	`
</mom_list>"
			else
				first_t_source=0
				Nt_forward_total=$t_size
				baryon_moms_xml="
<mom_list>
	`echo "$gprop_moms" | while read mom; do echo "<elem>$mom</elem>"; done`
</mom_list>"
			fi

			baryon_files="`baryon_file_name`"
			baryon_file_index=0
			baryon_file_num="`echo $baryon_files | wc -w`"
			for baryon_file in $baryon_files; do
				[ ${gprop_are_local} != yes ] && mkdir -p `dirname ${baryon_file}`

				t_source="$(( first_t_source + Nt_forward_total/baryon_file_num*baryon_file_index ))"
				if [ $baryon_file_index != $(( baryon_file_num-1 )) ]; then
					Nt_forward="$(( Nt_forward_total/baryon_file_num ))"
				else
					Nt_forward="$(( first_t_source+Nt_forward_total - t_source ))"
				fi
				
				# Find t_origin
				perl -e " 
  srand($cfg);

  # Call a few to clear out junk                                                                                                          
  foreach \$i (1 .. 20)
  {
    rand(1.0);
  }
  \$t_origin = int(rand($t_size));
  \$t_offset = ($t_source + \$t_origin) % $t_size;
  print \"\$t_origin \$t_offset\\n\"
" > h
				t_offset="`cat h | while read a b; do echo \$b; done`"
				baryon_t_source="${t_source}"
				[ ${gprop_are_local} == yes ] && baryon_t_source="${t_offset}"
				prefix="$runpath/baryon_${zphase}_t0_${gprop_t_source}_mf${momf}_idx${baryon_file_index}"
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
        <max_vecs>0</max_vecs>
        
        <use_derivP>true</use_derivP>
        <t_source>$baryon_t_source</t_source>
        <Nt_forward>$Nt_forward</Nt_forward>
        <num_vecs>$baryon_nvec</num_vecs>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>
        <phase>0.00 0.00 $zphase</phase>
        <use_superb_format>true</use_superb_format>

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
				[ $gprop_are_local != yes ] && cat << EOF > ${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o ${prefix}.out0
#SBATCH -t $baryon_chroma_minutes
#SBATCH --nodes=$baryon_slurm_nodes -n $(( slurm_procs_per_node*baryon_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J bar-${cfg}-${zphase}-${baryon_file_index}

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
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo b $baryon_chroma_minutes $baryon_slurm_nodes 1 0
}

globus() {
	[ $baryon_transfer_back == yes ] && echo ${baryon_file}.globus ${this_ep}${baryon_file#${confspath}} ${jlab_ep}${baryon_file#${confspath}} ${baryon_delete_after_transfer_back}
}

eval "\${1:-run}"

EOF
				baryon_file_index="$(( baryon_file_index+1 ))"
			done # baryon_file
			done # momf
			done # t_source
		done # zphase
	done # cfg
done # ens
