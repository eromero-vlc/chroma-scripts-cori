#!/bin/bash

# confs="`seq 2430 10 5410`"
# confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050"
# confsname="cl21_48_96_b6p3_m0p2416_m0p2050"
# tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams"

confs="`seq 1250 10 3560`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-1000"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-1000"

confs="`seq 1340 10 3790`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-1200"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-1200"

confs="`seq 280 10 2810`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-djm-1"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-djm-1"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-djm-1"

confs="`seq 1000 10 2180`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-djm-2"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-djm-2"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-djm-2"

confs="`seq 1000 10 3330`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-djm-3"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-djm-3"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-djm-3"

confs="`seq 1000 10 2420`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-rightColorvecs/cl21_48_96_b6p3_m0p2416_m0p2050-djm-4"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-djm-4"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams-djm-4"


s_size=48 # lattice spatial size
t_size=96 # lattice temporal size
nvec=128  # number of eigenvectors

confspath="/scratch3/projects/phy20014/isoClover/b6p3"
chromaform="/work2/06873/eloy/frontera/chromaform1"
chroma="${chromaform}/install-gnu/chroma-mgproto-qphix-avx512/bin/chroma"

mkdir -p ${confspath}/${confsprefix}/cfgs_mod
mkdir -p ${confspath}/${confsprefix}/eigs_mod

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${nvec}.mod${cfg}"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_eigs_$cfg"
mkdir -p $runpath


#
# Basis creation
#

cat << EOF > $runpath/eigs_creation.xml
<?xml version="1.0"?>
<chroma>
 <Param>
  <InlineMeasurements>
    <elem>
      <Name>CREATE_COLORVECS_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <num_vecs>$nvec</num_vecs>
        <decay_dir>3</decay_dir>
        <write_fingerprint>true</write_fingerprint>
        <LinkSmearing>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>0.08</link_smear_fact>
          <link_smear_num>10</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </LinkSmearing>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <colorvec_out>${colorvec_file}</colorvec_out>
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
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>
</chroma>
EOF

cat << EOF > $runpath/run.bash
#!/bin/bash
#SBATCH -o $runpath/eig_create_run.out
#SBATCH -t 8:00:00
#SBATCH --nodes=1 --ntasks-per-node=32
#SBATCH -A PHY20014
#SBATCH -p normal
#SBATCH -J eigs-$cfg

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$chromaform/install/primme-cpu/lib"

rm -f  ${colorvec_file}
echo RUNNING chroma
ibrun -n 32 \$MY_OFFSET $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 1 -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/eigs_creation.xml -geom 2 4 4 1
echo FINISHED
EOF

done # cfg
