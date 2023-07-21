#!/bin/bash

source ensembles.sh

momtype() {
	for i in "$@"; do echo $i; done | tr -d '-' | sort -nr | tr '\n' ' '
}

num_zeros_mom() {
	local n=0
	for i in $@; do
		[ "$i" == 0 ] && n="$(( n+1 ))"
	done
	echo $n
}

mom_letters() {
	if [ $# != 3 ]; then
		echo "mom_letters should get three args"  >&2
		exit 1
	fi
	echo "`momtype $@`" | while read momx momy momz; do
		if [ $momx == 0 -a $momy == 0 -a $momz == 0 ]; then
			echo 000
		elif [ $momx != 0 -a $momy == 0 -a $momz == 0 ]; then
			echo n00
		elif [ $momx == $momy -a $momz == 0 ]; then
			echo nn0
		elif [ $momx != $momy -a $momz == 0 ]; then
			echo nm0
		elif [ $momx == $momy -a $momx == $momz ]; then
			echo nnn
		elif [ $momx == $momy -a $momx != $momz ]; then
			echo nnm
		else
			echo nmk
		fi
	done
}

insertion_mom() {
	echo "$@" | while read momix momiy momiz momjx momjy momjz; do
		echo "$(( momjx - momix )) $(( momjy - momiy )) $(( momjz - momiz ))"
	done
}

mom_word() {
	echo ${1}_${2}_${3}_${4}_${5}_${6}
}

get_ops() {
	varname="redstar_`mom_letters $@`"
	echo "${!varname}"
}

operator_rows() {
	case $1 in
		pion*|b_b0*|a_a0*) echo 1 ;;
		rho_rho*|b_b1*|a_a1*) echo 1 2 3 ;;
		*) echo "operator_rows: $1 ?" >&2; exit 1;;
	esac
}

npoint_2pt() {
	local mom="$1"
	local operators="$2"
	for operatori in $operators; do
		for operatorj in $operators; do
			echo "
        <elem>
           <NPoint>
             <annotation>Sink</annotation>
             <elem>
               <t_slice>-2</t_slice>
               <Irrep>
                 <smearedP>true</smearedP>
                 <creation_op>false</creation_op>
                 <flavor>
                   <twoI>1</twoI>
                   <threeY>3</threeY>
                   <twoI_z>1</twoI_z>
                 </flavor>
                 <irmom>
                   <mom>$mom</mom>
                   <row>1</row>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatori</name>
                       <mom_type>$( momtype $mom )</mom_type>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>

             <annotation>Source</annotation>
             <elem>
               <t_slice>0</t_slice>
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
                   <mom>$mom</mom>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatorj</name>
                       <mom_type>$( momtype $mom )</mom_type>
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
}

