#!/bin/bash

confs="`seq 4510 10 10000`"
confs="`seq 4510 10 7000`"
confs=540
confsprefix="cl21_72_192_b6p5_m0p2091_m0p1778"
confsname="cl21_72_192_b6p5_m0p2091_m0p1778"
tag="cl21_72_192_b6p5_m0p2091_m0p1778"

s_size=72 # lattice spatial size
t_size=192 # lattice temporal size
nvec=128  # number of eigenvectors

confspath="/global/project/projectdirs/hadron/b6p5"
chroma="/global/project/projectdirs/hadron/qcd_software/nersc/cori/parscalar/install/chroma/bin/chroma"
laplace_eigs="/global/project/projectdirs/hadron/qcd_software/nersc/cori/parscalar/install/laplace_eigs/laplace_eigs"
vecs_combine_3d="/global/project/projectdirs/hadron/qcd_software/nersc/cori/parscalar/install/laplace_eigs/vecs_combine_3d"


mkdir -p ${confspath}/${confsprefix}/stout_mod
mkdir -p ${confspath}/${confsprefix}/cfgs_mod
mkdir -p ${confspath}/${confsprefix}/eigs_mod

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.n${nvec}.mod${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${nvec}.mod${cfg}"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_eigs_$cfg"
mkdir -p $runpath

mkdir -p $SCRATCH/tmp
localrunpath="$SCRATCH/tmp/run_${tag}_${cfg}"
stout_file="${localrunpath}/${confsname}.3d.stdout.n${nvec}.mod${cfg}"
local_gauge_file="${localrunpath}/${confsname}.3d.gauge.n${nvec}.mod${cfg}"
local_colorvec_file="${localrunpath}/${confsname}.3d.eigs.n${nvec}.mod${cfg}"

#
# Basis creation
#

cat << EOF > $runpath/stdout_creation.xml
<?xml version="1.0"?>
<chroma>
  <Param>
    <InlineMeasurements>
      <elem>
        <Name>LINK_SMEAR</Name>
        <Frequency>1</Frequency>
        <Param>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>0.1</link_smear_fact>
          <link_smear_num>10</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </Param>
        <NamedObject>
          <gauge_id>default_gauge_field</gauge_id>
          <linksmear_id>stout_gauge_field</linksmear_id>
        </NamedObject>
      </elem>
      <elem>
        <Name>WRITE_TIMESLICE_MAP_OBJECT_DISK</Name>
        <NamedObject>
          <object_type>ArrayLatticeColorMatrix</object_type>
          <input_id>default_gauge_field</input_id>
          <output_file>$local_gauge_file</output_file>
        </NamedObject>
      </elem>
      <elem>
        <Name>WRITE_TIMESLICE_MAP_OBJECT_DISK</Name>
        <NamedObject>
          <object_type>ArrayLatticeColorMatrix</object_type>
          <input_id>stout_gauge_field</input_id>
          <output_file>$stout_file</output_file>
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

cat << EOFout > $runpath/run.bash
#!/bin/bash
#SBATCH -o $runpath/eig_create_run.out
#SBATCH -t 0:40:00
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=32
#SBATCH --constraint=haswell
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH -J eigs-$cfg
#DW jobdw capacity=8GB access_mode=striped type=scratch

. /opt/modules/default/init/bash
module unload PrgEnv-cray
module unload PrgEnv-intel
module unload PrgEnv-pgi
module unload PrgEnv-gnu
module unload darshan
module load PrgEnv-intel
module load craype-haswell
module load python3

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=64
export OMP_PLACES=threads
export OMP_PROC_BIND=true

srun -N1 -n1 \$MY_OFFSET rm -rf $localrunpath
srun -N1 -n1 \$MY_OFFSET ln -s \$DW_JOB_STRIPED $localrunpath
#srun -N1 -n1 \$MY_OFFSET  mkdir -p $localrunpath

srun -N1 -n1 \$MY_OFFSET rm -f $gauge_file ${stout_file}* ${colorvec_file}
echo RUNNING chroma
srun -N16 -n$((32*16)) \$MY_OFFSET $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 1 -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/stdout_creation.xml -geom 4 4 4 8
srun -N1 -n1 \$MY_OFFSET cp $local_gauge_file $gauge_file &

for t_slice in \`seq 0 $((10 - 1))\` ; do

cat << EOF > $runpath/laplace_eigs.xml
<?xml version="1.0"?>
<LaplaceEigs>
  <Param>
    <version>2</version>
    <Layout>$s_size $s_size $s_size</Layout>
    <LinearOperator>Laplacian</LinearOperator>
    <t_slice>\$t_slice</t_slice>
    <gauge_file>$stout_file</gauge_file>
    <vec_file>${stout_file}_t_\${t_slice}</vec_file>
  </Param>
  <EigenInfo>
    <Nev>$nvec</Nev>
    <PrintLevel>3</PrintLevel>
    <LambdaC>0.5</LambdaC>
    <LambdaMax>15</LambdaMax>
    <NCheb>8</NCheb>
    <Tol>1e-06</Tol>
  </EigenInfo>
</LaplaceEigs>
EOF
echo RUNNING laplace_eigs for slice \$t_slice
srun -N16 -n$((32*16)) \$MY_OFFSET $laplace_eigs $runpath/laplace_eigs.xml $runpath/out_t_\$t_slice
done #t_slice

cat << EOF > $runpath/vecs_combine_3d.xml
<VecsCombine>
  <version>1</version>
  <Layout>$s_size $s_size $s_size $t_size</Layout>
  <InputFiles>
  `for i in $( seq 0 $((10 -1 )) ); do echo "<elem>${stout_file}_t_${i}</elem>" ; done`
  </InputFiles>
  <OutFile>$local_colorvec_file</OutFile>
</VecsCombine>
EOF
echo RUNNING vecs_combine_3d
srun -N1 -n1 \$MY_OFFSET $vecs_combine_3d $runpath/vecs_combine_3d.xml vecs_combine.out
srun -N1 -n1 \$MY_OFFSET cp $local_colorvec_file $colorvec_file
srun -N1 -n1 \$MY_OFFSET rm -f ${stout_file}*
wait
echo FINISHED
EOFout

done # cfg
