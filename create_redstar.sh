#!/bin/bash

source ensembles.sh

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
		elif [ $momx == $momy -o $momy == $momz ]; then
			echo nnm
		else
			echo nmk
		fi
	done
}

insertion_mom() {
	echo "$@" | while read momix momiy momiz momjx momjy momjz; do
		echo "$(( momix - momjx )) $(( momiy - momjy )) $(( momiz - momjz ))"
	done
}

get_ops() {
	varname="redstar_`mom_letters $@`"
	echo "${!varname}"
}

# | Operator Name          | Isospin | Gamma Structure | flavor/twoI | irmom/row
# |----------------------- |---------|-----------------|-------------| ---------
# | fl_a0xDX__J0_A1        |       0 |               1 |     0       |    1
# | a_a0xDX__J0_A1         |       1 |               1 |     2       |    1
# | omegal_rhoxDX__J1_T1   |       0 |             g_k |     0       |  1 2 3
# | rho_rhoxDX__J1_T1      |       1 |             g_k |     2       |  1 2 3
# | hl_b1xDX__J1_T1        |       0 |         g_i g_j |     0       |  1 2 3
# | b_b1xDX__J1_T1         |       1 |         g_i g_j |     2       |  1 2 3
# | etal_pion_2xDX__J0_A1  |       0 |         g_5 g_4 |     0       |    1
# | pion_pion_2xDX__J0_A1  |       1 |         g_5 g_4 |     2       |    1
# | hl_b0xDX__J0_A1        |       0 |             g_4 |     0       |    1
# | b_b0xDX__J0_A1         |       1 |             g_4 |     2       |    1
# | omegal_rho_2xDX__J1_T1 |       0 |         g_k g_4 |     0       |  1 2 3
# | rho_rho_2xDX__J1_T1    |       1 |         g_k g_4 |     2       |  1 2 3
# | fl_a1xDX__J1_T1        |       0 |         g_k g_5 |     0       |  1 2 3
# | a_a1xDX__J1_T1         |       1 |         g_k g_5 |     2       |  1 2 3
# | etal_pionxDX__J0_A1    |       0 |             g_5 |     0       |    1
# | pion_pionxDX__J0_A1    |       1 |             g_5 |     2       |    1

operator_rows() {
	case $1 in
		etal_*|pion*|hl_b0*|b_b0*|fl_a0*|a_a0*|hc_b0*) echo 1 ;;
		omegal_*|rho_*|hl_b1*|b_b1*|fl_a1*|a_a1*) echo 1 2 3 ;;
		*) echo "operator_rows: $1 ?" >&2; exit 1;;
	esac
}

operator_twoI() {
	case $1 in
		hc_b0*) echo 0 ;;
		etal*|hl_b0*|fl_a0*|omegal_rho*|hl_b1*|fl_a1*) echo 0 ;;
		pion*|b_b0*|a_a0*|rho_rho*|b_b1*|a_a1*) echo 2 ;;
		*) echo "operator_twoI: $1 ?" >&2; exit 1;;
	esac
}

