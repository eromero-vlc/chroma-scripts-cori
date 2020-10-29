#!/bin/bash

confs="`seq 1000 10 2310`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-rightColorvecs"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-new"
t_sources="`seq 0 6 95`"

# confs="`seq 100 10 860`"
# confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
# confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
# tag="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
# t_sources="`seq 0 6 95`"
# 
# confs="`seq 100 10 950`"
# confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
# confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
# tag="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
# t_sources="`seq 0 6 95`"
# 
# confs="`seq 2490 10 4670`"
# confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams/cl21_48_96_b6p3_m0p2416_m0p2050"
# confsname="cl21_48_96_b6p3_m0p2416_m0p2050"
# tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams"
# t_sources="`seq 0 6 95`"


t_fwd=21
t_back=21
s_size=48 # lattice spatial size
t_size=96 # lattice temporal size
t_sink=-2
t_corr=16 # Number of time slices
nvec=128 # rank basis for baryon elementals
tagcnf="n256"
tagfinal="tanjibops"
tagfinal="5ops"
tagfinal="1op"
tagfinal="allop"

confspath="$HOME/work/b6p3"
confspath="$SCRATCH/b6p3"
confspath="/scratch3/projects/phy20014/isoClover/b6p3"
redstar_gen_graph="~/phy/frontera/scalar/install/redstar/bin/redstar_gen_graph"
redstar_npt="~/phy/frontera/scalar/install/redstar/bin/redstar_npt"
harom="~/phy/frontera/scalar/install/harom/scalar/bin/harom" # OpenMP
hadron_node="~/phy/frontera/scalar/install/colorvec-pro/bin/hadron_node"

mkdir -p ${confspath}/${confsprefix}/corr

for cfg in $confs; do
lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
[ -f $lime_file ] || continue
for t_source in $t_sources; do

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

momoperatorsZero="NucleonMG1g1MxD0J0S_J1o2_G1g1 NucleonMG1g1MxD2J0S_J1o2_G1g1 NucleonMG1g1MxD2J0M_J1o2_G1g1 NucleonMHg1SxD2J2M_J1o2_G1g1 NucleonMG1g1MxD2J1A_J1o2_G1g1 NucleonMHg1SxD2J1M_J1o2_G1g1 NucleonMG1g1MxD2J1M_J1o2_G1g1"
momoperatorsNonZero="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g1MxD1J1M_J1o2_H1o2D4E1 NucleonMG1g1MxD1J1M_J3o2_H1o2D4E1 NucleonMG1g1MxD2J0M_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1A_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D4E1 NucleonMG1g1MxD2J2M_J3o2_H1o2D4E1 NucleonMG1g1MxD2J2S_J3o2_H1o2D4E1 NucleonMG1g1MxD2J2S_J5o2_H1o2D4E1 NucleonMHg1SxD1J1M_J1o2_H1o2D4E1 NucleonMHg1SxD1J1M_J3o2_H1o2D4E1 NucleonMHg1SxD1J1M_J5o2_H1o2D4E1 NucleonMHg1SxD2J0M_J3o2_H1o2D4E1 NucleonMHg1SxD2J1M_J1o2_H1o2D4E1 NucleonMHg1SxD2J2M_J1o2_H1o2D4E1 NucleonMHg1SxD2J2M_J3o2_H1o2D4E1"

cat << EOF | while read mom operators; do
0  $momoperatorsZero
1  $momoperatorsNonZero
2  $momoperatorsNonZero
3  $momoperatorsNonZero
EOF

prefix="mom$mom"
localprefix="$SCRATCH/tmp/$tag/b6p3/${prefix}_${t_source}${tagfinal}"
runpath="$PWD/$tag/$prefix/run_red_${cfg}_${t_source}_${tagfinal}"
mkdir -p $runpath

gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.${tagcnf}.mod${cfg}"
prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${nvec}.light.t0_${t_source}.${tag}.sdb${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.mod${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${nvec}.mod${cfg}"
baryon_file="${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_7.${tag}.sdb${cfg}"
final_db="${confspath}/${confsprefix}/corr/${confsname}.nuc_local.n${nvec}.tsrc_${t_source}.${tag}.${tagfinal}.mom_${mom}.sdb${cfg}"
if [ ! -f $colorvec_file ]; then echo Not found $colorvec_file; continue; fi
if [ ! -f $gauge_file ]; then echo Not found $gauge_file; continue; fi
prop_file_dep=""
if [ ! -f $prop_file ]; then
        prop_file_dep="`cat $PWD/$tag/$prefix/../run_prop_${cfg}/prop_create_run_${t_source}.sh.launched | tr -d '[:blank:]'`"
        if [ -z $prop_file_dep ] ; then echo Not found $prop_file; continue; fi
fi
baryon_file_dep=""
if [ ! -f $baryon_file ]; then
        baryon_file_dep="`cat $PWD/$tag/$prefix/../run_bar_${cfg}/harom_create_run.sh.launched | tr -d '[:blank:]'`"
         if [ -z $baryon_file_dep ] ; then echo Not found $baryon_file; continue; fi
fi

mkdir -p ${confspath}/${confsprefix}/corr

cat << EOF > $runpath/smeared_hadron_node_template.xml
<?xml version="1.0"?>
<ColorVecHadron>
<Param> 
  <version>5</version>
  <num_vecs>$nvec</num_vecs>
  <use_derivP>true</use_derivP>

  <FlavorToMass>
    <elem>
      <flavor>l</flavor>
      <mass>U-0.2416</mass>
    </elem>
    <elem>
      <flavor>s</flavor>
      <mass>U-0.2050</mass>
    </elem>
    <elem>
      <flavor>c</flavor>
      <mass>U0.2</mass>
    </elem>
    <elem>
      <flavor>e</flavor>
      <mass>U0.2</mass>
    </elem>
    <elem>
      <flavor>x</flavor>
      <mass>U0.05</mass>
    </elem>
    <elem>
      <flavor>y</flavor>
      <mass>U0.05</mass>
    </elem>
  </FlavorToMass>

</Param>
<DBFiles>
  <hadron_node_xmls>
    <elem>smeared_hadron_node.xml</elem>
  </hadron_node_xmls>
  <prop_dbs><elem>$prop_file</elem></prop_dbs>
  <baryon_dbs><elem>$baryon_file</elem></baryon_dbs>
  <meson_dbs> </meson_dbs>
  <glue_dbs></glue_dbs>
  <tetra_dbs></tetra_dbs>
  <output_db>${localprefix}/smeared_hadron_node.sdb${cfg}</output_db>
</DBFiles>
</ColorVecHadron>
EOF

cat << EOF > $runpath/harom_hadron_node_template.xml
<?xml version="1.0"?>
<harom>
<Param> 
  <InlineMeasurements>

    <elem>
      <annotation>
        Compute propagator solution vectors
      </annotation>
      <Name>UNSMEARED_HADRON_NODE_DISTILLATION</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>2</version>
        <num_vecs>${nvec}</num_vecs>
        <displacement_length>1</displacement_length>

        <FlavorToMass>
          <elem>
            <flavor>l</flavor>
            <mass>U-0.2416</mass>
          </elem>
          <elem>
            <flavor>s</flavor>
            <mass>U-0.2050</mass>
          </elem>
        </FlavorToMass>

        <LinkSmearing>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>0.1</link_smear_fact>
          <link_smear_num>10</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </LinkSmearing>
      </Param>
      <NamedObject>
        <hadron_node_xmls>
          <elem>unsmeared_hadron_node.xml</elem>
        </hadron_node_xmls>
        <gauge_file>$gauge_file</gauge_file>
        <colorvec_file>$colorvec_file</colorvec_file>
        <soln_files> </soln_files>
        <hadron_op_file>${localprefix}/unsmeared_hadron_node.sdb${cfg}</hadron_op_file>
      </NamedObject>
    </elem>

  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
</Param>

</harom>
EOF

for fake in 1; do
cat << EOF
<?xml version="1.0"?>
<RedstarNPt>
<Param> 
  <version>10</version>
  <diagnostic_level>5</diagnostic_level>

  <Nt_corr>$t_corr</Nt_corr>
  <convertUDtoL>true</convertUDtoL>
  <convertUDtoS>false</convertUDtoS>

  <average_1pt_diagrams>true</average_1pt_diagrams>
  <zeroUnsmearedGraphsP>true</zeroUnsmearedGraphsP>

  <t_origin>$t_origin</t_origin>
  <bc_spec>-1</bc_spec>  

  <Layout>
    <lattSize>$s_size $s_size $s_size $t_size</lattSize>
    <decayDir>3</decayDir>
  </Layout>

  <ensemble>$confsname</ensemble>

  <NPointList>
EOF
for operatori in $operators; do
for operatorj in $operators; do
for rowi in 1; do
for rowj in 1; do

cat << EOF
   <elem>
      <NPoint>
        <annotation>Sink</annotation>
        <elem>
          <t_slice>$t_sink</t_slice>
          <Irrep>
            <smearedP>true</smearedP>
            <creation_op>false</creation_op>
            <flavor>
              <twoI>1</twoI>
              <threeY>3</threeY>
              <twoI_z>1</twoI_z>
            </flavor>
            <irmom>
              <mom>0 0 $mom</mom>
              <row>$rowi</row>
            </irmom>
            <Op>
              <Operators>
                <elem>
                  <name>$operatori</name>
                  <mom_type>$mom 0 0</mom_type>
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
              <row>$rowj</row>
              <mom>0 0 $mom</mom>
            </irmom>
            <Op>
              <Operators>
                <elem>
                  <name>$operatorj</name>
                  <mom_type>$mom 0 0</mom_type>
                </elem>
              </Operators>
              <CGs>
              </CGs>
            </Op>
          </Irrep>
        </elem>
      </NPoint>
    </elem>
EOF

done #rowj
done #rowi
done #operatorj
done #operatori

cat << EOF
  </NPointList>
</Param>
<DBFiles>
  <corr_graph_db>eval_graph.sdb</corr_graph_db>
  <proj_op_xmls></proj_op_xmls>
  <eval_graph_xml>eval_graph.xml</eval_graph_xml>
  <noneval_graph_xml>noneval_graph.xml</noneval_graph_xml>
  <smeared_hadron_node_xml>smeared_hadron_node.xml</smeared_hadron_node_xml>
  <colorvec_smeared_hadron_node_xml>smeared_hadron_node_template.xml</colorvec_smeared_hadron_node_xml>
  <unsmeared_hadron_node_xml>unsmeared_hadron_node.xml</unsmeared_hadron_node_xml>
  <hadron_npt_graph_db>graph.sdb${cfg}</hadron_npt_graph_db>
  <hadron_node_dbs>
    <!-- elem>${localprefix}/smeared_hadron_node.sdb${cfg}</elem -->
    <elem>${localprefix}/unsmeared_hadron_node.sdb${cfg}</elem>
  </hadron_node_dbs>
  <output_db>$final_db</output_db>
</DBFiles>      
</RedstarNPt>
EOF
done > $runpath/twopt_control.xml # fake

cat << EOF > $runpath/twopt_run.sh
#!/bin/bash
#SBATCH -o $runpath/twopt_run.out
#SBATCH -t 12:00:00
#SBATCH -N 1 -n 14
#SBATCH -A FTA-Carlson
#SBATCH -p normal
#SBATCH -J red-$cfg
`
        [ "XX" != "X${baryon_file_dep}X" ] && echo "#DEPENDENCY" $baryon_file_dep
        [ "XX" != "X${prop_file_dep}X" ] && echo "#DEPENDENCY" $prop_file_dep
        echo "#CREATES" $final_db
`
cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=14
mkdir -p ${localprefix}

echo
echo "RUNINIG" $redstar_gen_graph $runpath/twopt_control.xml out.xml
echo
for i in \`seq 10\` ; do
        rm -f ${localprefix}/smeared_hadron_node.sdb${cfg} eval_graph.sdb graph.sdb${cfg}
        $redstar_gen_graph $runpath/twopt_control.xml out.xml && break
        sleep $(( RANDOM % 120 ))
done
sleep 5

# echo
# echo "RUNINIG" $hadron_node $runpath/smeared_hadron_node_template.xml out.xml
# echo
# task_affinity $hadron_node $runpath/smeared_hadron_node_template.xml out.xml
# sleep 5

echo
echo "RUNINIG" $harom -i $runpath/harom_hadron_node_template.xml -o $runpath/harom_hadron_node_template.out
echo
rm -f ${localprefix}/unsmeared_hadron_node.sdb${cfg}
task_affinity $harom -i $runpath/harom_hadron_node_template.xml -o $runpath/harom_hadron_node_template.out
sleep 5

echo
echo "RUNINIG" $redstar_npt $runpath/twopt_control.xml out.xml
echo
rm -f $final_db
task_affinity $redstar_npt $runpath/twopt_control.xml out.xml
rm -f ${localprefix}/smeared_hadron_node.sdb${cfg} ${localprefix}/unsmeared_hadron_node.sdb${cfg}
EOF

done # mom
done # t_source
done # cfg

