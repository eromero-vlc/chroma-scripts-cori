#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"

		for t_source in $prop_t_sources; do
		for zphase in $prop_zphases; do
		echo "$redstar_irmom_momtype" | while read irmomx irmomy irmomz momx momy momz; do

			irmom="$irmomx $irmomy $irmomz"
			mom="$momx $momy $momz"

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

			corr_file="`corr_file_name`"
			mkdir -p `dirname ${corr_file}`

			operators="$redstar_zeromom_operators"
			[ ${mom// /_} != 0_0_0 ] && operators="$redstar_nonzeromom_operators"

			#
			# Correlation creation
			#

			prefix="t${t_source}_m${mom// /_}_z${zphase}"
			redstar_xml="$runpath/redstar_${prefix}.xml"
			mkdir -p `dirname ${redstar_xml}`
			cat << EOF > $redstar_xml
<?xml version="1.0"?>
<RedstarNPt>
  <Param>
    <version>12</version>
    <diagnostic_level>5</diagnostic_level>
    <autoIrrepCG>false</autoIrrepCG>
    <rephaseIrrepCG>false</rephaseIrrepCG>
    <Nt_corr>${redstar_t_corr}</Nt_corr>
    <convertUDtoL>true</convertUDtoL>
    <convertUDtoS>false</convertUDtoS>
    <average_1pt_diagrams>true</average_1pt_diagrams>
    <zeroUnsmearedGraphsP>false</zeroUnsmearedGraphsP>
    <t_origin>$t_origin</t_origin>
    <bc_spec>-1</bc_spec>
    <Layout>
      <lattSize>$s_size $s_size $s_size $t_size</lattSize>
      <decayDir>3</decayDir>
    </Layout>
    <ensemble>${confsname}</ensemble>

    <NPointList>
`
	for operatori in $operators; do
		for operatorj in $operators; do
			echo "
        <elem>
           <NPoint>
             <annotation>Sink</annotation>
             <elem>
               <t_slice>$redstar_t_sink</t_slice>
               <Irrep>
                 <smearedP>true</smearedP>
                 <creation_op>false</creation_op>
                 <flavor>
                   <twoI>1</twoI>
                   <threeY>3</threeY>
                   <twoI_z>1</twoI_z>
                 </flavor>
                 <irmom>
                   <mom>$irmom</mom>
                   <row>1</row>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatori</name>
                       <mom_type>$mom</mom_type>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>

             <annotation>Source</annotation>
             <elem>
               <t_slice>$t_source</t_slice>
               <Irrep>
                 <smearedP>true</smearedP>
                 <creation_op>true</creation_op>
                 <flavor>
                   <twoI>1</twoI>
                   <threeY>3</threeY>
                   <twoI_z>1</twoI_z>
                 </flavor>
                  <irmom>
                   <row>1</row>
                   <mom>$irmom</mom>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatorj</name>
                       <mom_type>$mom</mom_type>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>
           </NPoint>
         </elem>"
		done #operatorj
	done #operatori
`
    </NPointList>
  </Param> 
  <DBFiles>
    <corr_graph_xml>${runpath}/corr_graph_${prefix}.xml</corr_graph_xml>
    <proj_op_xmls></proj_op_xmls>
    <corr_graph_bin>${runpath}/corr_graph_${prefix}.bin</corr_graph_bin>
    <noneval_graph_xml>${runpath}/noneval_graph_${prefix}.xml</noneval_graph_xml>
    <vertex_coeff_xml>${runpath}/vertex_coeff_xml_${prefix}.xml</vertex_coeff_xml>
    <output_db>${corr_file}</output_db>
    <eval_graph_xml>${runpath}/eval_graph_${prefix}.xml</eval_graph_xml>
  </DBFiles> 
  <ColorVec>
    <Param>
      <version>1</version>
      <num_vecs>${redstar_nvec}</num_vecs>
      <use_derivP>false</use_derivP>
      <use_genprop4>false</use_genprop4>
      <use_FSq>false</use_FSq>
      <fake_data_modeP>false</fake_data_modeP>
      <ensemble>${confsname}</ensemble>
      <FlavorToMass>
        <elem>
          <flavor>c</flavor>
          <mass>U0.20</mass>
        </elem>
        <elem>
          <flavor>e</flavor>
          <mass>U0.20</mass>
        </elem>
        <elem>
          <flavor>l</flavor>
          <mass>U${prop_mass}</mass>
        </elem>
        <elem>
          <flavor>s</flavor>
          <mass>U-0.2050</mass>
        </elem>
        <elem>
          <flavor>y</flavor>
          <mass>U0.05</mass>
        </elem>
        <elem>
          <flavor>x</flavor>
          <mass>U0.05</mass>
        </elem>
      </FlavorToMass>
    </Param>
    <DBFiles>
      <smeared_glue_dbs>
      </smeared_glue_dbs>
      <prop_dbs>
        <elem>`prop_file_name`</elem>
      </prop_dbs>
      <twoquark_discoblock_dbs>
`
	if [ $redstar_use_disco == yes ]; then
		for i in $( disco_file_name ) ; do
			echo "<elem>$i</elem>"
		done
	fi
`
      </twoquark_discoblock_dbs>
      <smeared_baryon_dbs>
`
	if [ $redstar_use_baryon == yes ]; then
		for i in $( baryon_file_name ); do
			echo "<elem>$i</elem>"
		done
	fi
`
      </smeared_baryon_dbs>
      <unsmeared_meson_dbs>
`
	if [ $redstar_3pt == yes ]; then
        	echo "<elem>$( gprop_file_name )</elem>"
	fi
`
      </unsmeared_meson_dbs>
      <smeared_meson_dbs>
`
	if [ $redstar_use_meson == yes ]; then
		for i in $( meson_file_name ); do
			echo "<elem>$i</elem>"
		done
	fi
`
      </smeared_meson_dbs>
      <fsq_discoblock_dbs>
      </fsq_discoblock_dbs>
      <smeared_tetra_dbs>
      </smeared_tetra_dbs>
      <hadron2pt_discoblock_dbs>
      </hadron2pt_discoblock_dbs>
      <unsmeared_genprop4_dbs>
      </unsmeared_genprop4_dbs>
    </DBFiles>
  </ColorVec>
</RedstarNPt>
EOF

			output="$runpath/redstar_${prefix}.out"
			output_xml="$runpath/redstar_${prefix}_xml_out.xml"
			cat << EOF > $runpath/redstar_${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o ${output}0
#SBATCH -t $redstar_minutes
#SBATCH --nodes=1
#SBATCH -J redstar-${prefix}

run() {
	$slurm_script_prologue_redstar
	cd $runpath
	rm -f ${runpath}/corr_graph_${prefix}.xml ${runpath}/corr_graph_${prefix}.bin ${runpath}/noneval_graph_${prefix}.xml ${runpath}/vertex_coeff_xml_${prefix}.xml ${corr_file} ${runpath}/eval_graph_${prefix}.xml ${output_xml}
	$redstar_corr_graph ${redstar_xml} ${output_xml} &> $output
	$redstar_npt ${redstar_xml} ${output_xml} &>> $output
}

check() {
	grep -q "REDSTAR_NPT: total time" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo `prop_file_name | tr '\n' ' '` `meson_file_name | tr '\n' ' '` `baryon_file_name | tr '\n' ' '`
`
	[ $redstar_3pt == yes ] && echo echo $( gprop_file_name | tr '\n' ' ' )
	[ $redstar_use_disco == yes ] && echo echo $( disco_file_name | tr '\n' ' ' )
`
}

outs() {
	echo $corr_file
}

class() {
	# class max_minutes nodes jobs_per_node
	echo c $redstar_minutes 1 $redstar_jobs_per_node
}

globus() {
	[ $redstar_transfer_back == yes ] && echo ${corr_file}.globus ${this_ep}${corr_file#${confspath}} ${jlab_ep}${corr_file#${confspath}} ${redstar_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # mom
		done # zphase
		done # t_source
	done # cfg
done # ens
