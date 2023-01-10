#!/bin/bash

confs="`seq 10000 10 20070`"
confs="`seq 15500 10 20070`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
t_sources="`seq 0 63`"
zphase="-2.00"

t_fwd=64
t_back=0
s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
max_nvec=128 # number of eigenvector computed
nvec=96 # Number of eigenvectors used to compute perambulators
tagcnf="n$max_nvec"
confspath="/mnt/tier2/project/p200054/cache/b6p3"
chromaform="/mnt/tier2/project/p200054/chromaform"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-superbblas-cuda/bin/chroma"

mkdir -p ${confspath}/${confsprefix}/prop_db

for cfg in $confs; do

runpath="$PWD/${tag}/run_prop_${zphase}-$cfg"
mkdir -p $runpath

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

lime_file="`ls ${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime*`"
lime_file_noref="${lime_file%.ref????}"
ref="${lime_file#${lime_file_noref}}"
[ -f $lime_file ] || continue
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${max_nvec}.mod${cfg}${ref}"
[ -f $colorvec_file ] || continue

if [ "X${zphase}X" != X0.00X ]; then
# Example: phased/prop_db/d001_2.00/11010/11010/cl21_32_64_b6p3_m0p2350_m0p2050.phased_2.00.prop.n96.light.t0_1.sdb11010
prop_file="${confspath}/${confsprefix}/phased/prop_db/d001_${zphase}/${cfg}/${cfg}/${confsname}.phased_${zphase}.prop.n${nvec}.light.t0_${t_source}.sdb${cfg}${ref}"
else
prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${nvec}.light.t0_${t_source}.sdb${cfg}${ref}"
fi
mkdir -p `dirname ${prop_file}`

#
# Propagators creation
#

cat << EOF > $runpath/prop_creation_${t_source}.xml
<?xml version="1.0"?>

<chroma>
<Param>
  <InlineMeasurements>

    <elem>
      <Name>PROP_AND_MATELEM_DISTILLATION_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <Contractions>
          <mass_label>U-0.2350</mass_label>
          <num_vecs>$nvec</num_vecs>
          <t_sources>$t_offset</t_sources>
          <Nt_forward>$t_fwd</Nt_forward>
          <Nt_backward>$t_back</Nt_backward>
          <decay_dir>3</decay_dir>
          <num_tries>-1</num_tries>
          <max_rhs>1</max_rhs>
          <phase>0.00 0.00 $zphase</phase>
        </Contractions>
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
              <invType>QUDA_MULTIGRID_CLOVER_INVERTER</invType>
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
              <RsdTarget>1e-07</RsdTarget>
              <Delta>0.1</Delta>
              <Pipeline>4</Pipeline>
              <MaxIter>500</MaxIter>
              <RsdToleranceFactor>8.0</RsdToleranceFactor>
              <AntiPeriodicT>true</AntiPeriodicT>
              <SolverType>GCR</SolverType>
              <Verbose>true</Verbose>
              <AsymmetricLinop>true</AsymmetricLinop>
              <CudaReconstruct>RECONS_12</CudaReconstruct>
              <CudaSloppyPrecision>SINGLE</CudaSloppyPrecision>
              <CudaSloppyReconstruct>RECONS_8</CudaSloppyReconstruct>
              <AxialGaugeFix>false</AxialGaugeFix>
              <AutotuneDslash>true</AutotuneDslash>
              <MULTIGRIDParams>
                <Verbosity>true</Verbosity>
                <Precision>HALF</Precision>
                <Reconstruct>RECONS_8</Reconstruct>
                <Blocking>
                  <elem>4 4 4 4</elem>
                  <elem>2 2 2 2</elem>
                </Blocking>
                <CoarseSolverType>
                  <elem>GCR</elem>
                  <elem>CA_GCR</elem>
                </CoarseSolverType>
                <CoarseResidual>0.1 0.1 0.1</CoarseResidual>
                <MaxCoarseIterations>12 12 8</MaxCoarseIterations>
                <RelaxationOmegaMG>1.0 1.0 1.0</RelaxationOmegaMG>
                <SmootherType>
                  <elem>CA_GCR</elem>
                  <elem>CA_GCR</elem>
                  <elem>CA_GCR</elem>
                </SmootherType>
                <SmootherTol>0.25 0.25 0.25</SmootherTol>
                <NullVectors>24 32</NullVectors>
                <Pre-SmootherApplications>0 0</Pre-SmootherApplications>
                <Post-SmootherApplications>8 8</Post-SmootherApplications>
                <SubspaceSolver>
                  <elem>CG</elem>
                  <elem>CG</elem>
                </SubspaceSolver>
                <RsdTargetSubspaceCreate>5e-06 5e-06</RsdTargetSubspaceCreate>
                <MaxIterSubspaceCreate>500 500</MaxIterSubspaceCreate>
                <MaxIterSubspaceRefresh>500 500</MaxIterSubspaceRefresh>
                <OuterGCRNKrylov>20</OuterGCRNKrylov>
                <PrecondGCRNKrylov>10</PrecondGCRNKrylov>
                <GenerateNullspace>true</GenerateNullspace>
                <GenerateAllLevels>true</GenerateAllLevels>
                <CheckMultigridSetup>false</CheckMultigridSetup>
                <CycleType>MG_RECURSIVE</CycleType>
                <SchwarzType>ADDITIVE_SCHWARZ</SchwarzType>
                <RelaxationOmegaOuter>1.0</RelaxationOmegaOuter>
                <SetupOnGPU>1 1</SetupOnGPU>
              </MULTIGRIDParams>
              <SubspaceID>mg_subspace</SubspaceID>
              <SolutionCheckP>true</SolutionCheckP>

            </InvertParam>
        </Propagator>
      </Param>
      <NamedObject>
        <gauge_id>default_gauge_field</gauge_id>
        <colorvec_files><elem>$colorvec_file</elem></colorvec_files>
        <prop_op_file>$prop_file</prop_op_file>
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

cat << EOF > $runpath/prop_create_run_${t_source}.sh
#!/bin/bash -l
#SBATCH -o $runpath/prop_create_run_${t_source}.out0
#SBATCH --account=p200054
#SBATCH -t 0:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q short
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J prop-${cfg}-${t_source}
#DEPENDENCY $colorvec_file_dep

. $chromaform/env.sh

cd $runpath
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=12
export CUDA_VISIBLE_DEVICES="0,1,2,3"
export GPU_DEVICE_ORDINAL="0,1,2,3"
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$chromaform/install/llvm/lib

rm -f $prop_file

srun \$MY_ARGS -n 4 -N 1 $chroma -i $runpath/prop_creation_${t_source}.xml -geom 1 1 2 2 -pool-max-alloc 0 -pool-max-alignment 512 -libdevice-path /apps/USE/easybuild/release/2021.3/software/CUDA/11.4.2/nvvm/libdevice &> $runpath/prop_create_run_${t_source}.out
EOF

done # t_source
done # cfg
