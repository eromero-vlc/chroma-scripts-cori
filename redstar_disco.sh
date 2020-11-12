#!/bin/bash

confs="`seq 1000 10 3160`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"
t_sources="`seq 0 16 63`"


t_fwd=21
t_back=21
s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
t_sink=-2
t_corr=7 # Number of time slices
nvec=64 # rank basis for baryon elementals
tagfinal="disco.1op"

confspath="/cache/isoClover/b6p3"
redstar_gen_graph="/work/JLabLQCD/eromero/qcd_software/scalar/install/redstar-pdf/bin/redstar_gen_graph"
redstar_npt="/work/JLabLQCD/eromero/qcd_software/scalar/install/redstar-pdf/bin/redstar_npt"
noneval_graph="/work/JLabLQCD/eromero/qcd_software/scalar/install/colorvec-pdf/bin/noneval_graph"
hadron_node="/work/JLabLQCD/eromero/qcd_software/scalar/install/colorvec-pdf/bin/hadron_node"
unsmeared_hadron_node="/work/JLabLQCD/eromero/qcd_software/scalar/install/colorvec-pdf/bin/unsmeared_hadron_node"

mkdir -p ${confspath}/${confsprefix}/corr

for cfg in $confs; do
lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"

[ -f $lime_file ] || continue
for t_source in $t_sources; do

# Find t_origin
perl_prog="
	  srand($cfg);
	
	  # Call a few to clear out junk                                                                                                          
	  foreach \$i (1 .. 20)
	  {
	    rand(1.0);
	  }
	  \$t_origin = int(rand($t_size));
	  \$t_offset = ($t_source + \$t_origin) % $t_size;
	  print \"\$t_offset\";"
t_offset="`perl -e "$perl_prog"`"

momoperatorsZero="NucleonMG1g1MxD0J0S_J1o2_G1g1 NucleonMG1g1MxD2J0S_J1o2_G1g1 NucleonMG1g1MxD2J0M_J1o2_G1g1 NucleonMHg1SxD2J2M_J1o2_G1g1 NucleonMG1g1MxD2J1A_J1o2_G1g1 NucleonMHg1SxD2J1M_J1o2_G1g1 NucleonMG1g1MxD2J1M_J1o2_G1g1"
momoperatorsNonZero="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g1MxD1J1M_J1o2_H1o2D4E1 NucleonMG1g1MxD1J1M_J3o2_H1o2D4E1 NucleonMG1g1MxD2J0M_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1A_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D4E1 NucleonMG1g1MxD2J2M_J3o2_H1o2D4E1 NucleonMG1g1MxD2J2S_J3o2_H1o2D4E1 NucleonMG1g1MxD2J2S_J5o2_H1o2D4E1 NucleonMHg1SxD1J1M_J1o2_H1o2D4E1 NucleonMHg1SxD1J1M_J3o2_H1o2D4E1 NucleonMHg1SxD1J1M_J5o2_H1o2D4E1 NucleonMHg1SxD2J0M_J3o2_H1o2D4E1 NucleonMHg1SxD2J1M_J1o2_H1o2D4E1 NucleonMHg1SxD2J2M_J1o2_H1o2D4E1 NucleonMHg1SxD2J2M_J3o2_H1o2D4E1"

cat << EOF | while read mom operators; do
0  $momoperatorsZero
EOF

prefix="mom$mom"
runpath="$PWD/$tag/$prefix/run_red_${cfg}_${t_source}_${tagfinal}"
mkdir -p $runpath

