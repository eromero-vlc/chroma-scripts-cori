#!/bin/bash

confs="`seq 800 10 4000`"
confs=1010
confsprefix="cl21_48_128_b6p5_m0p2070_m0p1750"
confsname="cl21_48_128_b6p5_m0p2070_m0p1750"
ensemble="cl21_48_128_b6p5_m0p2070_m0p1750"
tag="cl21_48_128_b6p5_m0p2070_m0p1750"

t_fwd=21
t_back=21
s_size=48 # lattice spatial size
t_size=128 # lattice temporal size


t_sources="`seq 0 24 95`"
t_seps="4 6 8 10 12 14"
zphase="0.00"

max_nvec=128 # number of eigenvector computed
nvec=128 # Number of eigenvectors used to compute perambulators
tagcnf="n$max_nvec"
confspath="/gpfsdswork/projects/rech/ual/uie52up/ppdfs"
chromaform="\$HOME/work/chromaform"
chroma="$chromaform/install/chroma2-quda-qdp-jit-double-nd4/bin/chroma"
chroma_python="/gpfsdswork/projects/rech/ual/uie52up/chroma-scripts-cori/chroma_python"

this_ep="9d6d99eb-6d04-11e5-ba46-22000b92c6ec:"
this_ep="dcb5f28c-dadf-11eb-8324-45cc1b8ccd4a:"
jlab_ep="a6fccca2-d1a2-11e5-9a63-22000b96db58:~/qcd/cache/isoClover/"

for t_source in $t_sources; do
   mkdir -p ${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}
done

MG_PARAM_FILE="`mktemp`"
cat <<EOF > $MG_PARAM_FILE
AntiPeriodicT                 True
MGLevels                      3
Blocking                      4,4,3,3:2,2,2,2
NullVecs                      24:32
NullSolverMaxIters            800:800
NullSolverRsdTarget           5e-6:5e-6
OuterSolverNKrylov            5
OuterSolverRsdTarget          1.0e-7
OuterSolverVerboseP           True
VCyclePreSmootherMaxIters     0:0
VCyclePreSmootherRsdTarget    0.0:0.0
VCyclePostSmootherNKrylov     4:4
VCyclePostSmootherMaxIters    8:13
VCyclePostSmootherRsdTarget   0.06:0.06
VCycleBottomSolverMaxIters    100:100
VCycleBottomSolverNKrylov     8:8
VCycleBottomSolverRsdTarget   0.06:0.06
EOF

# QUDA
cat <<EOF > $MG_PARAM_FILE
RsdTarget                 1.0e-7
AntiPeriodicT             True
SolverType                GCR
Blocking		  3,3,4,4:2,2,2,2
NullVectors		  24:32
SmootherType		  CA_GCR:CA_GCR:CA_GCR
SmootherTol               0.25:0.25:0.25
CoarseSolverType	  GCR:CA_GCR
CoarseResidual            0.1:0.1:0.1
Pre-SmootherApplications  0:0
Post-SmootherApplications 8:8
SubspaceSolver            CG:CG
RsdTargetSubspaceCreate   5e-06:5e-06
EOF

lowDispBound=8 # EXCLUSIVE!
minX=0
minY=0
#minZ=$(( $lowDispBound + 1 ))
minZ=0
maxX=0
maxY=0
maxZ=8
threeMom="0,0,0" # momentum transfer
gammas="gt g5gz g5gx g5gy g5gt gxgy gxgz gxgt gygz gygt gzgt"
disps="+z,$maxZ -z,$maxZ none"
gdm=""
prettyGDM=""
for g in $gammas; do
    prettyGDM="${prettyGDM}${g}_"
    for d in $disps; do
        gdm="$gdm;$g:$d:$threeMom"
    done
done
GDM=`echo $gdm | cut -b 2-`

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

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
[ -f $lime_file ] || continue
gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.${tagcnf}.mod${cfg}"
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.mod${cfg}"
colorvec_file_dep=""
#colorvec_file_dep="`cat ${runpath}/../run_eigs_${cfg}/run.bash.launched | tr -d '[:blank:]'`"
#if [ -z $colorvec_file_dep ] ; then echo Not found $colorvec_file; continue; fi

if [ "X${zphase}X" != XX ]; then
prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${nvec}.light.t0_${t_source}.phased_${zphase}.sdb${cfg}"
else
prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${nvec}.light.t0_${t_source}.sdb${cfg}"
fi

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
                <Mass>-0.2070</Mass>
                <clovCoeff>1.170082389372972</clovCoeff>
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
                <Mass>-0.2070</Mass>
                <clovCoeff>1.170082389372972</clovCoeff>
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
                  <elem>3 3 3 4</elem>
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
            <!-- InvertParam>
              <invType>MG_PROTO_QPHIX_EO_CLOVER_INVERTER</invType>
              <CloverParams>
                <Mass>-0.2070</Mass>
                <clovCoeff>1.170082389372972</clovCoeff>
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
            </InvertParam -->
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
#!/bin/bash
#SBATCH -o $runpath/gprop_create_run_${t_source}.out0
#SBATCH --account=qjs@gpu
#SBATCH --job-name=prop48_128
##SBATCH --constraint=v100-32g
#SBATCH --nodes=64
#SBATCH --ntasks=256
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=10
#SBATCH --hint=nomultithread
#SBATCH --time=0:30:00
#SBATCH --gres=gpu:4
#DEPENDENCY $colorvec_file_dep

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=10
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

. $chromaform/env.sh
rm -f $prop_file

srun -N64 -n256 -c10 \$MY_OFFSET --cpu_bind=cores $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 10 -sy 1 -sz 1 -minct 1 -pool-max-alloc 0 -pool-max-alignment 512 -i $runpath/prop_creation_${t_source}.xml  -geom 2 4 4 8 &> $runpath/prop_create_run_${t_source}.out
EOF

done # t_source
done # cfg
