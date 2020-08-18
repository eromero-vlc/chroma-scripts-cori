#!/bin/bash

confs="`seq 4510 10 10000`"
confs="7800 1000"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
max_nvec=128 # number of eigenvector computed
nvec=64 # rank basis for baryon elementals
tagcnf="n$max_nvec"

confspath="/global/project/projectdirs/hadron/b6p3"
harom="/global/project/projectdirs/hadron/qcd_software/nersc/cori-knl/parscalar/install/harom/bin/harom"

mkdir -p ${confspath}/${confsprefix}/baryon_db

for cfg in $confs; do

runpath="$PWD/${tag}/run_bar_$cfg"
mkdir -p $runpath

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
[ -f $lime_file ] || continue
gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.${tagcnf}.mod${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.mod${cfg}"

#colorvec_file_dep="`cat ${runpath}/../run_eigs_${cfg}/run.bash.launched | tr -d '[:blank:]'`"
#if [ -z $colorvec_file_dep ] ; then echo Not found $colorvec_file; continue; fi

baryon_file="${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).${tag}.sdb${cfg}"

#
# Baryon creation
#

cat << EOF > $runpath/harom_creation.xml
<?xml version="1.0"?>

<harom>
<Param>
  <InlineMeasurements>

    <elem>
      <Name>BARYON_MATELEM_COLORVEC_OPT</Name>
      <Frequency>1</Frequency>
      <Param>
        <version>3</version>
        <use_derivP>true</use_derivP>
        <start_t>0</start_t>
        <end_t>7</end_t>
    <mom2_min>0</mom2_min>
    <mom2_max>9</mom2_max>
        <!-- mom_list>
                <elem>0 0 0</elem>
                <elem>1 0 0</elem>
                <elem>-1 0 0</elem>
                <elem>0 1 0</elem>
                <elem>0 -1 0</elem>
                <elem>0 0 1</elem>
                <elem>0 0 -1</elem>
                <elem>2 0 0</elem>
                <elem>-2 0 0</elem>
                <elem>0 2 0</elem>
                <elem>0 -2 0</elem>
                <elem>0 0 2</elem>
                <elem>0 0 -2</elem>
                <elem>3 0 0</elem>
                <elem>-3 0 0</elem>
                <elem>0 3 0</elem>
                <elem>0 -3 0</elem>
                <elem>0 0 3</elem>
                <elem>0 0 -3</elem>
        </mom_list -->
        <mom_list>
            <elem>0 0 0</elem>
<!--                    <elem>0 0 1</elem>
                <elem>0 0 -1</elem>
                <elem>0 0 2</elem>
                <elem>0 0 -2</elem>    
               <elem>0 0 3</elem>
                <elem>0 0 -3</elem>	-->

        </mom_list>
        <num_vecs>${nvec}</num_vecs>
        <displacement_length>1</displacement_length>
        <decay_dir>3</decay_dir>

        <!-- List of displacement arrays -->
        <displacement_list>
          <elem><left>0</left><middle>0</middle><right>0</right></elem>
          <elem><left>0</left><middle>0</middle><right>1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2</right></elem>
          <elem><left>0</left><middle>0</middle><right>3</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 2</right></elem>
          <elem><left>0</left><middle>1</middle><right>1</right></elem>
          <elem><left>0</left><middle>1</middle><right>2</right></elem>
          <elem><left>0</left><middle>1</middle><right>3</right></elem>
          <elem><left>0</left><middle>2</middle><right>2</right></elem>
          <elem><left>0</left><middle>2</middle><right>3</right></elem>
          <elem><left>0</left><middle>3</middle><right>3</right></elem>
        </displacement_list>

        <LinkSmearing>
          <LinkSmearingType>STOUT_SMEAR</LinkSmearingType>
          <link_smear_fact>0.1</link_smear_fact>
          <link_smear_num>10</link_smear_num>
          <no_smear_dir>3</no_smear_dir>
        </LinkSmearing>

      </Param>
      <NamedObject>
        <gauge_file>$gauge_file</gauge_file>
        <colorvec_files><elem>$colorvec_file</elem></colorvec_files>
        <colorvec_file_out>$colorvec_file_sp</colorvec_file_out>
        <baryon_op_file>$baryon_file</baryon_op_file>
      </NamedObject>
    </elem>


  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
</Param>
</harom>
EOF

cat << EOF > $runpath/harom_create_run.sh
#!/usr/bin/env bash
#SBATCH -o $runpath/harom_create_run.out0
#SBATCH -t 0:40:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --constraint=knl
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH -J bar-$cfg
#DEPENDENCY $colorvec_file_dep

#Load environment
module unload PrgEnv-cray
module unload PrgEnv-intel
module unload PrgEnv-pgi
module unload PrgEnv-gnu
module unload craype-haswell
module load PrgEnv-intel
module load craype-mic-knl

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=64
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

rm -f $baryon_file
srun -N1 -n4 -c68 \$MY_OFFSET --cpu_bind=cores $harom -i $runpath/harom_creation.xml -o $runpath/harom_creation.out &> $runpath/harom_create_run.out
EOF

done # cfg
