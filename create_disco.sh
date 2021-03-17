#!/bin/bash

confs="`seq 1000 10 5160`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size

confspath="/cache/isoClover"
chroma="/home/eromero/qcd_software/jlab/knl/install/chroma2-double/bin/chroma"
probing_file="/work/JLabLQCD/eromero/run_disco/d32_32_32_64k0_0_5_0p8c256.txt"


mkdir -p ${confspath}/${confsprefix}/disco

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
disco_file="${confspath}/${confsprefix}/disco/${confsname}.disco.sdb${cfg}"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_disco_$cfg"
mkdir -p $runpath

#
# Disco creation
#

cat << EOF > $runpath/disco.xml
<?xml version="1.0"?>
<chroma>
<Param>
  <InlineMeasurements>
    <elem>
      <Name>DISCO_PROBING_DEFLATION</Name>
      <Param>
        <max_path_length>8</max_path_length>
        <p2_max>0</p2_max>
        <mass_label>U-0.2350</mass_label>
        <probing_distance>1</probing_distance>
	<probing_file>$probing_file</probing_file>
        <noise_vectors>1</noise_vectors>
	<max_rhs>4</max_rhs>
        <Propagator>
          <version>10</version>
          <quarkSpinType>FULL</quarkSpinType>
          <obsvP>false</obsvP>
          <numRetries>1</numRetries>
          <FermionAction>
            <FermAct>CLOVER</FermAct>
            <Mass>-0.2350</Mass>
            <clovCoeff>1.20536588031793</clovCoeff>
            <FermState>
              <Name>STOUT_FERM_STATE</Name>
              <rho>0.125</rho>
              <n_smear>1</n_smear>
              <orthog_dir>-1</orthog_dir>
              <FermionBC>
                <FermBC>SIMPLE_FERMBC</FermBC>
                <boundary>1 1 1 -1</boundary>
              </FermionBC>
            </FermState>
          </FermionAction>
            <InvertParam>
              <invType>MG_PROTO_QPHIX_EO_CLOVER_INVERTER</invType>
              <CloverParams>
                <Mass>-0.2350</Mass>
                <clovCoeff>1.20536588031793</clovCoeff>
              </CloverParams>
              <AntiPeriodicT>true</AntiPeriodicT>
              <MGLevels>3</MGLevels>
              <Blocking>
                <elem>4 4 4 4</elem>
                <elem>2 2 2 2</elem>
              </Blocking>
              <NullVecs>24 32</NullVecs>
              <NullSolverMaxIters>100 100</NullSolverMaxIters>
              <NullSolverRsdTarget>5e-8 5e-8</NullSolverRsdTarget>
              <NullSolverVerboseP>0 0</NullSolverVerboseP>
              <OuterSolverNKrylov>10</OuterSolverNKrylov>
              <OuterSolverRsdTarget>1.0e-7</OuterSolverRsdTarget>
              <OuterSolverMaxIters>300</OuterSolverMaxIters>
              <OuterSolverVerboseP>true</OuterSolverVerboseP>
              <VCyclePreSmootherMaxIters>0 0</VCyclePreSmootherMaxIters>
              <VCyclePreSmootherRsdTarget>0.1 0.1</VCyclePreSmootherRsdTarget>
              <VCyclePreSmootherRelaxOmega>1.1 1.1</VCyclePreSmootherRelaxOmega>
              <VCyclePreSmootherVerboseP>0 0</VCyclePreSmootherVerboseP>
              <VCyclePostSmootherMaxIters>8 13</VCyclePostSmootherMaxIters>
              <VCyclePostSmootherRsdTarget>0.06 0.06</VCyclePostSmootherRsdTarget>
              <VCyclePostSmootherRelaxOmega>1.1 1.1</VCyclePostSmootherRelaxOmega>
              <VCyclePostSmootherVerboseP>0 0</VCyclePostSmootherVerboseP>
              <VCycleBottomSolverMaxIters>100 100</VCycleBottomSolverMaxIters>
              <VCycleBottomSolverRsdTarget>0.06 0.06</VCycleBottomSolverRsdTarget>
              <VCycleBottomSolverNKrylov>8 8</VCycleBottomSolverNKrylov>
              <VCycleBottomSolverVerboseP>0 0</VCycleBottomSolverVerboseP>
              <VCycleMaxIters>1 1</VCycleMaxIters>
              <VCycleRsdTarget>0.1 0.1</VCycleRsdTarget>
              <VCycleVerboseP>0 0</VCycleVerboseP>
              <SubspaceId>foo_eo</SubspaceId>
            </InvertParam>
        </Propagator>
        <Projector>
              <projectorType>MG_PROTO_QPHIX_CLOVER_PROJECTOR</projectorType>
              <CloverParams>
                <Mass>-0.2350</Mass>
                <clovCoeff>1.20536588031793</clovCoeff>
                <AnisoParam>
                  <anisoP>false</anisoP>
                  <t_dir>3</t_dir>
                  <xi_0>1</xi_0>
                  <nu>1</nu>
                </AnisoParam>
              </CloverParams>
              <AntiPeriodicT>true</AntiPeriodicT>
              <MGLevels>3</MGLevels>
              <Blocking>
                <elem>4 4 4 4</elem>
                <elem>2 2 2 2</elem>
              </Blocking>
              <NullVecs>24 32</NullVecs>
              <NullSolverMaxIters>800 800</NullSolverMaxIters>
              <NullSolverRsdTarget>-0.006 -0.0006</NullSolverRsdTarget>
              <NullSolverVerboseP>0 0</NullSolverVerboseP>
              <EigenSolverBlockSize>1</EigenSolverBlockSize>
              <EigenSolverMaxRestartSize>32</EigenSolverMaxRestartSize>
              <EigenSolverMaxRank>800</EigenSolverMaxRank>
              <EigenSolverRsdTarget>1.0e-3</EigenSolverRsdTarget>
              <EigenSolverMaxIters>0</EigenSolverMaxIters>
              <EigenSolverVerboseP>true</EigenSolverVerboseP>
              <BottomSolverNKrylov>40</BottomSolverNKrylov>
              <BottomSolverRsdTarget>1.0e-4</BottomSolverRsdTarget>
              <BottomSolverMaxIters>10000</BottomSolverMaxIters>
              <BottomSolverVerboseP>false</BottomSolverVerboseP>
              <SubspaceId>foo_eo_caca</SubspaceId>
        </Projector>
        <use_ferm_state_link>true</use_ferm_state_link>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <sdb_file>$disco_file</sdb_file>
      </NamedObject>
    </elem>
  </InlineMeasurements>
  <nrow>$s_size $s_size $s_size $t_size</nrow>
</Param>

<RNG>
  <Seed>
    <elem>11</elem>
    <elem>11</elem>
    <elem>11</elem>
    <elem>0</elem>
  </Seed>
</RNG>

  <Cfg>
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>
</chroma>
EOF

cat << EOF > $runpath/disco_create.sh
#!/bin/bash
#SBATCH -o $runpath/disco_create.out.0
#SBATCH -t 10:30:00
#SBATCH --nodes=4
#SBATCH -J disco-${cfg}
#SBATCH -A delta
#SBATCH -p phi
#SBATCH -C cache,quad,18p


COMPILER_SUITE=/dist/intel/parallel_studio_2019/parallel_studio_xe_2019
source  \${COMPILER_SUITE}/psxevars.sh intel64


cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=64
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

rm -f $disco_file

export nodefile="\`mktemp\`"
scontrol show hostnames \$SLURM_JOB_NODELIST > \$nodefile

mpirun -rsh rsh -genvall -np 16 -hostfile \$nodefile -ppn 4 $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 64 -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/disco.xml  -geom 2 2 2 2 &> $runpath/disco_create.out
EOF

done # cfg
