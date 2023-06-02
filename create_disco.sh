#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running disco
	[ $run_discos != yes ] && continue

	# Create the directory to store the results
	mkdir -p ${confspath}/${confsprefix}/disco

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		disco_file="`disco_file_name`"
		[ -f $lime_file ] || continue
		
		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath
		
		#
		# Basis creation
		#
		
		cat << EOF > $runpath/disco.xml
<?xml version="1.0"?>
<chroma>
 <Param>
  <InlineMeasurements>
   <elem>
    <Name>DISCO_PROBING_DEFLATION_SUPERB</Name>
      <Param>
        <max_path_length>${disco_max_z_displacement}</max_path_length>
        <mom_list>
           <elem>0 0 0</elem>
           <elem>0 0 1</elem>
           <elem>0 0 -1</elem>
           <elem>0 0 2</elem>
           <elem>0 0 -2</elem>
           <elem>0 0 3</elem>
           <elem>0 0 -3</elem>
        </mom_list>
        <mass_label>${prop_mass_label}</mass_label>
        <probing_distance>${disco_probing_displacement}</probing_distance>
        <probing_power>${disco_probing_power}</probing_power>
        <noise_vectors>${disco_noise_vectors}</noise_vectors>
        <max_rhs>1</max_rhs>
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
              <invType>MG_PROTO_QPHIX_EO_CLOVER_INVERTER</invType>
              <CloverParams>
                <Mass>${prop_mass}</Mass>
                <clovCoeff>${prop_clov}</clovCoeff>
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
                <Mass>${prop_mass}</Mass>
                <clovCoeff>${prop_clov}</clovCoeff>
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
              <NullSolverRsdTarget>-0.002 -0.0002</NullSolverRsdTarget>
              <NullSolverVerboseP>0 0</NullSolverVerboseP>
              <EigenSolverBlockSize>1</EigenSolverBlockSize>
              <EigenSolverMaxRestartSize>32</EigenSolverMaxRestartSize>
              <EigenSolverMaxRank>1600</EigenSolverMaxRank>
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
        <sdb_file>${disco_file}</sdb_file>
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
      <elem>$cfg</elem>
    </Seed>
  </RNG>
  <Cfg>
    <cfg_type>SCIDAC</cfg_type>
    <cfg_file>${lime_file}</cfg_file>
    <parallel_io>true</parallel_io>
  </Cfg>
</chroma>
EOF

		output="$runpath/disco.out"
		cat << EOF > $runpath/disco.sh
$slurm_sbatch_prologue_cpu
#SBATCH -o $runpath/disco.out0
#SBATCH -t $disco_chroma_minutes
#SBATCH --nodes=$disco_slurm_nodes
#SBATCH -J disco-${cfg}

run() {
	$slurm_script_prologue_cpu
	
	cd $runpath
	rm -f $colorvec_file
	srun \$MY_ARGS -n $(( slurm_procs_per_node_cpu*disco_slurm_nodes )) -N $disco_slurm_nodes $chroma_cpu -i $runpath/disco.xml -geom $disco_chroma_geometry $chroma_extra_args_cpu &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo $lime_file
}

outs() {
	echo $disco_file
}

class() {
	# class max_minutes nodes
	echo a $disco_chroma_minutes $disco_slurm_nodes
}

globus() {
	[ $disco_transfer_back == yes ] && echo ${disco_file}.globus ${this_ep}${disco_file#${confspath}} ${jlab_ep}${disco_file#${confspath}} ${disco_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF
	done # cfg
done # ens
