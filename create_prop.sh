#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running props
	[ $run_props != yes ] && continue

	for cfg in $confs; do
		lime_file_name="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"

		for t_source in $prop_t_sources; do
		for zphase in $prop_zphases; do

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

			prop_file="`prop_file_name`"
			mkdir -p `dirname ${prop_file}`

			#
			# Propagators creation
			#

			prop_xml="$runpath/prop_t${t_source}_z${zphase}.xml"
			mkdir -p `dirname ${prop_xml}`
			cat << EOF > $prop_xml
<?xml version="1.0"?>

<chroma>
<Param>
  <InlineMeasurements>

    <elem>
      <Name>PROP_AND_MATELEM_DISTILLATION_SUPERB</Name>
      <Frequency>1</Frequency>
      <Param>
        <Contractions>
          <mass_label>${prop_mass_label}</mass_label>
          <num_vecs>$nvec</num_vecs>
          <t_sources>$t_offset</t_sources>
          <Nt_forward>$prop_t_fwd</Nt_forward>
          <Nt_backward>$prop_t_back</Nt_backward>
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
            <Mass>${prop_mass}</Mass>
            <clovCoeff>${prop_clov}</clovCoeff>
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
                <Mass>${prop_mass}</Mass>
                <clovCoeff>${prop_clover}</clovCoeff>
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

			output="$runpath/prop_t${t_source}_z${zphase}.out"
			cat << EOF > $runpath/prop_t${t_source}_z${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/prop_t${t_source}_z${zphase}.out0
#SBATCH -t 0:30:00
#SBATCH --nodes=1
#SBATCH --gpus-per-task=1
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J prop-${cfg}-${t_source}-${zphase}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f $prop_file
	srun \$MY_ARGS -n 4 -N 1 $chroma -i ${prop_xml} -geom 1 1 2 2 $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $prop_file
}

class() {
	# class max_minutes nodes
	echo b 600 1
}

globus() {
	[ $prop_transfer_back == yes ] && echo ${prop_file}.globus ${this_ep}${prop_file#${confspath}} ${jlab_ep}${prop_file#${confspath}} ${prop_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # zphase
		done # t_source
	done # cfg
done # ens
