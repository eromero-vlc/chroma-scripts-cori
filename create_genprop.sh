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

unpack_moms() {
	echo $1 $2 $3
	echo $(( -$1 )) $(( -$2 )) $(( -$3 ))
}

num_args() {
	echo $#
}

k_split() {
	local n i f
	n="$1"
	shift
	i="0"
	for f in "$@" "__last_file__"; do
		if [ $f != "__last_file__" ]; then
			echo -n "$f "
			i="$(( i+1 ))"
			if [ $i == $n ]; then
				i="0"
				echo
			fi
		else
			[ $i != 0 ] && echo
		fi
	done
}

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running genprops
	[ $run_gprops != yes ] && continue

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

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
		k_split $gprop_max_moms_per_job $moms | while read mom_group ; do

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
			t_origin="`cat h | while read a b; do echo \$a; done`"
			t_offset="`cat h | while read a b; do echo \$b; done`"

			gprop_file="`gprop_file_name`"
			[ $gprop_are_local != yes ] && mkdir -p `dirname ${gprop_file}`

			#
			# Genprops creation
			#
			if [ $gprop_are_local == yes ]; then
				gprop_moms="$( for mom in $mom_group; do unpack_moms ${mom//_/ }; done )"
			fi
			prefix="gprop_t${t_source}_z${zphase}_mf${mom_group// /_}"
			gprop_xml="$runpath/${prefix}.xml"
			gprop_class="b"
			redstar_tasks=""
			num_redstar_tasks=0

			if [ $gprop_are_local == yes ]; then
				gprop_class="d"
				redstar_tasks="$( for mom in $mom_group; do ls $runpath/redstar_t${t_source}_*_z${zphase}_mf${mom}.sh.future; done )"
				num_redstar_tasks="$( num_args $redstar_tasks )"
				[ $num_redstar_tasks == 0 ] && continue
				baryon_xmls="$( for mom in $mom_group; do ls $runpath/baryon_${zphase}_t0_${t_source}_mf${mom}_idx0.xml; done )"
			fi

			mkdir -p `dirname ${gprop_xml}`
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
	for tsep in ${gprop_t_seps}; do
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
            <max_rhs>1</max_rhs>
            <use_multiple_writers>false</use_multiple_writers>
            <use_genprop4_format>false</use_genprop4_format>
            <use_genprop5_format>true</use_genprop5_format>
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
			output="$runpath/${prefix}.out"
			local_aux="${localpath}/${runpath//\//_}_${prefix}.aux"
			cat << EOF > $runpath/${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/${prefix}.out0
#SBATCH -t $gprop_chroma_minutes
#SBATCH --nodes=$gprop_slurm_nodes -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J gprop-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	#[ $gprop_are_local == yes ] && srun -N 1 -n 1 \$MY_ARGS mkdir -p `dirname ${gprop_file}`
	#rm -f ${gprop_file}*
	if [ $gprop_are_local == yes ] ; then
		srun -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS $chroma -i ${gprop_xml} -geom $gprop_chroma_geometry $chroma_extra_args &> $output
`
		for baryon_xml in ${baryon_xmls}; do
			echo "srun -n $(( slurm_procs_per_node*baryon_slurm_nodes )) -N $baryon_slurm_nodes \\\$MY_ARGS $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args &> ${baryon_xml%.xml}.out"
		done
`
		#disp_node="\${MY_ARGS//-r /}"
		#srun -n $(( slurm_procs_per_node*baryon_slurm_nodes )) -N $baryon_slurm_nodes -r \$(( disp_node+gprop_slurm_nodes )) $chroma -i ${baryon_xml} -geom $baryon_chroma_geometry $chroma_extra_args &> $baryon_output &
		#wait
	else
		srun -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS $chroma -i ${gprop_xml} -geom $gprop_chroma_geometry $chroma_extra_args &> $output
	fi
`
	if [ $gprop_are_local == yes ] ; then
		echo sleep 60
		echo "cat << EOFo > ${local_aux}"
		i=0
		k_split $(( (num_redstar_tasks + slurm_procs_per_node*gprop_slurm_nodes-1 ) / (slurm_procs_per_node*gprop_slurm_nodes) )) $redstar_tasks | while read js ; do
			echo "$i bash -c 'for t in $js; do bash \\\\\\\$t run; done'"
			i="$((i+1))"
		done
		echo "EOFo"
		echo srun -n $(( num_redstar_tasks < slurm_procs_per_node*gprop_slurm_nodes ? num_redstar_tasks : slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \\\$MY_ARGS --gpu-bind=closest -K0 -k -W0 --multi-prog ${local_aux}
	fi
`
}

check() {
	tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully" || exit 1
`
	if [ $gprop_are_local == yes ] ; then
		for t in $redstar_tasks; do
			echo "bash $t check || exit 1"
		done
	fi
`
	exit 0
}

blame() {
	if ! tail -n 3000 ${output} 2> /dev/null | grep -q "CHROMA: ran successfully"; then
		echo genprop creation failed
		exit 1
	fi
`
	if [ $gprop_are_local == yes ] ; then
		for t in $redstar_tasks; do
			echo "bash $t check || echo fail $t"
		done
	fi
`
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
`
	if [ $gprop_are_local == yes ] ; then
		for t in $redstar_tasks; do
			echo bash $t deps
		done
	fi
`
}

outs() {
	echo -n
`
	if [ $gprop_are_local == yes ] ; then
		for t in $redstar_tasks; do
			echo bash $t outs
		done
	else
		echo echo $gprop_file
	fi
`
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo $gprop_class $gprop_chroma_minutes $gprop_slurm_nodes 1 0
}

globus() {
	echo -n
`
	if [ $gprop_are_local == yes ] ; then
		for t in $redstar_tasks; do
			echo bash $t globus
		done
	else
		echo echo "[ $gprop_transfer_back == yes ] && echo ${gprop_file}.globus ${this_ep}${gprop_file#${confspath}} ${jlab_ep}${gprop_file#${confspath}} ${gprop_delete_after_transfer_back}"
	fi
`
}

eval "\${1:-run}"
EOF

		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
