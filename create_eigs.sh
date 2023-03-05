#!/bin/bash

confs="`seq 11500 10 13620`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050_extension/backups/cl21_32_64_b6p3_m0p2350_m0p2050-11200"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050-11200"
tag="cl21_32_64_b6p3_m0p2350_m0p2050_extension-backups-11200"

confs="`seq 12200 10 16640`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050_extension/backups/cl21_32_64_b6p3_m0p2350_m0p2050-11900"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050-11900"
tag="cl21_32_64_b6p3_m0p2350_m0p2050_extension-backups-11900"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
nvec=96  # number of eigenvectors

confspath="/mnt/tier2/project/p200054/cache/b6p3"
chromaform="/mnt/tier2/project/p200054/chromaform"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-superbblas-cuda/bin/chroma"

mkdir -p ${confspath}/${confsprefix}/eig

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
# Sample: eig/cl21_32_64_b6p3_m0p2350_m0p2050-14200_eigen_z0_light.15560.eig
colorvec_file="${confspath}/${confsprefix}/eig/${confsname}_eigen_z0_light.${cfg}.eig"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_eigs_$cfg"
mkdir -p $runpath


#
# Basis creation
#

cat << EOF > $runpath/eig_creation.xml
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
        <write_fingerprint>false</write_fingerprint>
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

cat << EOF > $runpath/run.sh
#!/bin/bash -l
#SBATCH -o $runpath/eig_create_run.out0
#SBATCH --account=p200054
#SBATCH -t 10:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q short
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J eig-${cfg}

. $chromaform/env.sh

cd $runpath
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=12
export CUDA_VISIBLE_DEVICES="0,1,2,3"
export GPU_DEVICE_ORDINAL="0,1,2,3"
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$chromaform/install/llvm/lib

rm -f $colorvec_file

srun \$MY_ARGS -n 4 -N 1 $chroma -i $runpath/eig_creation.xml -geom 1 1 2 2 -pool-max-alloc 0 -pool-max-alignment 512 -libdevice-path /apps/USE/easybuild/release/2021.3/software/CUDA/11.4.2/nvvm/libdevice &> $runpath/eig_create_run.out
EOF

done # cfg
