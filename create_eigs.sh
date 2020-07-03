#!/bin/bash

confs="`seq 4510 10 10000`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
nvec=128  # number of eigenvectors

confspath="/global/project/projectdirs/hadron/b6p3"
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

localrunpath="$SCRATCH/tmp/run_${tag}_${cfg}"
stout_file="${localrunpath}/${confsname}.3d.stdout.n${nvec}.mod${cfg}"
#local_gauge_file="${localrunpath}/${confsname}.3d.gauge.n${nvec}.mod${cfg}"
#local_colorvec_file="${localrunpath}/${confsname}.3d.eigs.n${nvec}.mod${cfg}"

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
          <link_smear_fact>0.08</link_smear_fact>
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
          <output_file>$gauge_file</output_file>
        </NamedObject>
      </elem>
      <!-- elem>
        <Name>WRITE_TIMESLICE_MAP_OBJECT_DISK</Name>
        <NamedObject>
          <object_type>ArrayLatticeColorMatrix</object_type>
          <input_id>stout_gauge_field</input_id>
          <output_file>$stout_file</output_file>
        </NamedObject>
      </elem -->
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
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --constraint=haswell
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH -J eigs-$cfg

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
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=true

#srun -n 1 \$MY_OFFSET ln -s \$DW_JOB_STRIPED $localrunpath
srun -n 1 \$MY_OFFSET  mkdir -p $localrunpath
srun -n 1 \$MY_OFFSET rm -rf $localrunpath/*

srun -n 1 \$MY_OFFSET rm -f $gauge_file ${stout_file}* ${colorvec_file}
echo RUNNING chroma
srun -n 32 \$MY_OFFSET $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 1 -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/stdout_creation.xml -geom 2 2 2 4

for t_slice in \`seq 0 $((t_size - 1))\` ; do

cat << EOF > $runpath/laplace_eigs.xml
<?xml version="1.0"?>
<LaplaceEigs>
  <Param>
    <version>2</version>
    <Layout>$s_size $s_size $s_size</Layout>
    <LinearOperator>Laplacian</LinearOperator>
    <t_slice>\$t_slice</t_slice>
    <gauge_file>$gauge_file</gauge_file>
    <vec_file>${stout_file}_t_\${t_slice}</vec_file>
  </Param>
  <EigenInfo>
    <Nev>$nvec</Nev>
    <PrintLevel>3</PrintLevel>
    <LambdaC>0.3</LambdaC>
    <LambdaMax>15</LambdaMax>
    <NCheb>-1</NCheb>
    <Tol>1e-05</Tol>
  </EigenInfo>
</LaplaceEigs>
EOF
echo RUNNING laplace_eigs for slice \$t_slice
srun -n 32 \$MY_OFFSET $laplace_eigs $runpath/laplace_eigs.xml $runpath/out_t_\$t_slice
done #t_slice

cat << EOF > $runpath/vecs_combine_3d.xml
<VecsCombine>
  <version>1</version>
  <Layout>$s_size $s_size $s_size $t_size</Layout>
  <InputFiles>
  `for i in $( seq 0 $((t_size -1 )) ); do echo "<elem>${stout_file}_t_${i}</elem>" ; done`
  </InputFiles>
  <OutFile>$colorvec_file</OutFile>
</VecsCombine>
EOF
echo RUNNING vecs_combine_3d
srun -n 1 \$MY_OFFSET $vecs_combine_3d $runpath/vecs_combine_3d.xml vecs_combine.out
srun -n 1 \$MY_OFFSET rm -f ${stout_file}*
echo FINISHED
EOFout

done # cfg
