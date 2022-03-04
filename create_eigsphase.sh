#!/bin/bash

confs="`seq 4510 10 10000`"
confs="`seq 4510 10 7000`"




confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
nvec=128  # number of eigenvectors
zphase="2.00"  # colorvec phase

confspath="/global/project/projectdirs/hadron/b6p3"
harom="/global/project/projectdirs/hadron/qcd_software/nersc/cori/parscalar/install/harom-phase/bin/harom"


mkdir -p ${confspath}/${confsprefix}/eigs_mod

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.n${nvec}.mod${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${nvec}.mod${cfg}"
colorvec_file_out="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.phased_${zphase}.eigs.n${nvec}.mod${cfg}"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_eigsphase_$cfg"
mkdir -p $runpath

#
# Basis transformation
#

cat << EOF > $runpath/eigs_phase_creation.xml
<harom>
  <Param>
    <InlineMeasurements>
      <elem>
        <Name>PHASE_COLORVEC</Name>
        <Frequency>1</Frequency>
        <Param>
          <version>1</version>
          <num_vecs>${nvec}</num_vecs>
          <decay_dir>3</decay_dir>
          <Zeta>0.00 0.00 ${zphase}</Zeta>
          <phaseEigType>Phase</phaseEigType>
        </Param>
        <NamedObject>
          <gauge_id>default_gauge_field</gauge_id>
          <colorvec_files>
            <elem>${colorvec_file}</elem>
          </colorvec_files>
          <colorvec_out>${colorvec_file_out}</colorvec_out>
          <ColorVecMapObject>
            <MapObjType>MAP_OBJECT_MEMORY</MapObjType>
          </ColorVecMapObject>
        </NamedObject>
      </elem>
    </InlineMeasurements>
    <nrow>$s_size $s_size $s_size $t_size</nrow>
  </Param>
</harom>
EOF

cat << EOFout > $runpath/run.bash
#!/bin/bash
#SBATCH -o $runpath/eig_phase_create_run.out
#SBATCH -t 0:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --constraint=haswell
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH -J eigs-phase-$cfg

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

srun -N1 -n1 \$MY_OFFSET rm -f $colorvec_file_out
srun -N1 -n4 \$MY_OFFSET $harom -i $runpath/eigs_phase_creation.xml -o $runpath/eigs_phase_run.out &> $runpath/run.out
echo FINISHED
EOFout

done # cfg
