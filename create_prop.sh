#!/bin/bash

confs="`seq 4510 10 10000`"
confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
tag="cl21_32_64_b6p3_m0p2350_m0p2050"
t_sources="`seq 0 16 63`"

t_fwd=21
t_back=21
s_size=32 # lattice spatial size
t_size=64 # lattice temporal size
max_nvec=128 # number of eigenvector computed
nvec=64 # Number of eigenvectors used to compute perambulators
tagcnf="n$max_nvec"

confspath="/global/project/projectdirs/hadron/b6p3"
chroma="/global/project/projectdirs/hadron/qcd_software/nersc/cori-knl/parscalar/install/chroma-double/bin/chroma"

mkdir -p ${confspath}/${confsprefix}/prop_db

for cfg in $confs; do

runpath="$PWD/${tag}/run_prop_$cfg"
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
colorvec_file_dep="`cat ${runpath}/../run_eigs_${cfg}/run.bash.launched | tr -d '[:blank:]'`"
if [ -z $colorvec_file_dep ] ; then echo Not found $prop_file; continue; fi

prop_file="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${nvec}.light.t0_${t_source}.${tag}.sdb${cfg}"
if [ ! -f $colorvec_file ]; then
	echo Missing $colorvec_file
	continue;
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
      <Name>PROP_AND_MATELEM_DISTILLATION</Name>
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
#SBATCH -o $runpath/prop_create_run_${t_source}.out0
#SBATCH -t 0:40:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --constraint=knl
#SBATCH -A hadron
#SBATCH --qos=regular
#SBATCH -J prop-${cfg}-${t_source}
#DEPENDENCY $colorvec_file_dep

cd $runpath
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=64
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

rm -f $prop_file

srun -N2 -n8 -c68 \$MY_OFFSET --cpu_bind=cores $chroma -by 4 -bz 4 -pxy 0 -pxyz 0 -c 64 -sy 1 -sz 1 -minct 1 -poolsize 1 -i $runpath/prop_creation_${t_source}.xml  -geom 1 2 2 2 &> $runpath/prop_create_run_${t_source}.out
EOF

done # t_source
done # cfg