disco_file="${confspath}/${confsprefix}/disco/${confsname}.disco.sdb${cfg}"
prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n64.light.t0_${t_source}.sdb${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n128.mod${cfg}"
baryon_file="${confspath}/${confsprefix}/baryon_db/${confsname}.n64.absmomz_0_4.baryon.colorvec.t_0_63.sdb${cfg}"
unsmeared_meson_file="${confspath}/${confsprefix}/unsmeared_meson_dbs/t0_${t_source}/tsnk_6/unsmeared_meson.n64.${t_source}.tsnk_6.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp008.qXYZ_0,0,0.sdb${cfg}"
final_db="${confspath}/${confsprefix}/corr/${confsname}.nuc_local.n${nvec}.tsrc_${t_source}.${tag}.${tagfinal}.mom_${mom}.sdb${cfg}"
final_conn_db="${confspath}/${confsprefix}/corr/${confsname}.nuc_local.n${nvec}.tsrc_${t_source}.${tag}.${tagfinal}_conn.mom_${mom}.sdb${cfg}"
if [ ! -f $colorvec_file ]; then echo Not found $colorvec_file; continue; fi
if [ ! -f $prop_file ]; then echo Not found $prop_file; continue; fi
if [ ! -f $baryon_file ]; then echo Not found $baryon_file; continue; fi
if [ ! -f $unsmeared_meson_file ]; then echo Not found $unsmeared_meson_file; continue; fi

mkdir -p ${confspath}/${confsprefix}/corr

cat << EOF > $runpath/noneval_graph_template.xml
<?xml version="1.0"?>
<NonEvalGraph>
<Param>
  <version>1</version>
  <ensemble>$confsname</ensemble>

  <FlavorToMass>
    <elem>
      <flavor>l</flavor>
      <mass>U-0.2350</mass>
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
      <flavor>g</flavor>
      <mass>U0.05</mass>
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
  <noneval_graph_xmls>
    <elem>noneval_graph.xml</elem>
  </noneval_graph_xmls>
  <discoblock_dbs>
    <elem>$disco_file</elem>
  </discoblock_dbs>
  <output_db>graph.sdb</output_db>
</DBFiles>
</NonEvalGraph>
EOF

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
      <mass>U-0.2350</mass>
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
  <output_db>smeared_hadron_node.sdb</output_db>
</DBFiles>
</ColorVecHadron>
EOF

cat << EOF > $runpath/unsmeared_hadron_node_template.xml
<?xml version="1.0"?>
<ColorVecHadron>
<Param>
  <version>6</version>
  <num_vecs>$nvec</num_vecs>
  <use_derivP>false</use_derivP>
  <use_genprop4>false</use_genprop4>

   <FlavorToMass>
     <elem>
       <flavor>l</flavor>
       <mass>U-0.2350</mass>
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
      <flavor>g</flavor>
      <mass>U0.05</mass>
    </elem>
  </FlavorToMass>

</Param>
<DBFiles>
  <hadron_node_xmls>
    <elem>unsmeared_hadron_node.xml</elem>
  </hadron_node_xmls>
  <unsmeared_meson_dbs>
    <elem>$unsmeared_meson_file</elem>
  </unsmeared_meson_dbs>
  <unsmeared_genprop4_dbs>
    <!-- elem>unsmeared_genprop4.sdb</elem -->
  </unsmeared_genprop4_dbs>
  <output_db>unsmeared_hadron_node.sdb</output_db>
</DBFiles>
</ColorVecHadron>
EOF

cat << EOF | while read value file; do
true $final_conn_db
false $final_db
EOF

cat << EOF > $runpath/nuc_3pt_${value}.xml
<?xml version="1.0"?>

<RedstarNPt>
  <Param>
    <version>11</version>
    <Nt_corr>$t_corr</Nt_corr>
    <t_origin>$t_offset</t_origin>
    <bc_spec>1</bc_spec>
    <diagnostic_level>1</diagnostic_level>
    <convertUDtoL>true</convertUDtoL>
    <convertUDtoS>false</convertUDtoS>
    <autoIrrepCG>false</autoIrrepCG>
    <rephaseIrrepCG>false</rephaseIrrepCG>
    <average_1pt_diagrams>true</average_1pt_diagrams>
    <zeroUnsmearedGraphsP>$value</zeroUnsmearedGraphsP>
    <ensemble>$confsname</ensemble>
    <Layout>
      <decayDir>3</decayDir>
      <lattSize>$s_size $s_size $s_size $t_size</lattSize>
    </Layout>
    <NPointList>
      <elem>
        <NPoint>
          <elem>
            <t_slice>6</t_slice>
            <Irrep>
              <creation_op>false</creation_op>
              <smearedP>true</smearedP>
              <flavor>
                <twoI>1</twoI>
                <threeY>3</threeY>
                <twoI_z>1</twoI_z>
              </flavor>
              <irmom>
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>NucleonMG1g1MxD0J0S_J1o2_G1g1</name>
                    <mom_type>0 0 0</mom_type>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
          <elem>
            <t_slice>-3</t_slice>
            <Irrep>
              <creation_op>true</creation_op>
              <smearedP>false</smearedP>
              <flavor>
                <twoI>0</twoI>
                <threeY>0</threeY>
                <twoI_z>0</twoI_z>
              </flavor>
              <irmom>
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>hl_b0xDA__J0_A1pM</name>
                    <mom_type>0 0 0</mom_type>
                    <disp_list>3</disp_list>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
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
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>NucleonMG1g1MxD0J0S_J1o2_G1g1</name>
                    <mom_type>0 0 0</mom_type>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
        </NPoint>
      </elem>
      <elem>
        <NPoint>
          <elem>
            <t_slice>6</t_slice>
            <Irrep>
              <creation_op>false</creation_op>
              <smearedP>true</smearedP>
              <flavor>
                <twoI>1</twoI>
                <threeY>3</threeY>
                <twoI_z>1</twoI_z>
              </flavor>
              <irmom>
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>NucleonMG1g1MxD0J0S_J1o2_G1g1</name>
                    <mom_type>0 0 0</mom_type>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
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
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>b_b0xDA__J0_A1pP</name>
                    <mom_type>0 0 0</mom_type>
                    <disp_list>3</disp_list>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
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
                <row>1</row>
                <mom>0 0 0</mom>
              </irmom>
              <Op>
                <Operators>
                  <elem>
                    <name>NucleonMG1g1MxD0J0S_J1o2_G1g1</name>
                    <mom_type>0 0 0</mom_type>
                  </elem>
                </Operators>
                <CGs>
                </CGs>
              </Op>
            </Irrep>
          </elem>
        </NPoint>
      </elem>
    </NPointList>
  </Param>
  <DBFiles>
    <proj_op_xmls>
    </proj_op_xmls>
    <corr_graph_db>corr_graph_${value}.sdb</corr_graph_db>
    <corr_graph_xml>corr_graph.nuc_3pt_${value}.xml</corr_graph_xml>
    <noneval_graph_xml>noneval_graph.xml</noneval_graph_xml>
    <smeared_hadron_node_xml>smeared_hadron_node.xml</smeared_hadron_node_xml>
    <unsmeared_hadron_node_xml>unsmeared_hadron_node.xml</unsmeared_hadron_node_xml>
    <hadron_npt_graph_db>graph.sdb</hadron_npt_graph_db>
    <hadron_node_dbs>
      <elem>smeared_hadron_node.sdb</elem>
      <elem>unsmeared_hadron_node.sdb</elem>
    </hadron_node_dbs>
    <output_db>$file</output_db>
  </DBFiles>
</RedstarNPt>
EOF
done  # value

cat << EOF > $runpath/run.sh
#!/bin/bash
#SBATCH -o $runpath/run.out
#SBATCH -t 0:10:00
#SBATCH -N 1 -n 1
#SBATCH -A delta
#SBATCH -p normal
#SBATCH -J red-$cfg
`
        echo "#CREATES" $final_db
`

COMPILER_SUITE=/dist/intel/parallel_studio_2019/parallel_studio_xe_2019
source  \${COMPILER_SUITE}/psxevars.sh intel64

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=4

echo
echo "RUNINIG" $redstar_gen_graph nuc_3pt_true.xml out.xml
echo
rm -f smeared_hadron_node.sdb unsmeared_hadron_node.sdb graph.sdb $final_db noneval_graph.xml smeared_hadron_node.xml unsmeared_hadron_node.xml graph.sdb corr_graph*.sdb
$redstar_gen_graph nuc_3pt_true.xml out.xml

echo
echo "RUNINIG" $hadron_node smeared_hadron_node_template.xml out.xml
echo
rm -f smeared_hadron_node.sdb
$hadron_node smeared_hadron_node_template.xml out.xml

echo
echo "RUNINIG" $unsmeared_hadron_node unsmeared_hadron_node_template.xml unsmeared_hadron_node.out
echo
rm -f unsmeared_hadron_node.sdb
$unsmeared_hadron_node unsmeared_hadron_node_template.xml unsmeared_hadron_node.out

echo
echo "RUNINIG" $redstar_npt nuc_3pt_true.xml out.xml
echo
rm -f $final_conn_db
$redstar_npt nuc_3pt_true.xml out.xml

echo
echo "RUNNING " $noneval_graph noneval_graph_template.xml out.xml
echo
$noneval_graph noneval_graph_template.xml out.xml

echo
echo "RUNINIG" $redstar_gen_graph nuc_3pt_false.xml out.xml
echo
##rm -f smeared_hadron_node.sdb unsmeared_hadron_node.sdb $final_db
$redstar_gen_graph nuc_3pt_false.xml out.xml

echo
echo "RUNINIG" $redstar_npt nuc_3pt_false.xml out.xml
echo
rm -f $final_db
$redstar_npt nuc_3pt_false.xml out.xml

rm -f smeared_hadron_node.sdb unsmeared_hadron_node.sdb
EOF

done # mom
done # t_source
done # cfg