npoint_2pt() {
	local phasei="$1"
	local momi="$2"
	local phasej="$3"
	local momj="$4"
	for operatori in $( get_ops $momi ) ; do
		for operatorj in $( get_ops $momj ) ; do
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
                   <mom>$momi</mom>
                   <row>1</row>
                 </irmom>
                 <phasing>$phasei</phasing>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatori</name>
                       <mom_class>$( momtype $momi )</mom_class>
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
                   <mom>$momj</mom>
                 </irmom>
                 <phasing>$phasej</phasing>
                 <Op>
                   <Operators>
                     <elem>
                       <name>$operatorj</name>
                       <mom_class>$( momtype $momj )</mom_class>
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
	local phasingi="$1"
	local momi="$2"
	local operatorsi="$( get_ops $momi )"
	local phasingj="$3"
	local momj="$4"
	local operatorsj="$( get_ops $momj )"
	local momk="$( insertion_mom $momi $momj )"
	local operatorsk="$5"
	local t_seps="$6"
	local disps="$7"
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
                 <phasing>$phasingi</phasing>
                 <Op>
                   <Operators>
                     <elem>
                       <name> $( for operatori in $operatorsi; do echo "<alt>$operatori</alt>"; done ) </name>
                       <mom_class>$momtypei</mom_class>
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
                   <twoI>$( operator_twoI $operatork )</twoI>
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
                       <mom_class>$momtypek</mom_class>
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
                 <phasing>$phasingj</phasing>
                 <Op>
                   <Operators>
                     <elem>
                       <name> $( for operatorj in $operatorsj; do echo "<alt>$operatorj</alt>"; done ) </name>
                       <mom_class>$momtypej</mom_class>
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

corr_graph() {
	local corr_graph_file="$1"
	local corr_file="$2"
	local t_origin="$3"
	local tseps="$4"
	shift 4
	ops="$@"
	echo "<?xml version=\"1.0\"?>
<RedstarNPt>
  <Param>
    <version>14</version>
    <cgc_options>
      <autoIrrepCG>true</autoIrrepCG>
      <rephaseIrrepCG>true</rephaseIrrepCG>
      <enableCGTargetMomRotation>true</enableCGTargetMomRotation>
      <autoCGVersion>1</autoCGVersion>
    </cgc_options>
    <diagnostic_level>0</diagnostic_level>
    <Nt_corr>${redstar_t_corr}</Nt_corr>
    <convertUDtoL>true</convertUDtoL>
    <convertUDtoS>false</convertUDtoS>
    <average_1pt_diagrams>true</average_1pt_diagrams>
    <zeroUnsmearedGraphsP>$( if [ $redstar_disco == yes ]; then echo false ; else echo true ; fi )</zeroUnsmearedGraphsP>
    <t_origin>$t_origin</t_origin>
    <bc_spec>-1</bc_spec>
    <Layout>
      <lattSize>$s_size $s_size $s_size $t_size</lattSize>
      <decayDir>3</decayDir>
    </Layout>
    <ensemble>${confsname}</ensemble>
  </Param> 

  <NPointList>
`
	if [ $t_origin == -1 ]; then
		local insert_op_mom_combo
		for insert_op_mom_combo in $ops ; do
			local insertion_op="$( get_type_from_corr_line ${insert_op_mom_combo//\~/ } )"
			local momi="$( get_sink $( get_mom_from_corr_line ${insert_op_mom_combo//\~/ } ) )"
			local phasei="$( get_sink $( get_phase_from_corr_line ${insert_op_mom_combo//\~/ } ) )"
			local momj="$( get_source $( get_mom_from_corr_line ${insert_op_mom_combo//\~/ } ) )"
			local phasej="$( get_source $( get_phase_from_corr_line ${insert_op_mom_combo//\~/ } ) )"
			if [ $insertion_op == 2pt ] ; then
				npoint_2pt "$phasei" "$momi" "$phasej" "$momj"
			else
				npoint_3pt "$phasei" "$momi" "$phasej" "$momj" "$insertion_op" "$tseps" "$redstar_insertion_disps"
			fi
		done
	fi
`
  </NPointList>
  <DBFiles>
    <proj_op_xmls></proj_op_xmls>
    <corr_graph_bin>${corr_graph_file}</corr_graph_bin>
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
      <genprop_return_zero_value_for_t_slice_outside_source_sink_range>true</genprop_return_zero_value_for_t_slice_outside_source_sink_range>
      <ensemble>${confsname}</ensemble>
      <FlavorToMass>
        <elem>
          <flavor>c</flavor>
          <mass>U${prop_mass}</mass>
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
    </Param>"
	if [ $t_origin != -1 ]; then
		echo "
    <DBFiles>
      <smeared_glue_dbs>
      </smeared_glue_dbs>
      <prop_dbs>
`
		for i in $( prop_file_name ) ; do
			echo "<elem>$i</elem>"
		done
`
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
	if [ $redstar_use_gprops == yes ]; then
		local are_there_3pt="nop"
		local insert_op_mom_combo
		for insert_op_mom_combo in $ops ; do
			local insertion_op="$( get_type_from_corr_line ${insert_op_mom_combo//\~/ } )"
			[ $insertion_op != 2pt ] && are_there_3pt="yes"
		done
		if [ $are_there_3pt == yes ] ; then
			local i
			for phase in $( get_phases_in_3pt_mom_group $ops ) ; do
				for i in $( gprop_file_name ); do
					echo "<elem>$i</elem>"
				done
			done
		fi
	fi
`
      </unsmeared_genprop4_dbs>
    </DBFiles>
"
	fi
	echo "
  </ColorVec>
</RedstarNPt>
"
}

redstar_files="`mktemp`"

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running redstar
	[ $run_redstar != yes ] && continue

	[ ${run_onthefly} != yes ] && max_moms_per_job=1

	get_grouping_vars

	corr_runpath="$PWD/${tag}/redstar_corr_graph-${ens}"
	rm -rf $corr_runpath
	mkdir -p $corr_runpath

	template_runpath="$PWD/${tag}/redstar_template-${ens}"
	rm -rf ${template_runpath}
	mkdir -p ${template_runpath}
	cfg="@CFG"
	runpath="$PWD/${tag}/conf_${cfg}"
	rm -f ${redstar_files}*

	k_split $max_phases_per_job $phase_groups | while read phase_group ; do
	phase_leader="`take_first $phase_group`"
	k_split $max_tseps_per_job $tsep_groups | while read tsep_group ; do
		tsep_leader="`take_first $tsep_group`"

		k_split $max_moms_per_job $( word_moms_filtered_by_phases $phase_group ) | while read this_all_moms ; do
			mom_leader="`take_first $this_all_moms`"
			combo_line=0
			k_split_lines $(( slurm_procs_per_node*redstar_slurm_nodes )) $( get_corr_lines $this_all_moms ) | while read insert_op_mom_combos ; do
				corr_graph_bin="${corr_runpath}/corr_graph_insop${combo_line}_m${mom_leader}_tsep${tsep_leader}.bin"
				output="${corr_graph_bin}.out"
				cat << EOF > ${corr_graph_bin}.sh
$slurm_sbatch_prologue
#SBATCH -o ${output}0
#SBATCH -t $redstar_minutes
#SBATCH --nodes=1
#SBATCH -J r-corr-graph

environ() {
	$slurm_script_prologue_redstar
}

run() {
	tmp_runpath="${localpath}/${corr_graph_bin//\//_}"
	[ -e ${localpath} ] || tmp_runpath="\${TMPDIR:-/tmp}/${corr_graph_bin//\//_}"
	mkdir -p \$tmp_runpath
	cd \$tmp_runpath
	rm -f ${corr_graph_bin}
	cat << EOFeof > corr_graph.xml
$( corr_graph "${corr_graph_bin}" "none" "-1" "${tsep_group}" $insert_op_mom_combos )
EOFeof
	echo Starting $redstar_corr_graph corr_graph.xml output_xml > $output
	$redstar_corr_graph corr_graph.xml output_xml &>> $output
	rm -r \$tmp_runpath
}

check() {
	grep -q "REDSTAR_CORR_GRAPH: total time" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() { echo -n; }

outs() {
	echo $corr_graph_bin
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo c $redstar_minutes 1 $redstar_jobs_per_node 0
}

globus() { echo -n; }

eval "\${1:-run}"
EOF

				for t_source in $prop_t_sources; do
					corr_file="`mom="${mom_leader//_/ }" insertion_op=${combo_line} tsep=$tsep_leader corr_file_name`"
					mkdir -p `dirname ${corr_file}`
					prefix="t${t_source}_insop${combo_line}_mf${mom_leader}_tsep${tsep_leader}"
					redstar_xml="redstar_${prefix}.xml"
					output_xml="redstar_xml_out_${prefix}.out"
					output="$runpath/redstar_${prefix}.out"
					redstar_sh="redstar_${prefix}.sh"
					[ $run_onthefly == yes ] && redstar_sh+=".future"
					redstar_sh+=".template"
					echo ${redstar_sh} >> ${redstar_files}.tsrc$t_source
					cat << EOF > $template_runpath/${redstar_sh}
$slurm_sbatch_prologue
#SBATCH -o ${output}0
#SBATCH -t $redstar_minutes
#SBATCH --nodes=1
#SBATCH -J redstar-${prefix}

environ() {
	$slurm_script_prologue_redstar
}

run() {
	find ${localpath} &> $output
	tmp_runpath="${localpath}/${runpath//\//_}_$prefix"
	mkdir -p \$tmp_runpath
	cd \$tmp_runpath
	rm -f ${corr_file}
	cat << EOFeof > redstar.xml
$( corr_graph "${corr_graph_bin}" "$corr_file" "@T_ORIGIN" "${tsep_group}" $insert_op_mom_combos )
EOFeof
	mkdir -p `dirname ${corr_file}`
	echo Starting $redstar_npt redstar.xml output.xml >> $output
	$redstar_npt redstar.xml output.xml &>> $output
	rm -rf \$tmp_runpath
}

check() {
	[ -f $corr_file ] || exit 1
	tail -n 10 ${output} 2> /dev/null | grep -q "REDSTAR_NPT: total time" && exit 0
	exit 1
}

deps() {
	echo ${corr_graph_bin}
`
	[ $redstar_use_meson == yes ] && echo echo $( meson_file_name | tr '\n' ' ' )
	[ $redstar_use_baryon == yes ] && [ $run_onthefly != yes -o $run_baryons != yes ] && echo echo $( baryon_file_name | tr '\n' ' ' )
	[ $run_onthefly != yes -o $run_props != yes ] && echo echo $( prop_file_name | tr '\n' ' ' )
	[ $redstar_use_gprops == yes ] && [ $run_onthefly != yes -o $run_gprops != yes ] && echo echo $( tseps="${tsep_group}" gprop_file_name | tr '\n' ' ' )
	[ $redstar_use_disco == yes ] && echo echo $( disco_file_name | tr '\n' ' ' )
`
}

outs() {
	echo $corr_file
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo d $redstar_minutes 1 $redstar_jobs_per_node $redstar_max_concurrent_jobs
}

globus() {
	[ $redstar_transfer_back == yes ] && echo ${corr_file}.globus ${this_ep}${corr_file#${confspath}} ${jlab_ep}${corr_file#${confspath}} ${redstar_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF
				done # t_source
	
				combo_line="$(( combo_line+1 ))"
			done # insert_op_mom_combos
		done # this_all_moms
	done # tsep_group
	done # phase_group

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		[ -f ${runpath}.tar.gz ] && continue
		mkdir -p ${runpath}

		for t_source in $prop_t_sources; do

			# Find t_origin
			t_offset="`shuffle_t_source $cfg $t_size $t_source`"

			cat ${redstar_files}.tsrc$t_source | while read template_file; do
				cat << EOF > $runpath/${template_file%.template}
$slurm_sbatch_prologue
#SBATCH -o $runpath/${template_file%.sh.template}.out0
#SBATCH -t $redstar_minutes
#SBATCH --nodes=1
#SBATCH -J redstar-${prefix}

t="\$(mktemp)"
sed 's/@CFG/${cfg}/g; s/@T_ORIGIN/$t_offset/g' ${template_runpath}/${template_file} > \$t
if [ x\$1 == x ]; then
	. \$t environ
	bash $BASH_INVOCATION_OPTIONS \$t
	r="\$?"
	rm -f \$t
	exit \$r
elif [ x\$1 == xenviron ]; then
	. \$t \$@
	rm -f \$t
elif [ x\$1 == xrun ]; then
	bash $BASH_INVOCATION_OPTIONS \$t \$@
	r="\$?"
	rm -f \$t
	exit \$r
else
	bash \$t \$@
	r="\$?"
	rm -f \$t
	exit \$r
fi
EOF

			done # template_file
		done # t_source
	done # cfg
done # ens
