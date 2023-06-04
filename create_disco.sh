#!/bin/bash

confs="`seq 1000 10 4000`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size

disco_samples=10

confspath="/gpfsdswork/projects/rech/cib/uie52up/cache/b6p3"
chromaform="\$HOME/work_qjs/chromaform"
chroma="$chromaform/install/chroma-mgproto-qphix-avx512/bin/chroma"
chromaform="\$HOME/work_cib/chromaform-cpu-next"
chroma="$chromaform/install/chroma-sp-mgproto-qphix-qdpxx-double-nd4-avx512-superbblas-cpu-next/bin/chroma"

mkdir -p ${confspath}/${confsprefix}/disco

for cfg in $confs; do

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"

echo $lime_file
[ -f $lime_file ] || continue

runpath="$PWD/${tag}/run_disco_$cfg"
mkdir -p $runpath

#
# Disco creation
#

for s in `seq $disco_samples`; do

disco_file="${confspath}/${confsprefix}/disco/${confsname}.disco.sdb${cfg}_part_${s}"

cat << EOF > $runpath/disco_${s}.xml
<?xml version="1.0"?>
<chroma>
<Param>
  <InlineMeasurements>
    <elem>
      <Name>DISCO_PROBING_DEFLATION_SUPERB</Name>
      <Param>
        <max_path_length>8</max_path_length>
       <mom_list>
                <elem>0 0 0</elem>
                <elem>0 0 1</elem>
                <elem>0 0 -1</elem>
                <elem>0 0 2</elem>
                <elem>0 0 -2</elem>
                <elem>0 0 3</elem>
                <elem>0 0 -3</elem>
        </mom_list>
        <mass_label>U-0.2350</mass_label>
        <probing_distance>6</probing_distance>
        <probing_power>10</probing_power>
        <noise_vectors>1</noise_vectors>
	<max_rhs>1</max_rhs>
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
              <NullSolverRsdTarget>-0.002 -0.001</NullSolverRsdTarget>
              <NullSolverVerboseP>0 0</NullSolverVerboseP>
              <EigenSolverBlockSize>1</EigenSolverBlockSize>
              <EigenSolverMaxRestartSize>32</EigenSolverMaxRestartSize>
              <EigenSolverMaxRank>3200</EigenSolverMaxRank>
              <EigenSolverRsdTarget>1.0e-3</EigenSolverRsdTarget>
              <EigenSolverMaxIters>0</EigenSolverMaxIters>
              <EigenSolverVerboseP>true</EigenSolverVerboseP>
              <BottomSolverNKrylov>40</BottomSolverNKrylov>
              <BottomSolverRsdTarget>3.0e-5</BottomSolverRsdTarget>
              <BottomSolverMaxIters>20000</BottomSolverMaxIters>
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
    <elem>$cfg</elem>
    <elem>11</elem>
    <elem>11</elem>
    <elem>$s</elem>
  </Seed>
</RNG>

  <Cfg>
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>
</chroma>
EOF

cat << EOF > $runpath/disco_create_$s.sh
#!/bin/bash
#SBATCH -o $runpath/disco_create_${s}.out.0
#SBATCH -t 20:00:00
#SBATCH -J disco-${cfg}
#SBATCH --account=qjs@cpu
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=10


. $chromaform/env.sh

cd $runpath
#export MKL_NUM_THREADS=10
export OMP_NUM_THREADS=10
export OPENBLAS_NUM_THREADS=1
#export OMP_PLACES=threads
#export OMP_PROC_BIND=true
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$chromaform/install/primme/lib

rm -f $disco_file

srun \$MY_OFFSET $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c \$OMP_NUM_THREADS -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/disco_${s}.xml -geom 2 2 4 4 &> $runpath/disco_create_${s}.out
EOF

done # s
done # cfg