npoint_3pt() {
	local momi="$1"
	local operatorsi="$2"
	local momj="$3"
	local operatorsj="$4"
	local momk="$5"
	local operatorsk="$6"
	local t_seps="$7"
	local disps="$8"
	local momtypei="$( momtype $momi )"
	local momtypej="$( momtype $momj )"
	local momtypek="$( momtype $momk )"
	for operatork in $operatorsk; do
		echo "
         <elem>
           <NPoint>
             <annotation>Sink</annotation>
             <elem>
               <t_slice> $( for t_sep in $t_seps; do echo -n "<alt>$t_sep</alt>"; done ) </t_slice>
               <Irrep>
                 <creation_op>false</creation_op>
                 <smearedP>true</smearedP>
                 <flavor>
                   <twoI>1</twoI>
                   <threeY>3</threeY>
                   <twoI_z>1</twoI_z>
                 </flavor>
                 <irmom>
                   <row> $( for rowi in 1 2; do echo -n "<alt>$rowi</alt>"; done ) </row>
                   <mom>$momi</mom>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name> $( for operatori in $operatorsi; do echo "<alt>$operatori</alt>"; done ) </name>
                       <mom_type>$momtypei</mom_type>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>

             <annotation>Insertion</annotation>
             <elem>
               <t_slice>-3</t_slice>
               <Irrep>
                 <creation_op>true</creation_op>
                 <smearedP>false</smearedP>
                 <flavor>
                   <twoI>2</twoI>
                   <threeY>0</threeY>
                   <twoI_z>0</twoI_z>
                 </flavor>
                 <irmom>
                   <row> $( for rowk in $( operator_rows $operatork ); do echo -n "<alt>$rowk</alt>"; done ) </row>
                   <mom>$momk</mom>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name>${operatork}</name>
                       <mom_type>$momtypek</mom_type>
                       <disp_list>$( echo "$disps" | while read disp_prefix disp_list; do [ x${disp_prefix}x != xx ] && echo "<alt>$disp_list</alt>"; done ) </disp_list>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>

             <annotation>Source</annotation>
             <elem>
               <t_slice>0</t_slice>
               <Irrep>
                 <creation_op>true</creation_op>
                 <smearedP>true</smearedP>
                 <flavor>
                   <twoI>1</twoI>
                   <threeY>3</threeY>
                   <twoI_z>1</twoI_z>
                 </flavor>
                 <irmom>
                   <row> $( for rowj in 1 2; do echo -n "<alt>$rowj</alt>"; done ) </row>
                   <mom>$momj</mom>
                 </irmom>
                 <Op>
                   <Operators>
                     <elem>
                       <name> $( for operatorj in $operatorsj; do echo "<alt>$operatorj</alt>"; done ) </name>
                       <mom_type>$momtypej</mom_type>
                     </elem>
                   </Operators>
                   <CGs>
                   </CGs>
                 </Op>
               </Irrep>
             </elem>
           </NPoint>
         </elem>"
	done #operatork
}

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue

	all_moms_2pt=""
	all_moms_3pt=""
	if [ $redstar_2pt == yes ]; then
		all_moms_2pt="`
			echo "$redstar_2pt_moms" | while read mom; do
				mom_word $mom
			done
		`"
	fi
	if [ $redstar_3pt == yes ]; then
		all_moms_3pt="`
			echo "$redstar_3pt_srcmom_snkmom" | while read momij; do
				mom_word $momij
			done
		`"
	fi
	all_moms="`echo "$all_moms_2pt $all_moms_3pt" | sort -u`"

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p ${runpath}

		for t_source in $prop_t_sources; do

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

			for zphase in $prop_zphases; do
			echo "$all_moms" | while read momw; do
			for insertion_op in "_2pt_" $redstar_insertion_operators; do
				[ ${redstar_2pt} != yes -a ${insertion_op} == _2pt_ ] && continue

				mom="${momw//_/ }"
				corr_file="`corr_file_name`"
				mkdir -p `dirname ${corr_file}`

				#
				# Correlation creation
				#

				prefix="t${t_source}_insop${insertion_op}_m${momw}_z${zphase}"
				redstar_xml="$runpath/redstar_${prefix}.xml"
 				cat << EOF > $redstar_xml
<?xml version="1.0"?>
<RedstarNPt>
  <Param>
    <version>12</version>
    <diagnostic_level>0</diagnostic_level>
    <autoIrrepCG>false</autoIrrepCG>
    <rephaseIrrepCG>false</rephaseIrrepCG>
    <Nt_corr>${redstar_t_corr}</Nt_corr>
    <convertUDtoL>true</convertUDtoL>
    <convertUDtoS>false</convertUDtoS>
    <average_1pt_diagrams>true</average_1pt_diagrams>
    <zeroUnsmearedGraphsP>false</zeroUnsmearedGraphsP>
    <t_origin>$(( (t_origin+t_source)%t_size ))</t_origin>
    <bc_spec>-1</bc_spec>
    <Layout>
      <lattSize>$s_size $s_size $s_size $t_size</lattSize>
      <decayDir>3</decayDir>
    </Layout>
    <ensemble>${confsname}</ensemble>

    <NPointList>
`
	if [ ${redstar_2pt} == yes -a ${insertion_op} == _2pt_ ]; then
		echo "$redstar_2pt_moms" | while read momi; do
			[ "$momw" != "$( mom_word $momi )" ] && continue
			operators="$redstar_zeromom_operators"
			[ $momw != 0_0_0___ ] && operators="$redstar_nonzeromom_operators"
			npoint_2pt "$momi" "$operators"
		done #momi
	fi
	if [ ${redstar_3pt} == yes -a ${insertion_op} != _2pt_ ]; then
		echo "$redstar_3pt_srcmom_snkmom" | while read momix momiy momiz momj; do
			momi="$momix $momiy $momiz"
			[ "$momw" != "$( mom_word $momi $momj )" ] && continue
			operatorsi="$( get_ops $momi )"
			operatorsj="$( get_ops $momj )"
			momk="$( insertion_mom $momi $momj )"
			npoint_3pt "$momi" "$operatorsi" "$momj" "$operatorsj" "$momk" "$insertion_op" "$gprop_t_seps" "$redstar_insertion_disps"
		done #mom
	fi
`
    </NPointList>
  </Param> 
  <DBFiles>
    <proj_op_xmls></proj_op_xmls>
    <corr_graph_bin>corr_graph_${prefix}.bin</corr_graph_bin>
    <output_db>${corr_file}</output_db>
  </DBFiles> 
  <ColorVec>
    <Param>
      <version>1</version>
      <num_vecs>${redstar_nvec}</num_vecs>
      <use_derivP>false</use_derivP>
      <use_genprop4>true</use_genprop4>
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
`
	if [ $redstar_3pt == yes ]; then
        	echo "<elem>$( gprop_file_name )</elem>"
	fi
`
      </unsmeared_genprop4_dbs>
    </DBFiles>
  </ColorVec>
</RedstarNPt>
EOF

			output_xml="redstar_xml_out_${prefix}.out"
			output="$runpath/redstar_${prefix}.out"
			cat << EOF > $runpath/redstar_${prefix}.sh
$slurm_sbatch_prologue
#SBATCH -o ${output}0
#SBATCH -t $redstar_minutes
#SBATCH --nodes=1
#SBATCH -J redstar-${prefix}

run() {
	$slurm_script_prologue_redstar
	tmp_runpath="\${TMPDIR:-/tmp}/${runpath//\//_}"
	mkdir -p \$tmp_runpath
	cd \$tmp_runpath
	rm -f corr_graph_${prefix}.bin ${corr_file}
	echo Starting $redstar_corr_graph $redstar_xml $output_xml > $output
	$redstar_corr_graph $redstar_xml $output_xml &>> $output || exit 1
	echo Starting $redstar_npt $redstar_xml $output_xml &>> $output
	$redstar_npt $redstar_xml $output_xml &>> $output
	rm -f $output_xml corr_graph_${prefix}.bin
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

		done # insertion_op
		done # mom
		done # zphase
		done # t_source
	done # cfg
done # ens
