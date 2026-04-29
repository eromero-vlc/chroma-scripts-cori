# This shell script is executed at the beginning of create_*.sh, launch.sh, cancel.sh and check.sh

. common.sh

ensembles="ensemble0"

ensemble0() {
	# Tasks to run
	run_eigs="nop"
	run_discos="nop"
	run_redstar="yes"

	onthefly_chroma_minutes=120
	max_moms_per_job=1000
	max_corr_per_job=10000
	max_phases_per_job=1000
	max_tseps_per_job=1000

	# Ensemble properties
	confsprefix="cl21_48_128_b6p5_m0p2070_m0p1750"
	ensemble="cl21_48_128_b6p5_m0p2070_m0p1750"
	confsname="cl21_48_128_b6p5_m0p2070_m0p1750"
	tag="cl21_48_128_b6p5_m0p2070_m0p1750"
	confs="`seq 1010 30 7634`"
	confs=1010
	s_size=48 # lattice spatial size
	t_size=128 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }

	# Colorvecs options
	max_nvec=512  # colorvecs to compute
	nvec=128  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${max_nvec}.mod${cfg}"; }
	eigs_slurm_nodes=1
	eigs_chroma_geometry="1 1 1 4"
	eigs_chroma_minutes=60

	# Props options
	t_sources="0 32 64 96"
	prop_mass="-0.2070"
	prop_clov="1.170082389372972"
	prop_mass_label="U${prop_mass}"
	prop_slurm_nodes=6
	prop_chroma_geometry="1 1 3 8"
	prop_chroma_minutes=20
	prop_max_rhs=8
	prop_inv="
              <invType>QUDA_MULTIGRID_CLOVER_INVERTER</invType>
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
              <RsdTarget>1e-10</RsdTarget>
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
                <Verbosity>false</Verbosity>
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
                <RsdTargetSubspaceCreate>5e-07 5e-07</RsdTargetSubspaceCreate>
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
 "
	prop_inv_new="
              <invType>MGPROTON</invType>

              <type>eo</type>
              <solver>
                <type>mr</type>
                <tol>1e-10</tol>
                <max_its>20000</max_its>
                <prefix>l0</prefix>
                <verbosity>Detailed</verbosity>
              </solver>
              <use_Aee_prec>true</use_Aee_prec>
              <prec_ee>
                   <type>mg</type>
                   <num_null_vecs>100</num_null_vecs>
                   <max_num_null_vecs>100</max_num_null_vecs>
                   <num_colors>24</num_colors>
                   <blocking>4 4 4 4</blocking>
                   <spin_splitting>chirality_splitting</spin_splitting>
                   <null_vecs>
                      <solver>
                        <type>eo</type>
                        <use_Aee_prec>true</use_Aee_prec>
                        <solver>
                          <type>mr</type>
                          <tol>1e-7</tol>
                          <max_its>100</max_its>
                          <error_if_not_converged>false</error_if_not_converged>
                          <prefix>l0_nv</prefix>
                          <verbosity>Detailed</verbosity>
                        </solver>
                      </solver>
                   </null_vecs>
                   <solver_smoother>
                     <type>eo</type>
                     <use_Aee_prec>true</use_Aee_prec>
                     <solver>
                       <type>mr</type>
                       <tol>1e-1</tol>
                       <max_its>8</max_its>
                       <error_if_not_converged>false</error_if_not_converged>
                       <verbosity>false</verbosity>
                       <prefix>s0</prefix>
                     </solver>
                   </solver_smoother>
                   <solver_coarse>
                     <type>eo</type>
                     <use_Aee_prec>true</use_Aee_prec>
                     <solver>
                       <type>mr</type>
                       <tol>1e-1</tol>
                       <max_its>6</max_its>
                       <error_if_not_converged>false</error_if_not_converged>
                       <verbosity>false</verbosity>
                       <prefix>c0</prefix>
                     </solver>
                     <prec_ee>
                          <type>mg</type>
                          <num_null_vecs>200</num_null_vecs>
                          <max_num_null_vecs>200</max_num_null_vecs>
                          <num_colors>32</num_colors>
                          <blocking>2 2 2 2</blocking>
                          <spin_splitting>chirality_splitting</spin_splitting>
                          <null_vecs>
                             <solver>
                               <type>eo</type>
                               <use_Aee_prec>true</use_Aee_prec>
                               <solver>
                                 <type>mr</type>
                                 <tol>1e-7</tol>
                                 <max_its>100</max_its>
                                 <error_if_not_converged>false</error_if_not_converged>
                                 <prefix>l1_nv</prefix>
                                 <verbosity>Detailed</verbosity>
                               </solver>
                             </solver>
                          </null_vecs>
                          <solver_smoother>
                            <type>eo</type>
                            <use_Aee_prec>true</use_Aee_prec>
                            <solver>
                              <type>mr</type>
                              <tol>1e-1</tol>
                              <max_its>16</max_its>
                              <error_if_not_converged>false</error_if_not_converged>
                              <verbosity>false</verbosity>
                              <prefix>s1</prefix>
                            </solver>
                          </solver_smoother>
                          <solver_coarse>
                            <type>eo</type>
                            <use_Aee_prec>true</use_Aee_prec>
                            <solver>
                              <type>mr</type>
                              <tol>1e-1</tol>
                              <max_its>13</max_its>
                              <error_if_not_converged>false</error_if_not_converged>
                              <verbosity>false</verbosity>
                              <prefix>c1</prefix>
                            </solver>
                          </solver_coarse>
                     </prec_ee>
                   </solver_coarse>
              </prec_ee>
	"

	# Genprops options
	gprop_t_seps="6 7 8 9 10 11 12"
	gprop_max_tslices_in_contraction=1
	gprop_max_mom_in_contraction=1
	localpath="/tmp"
	localpath="/dev/shm"

	# Baryon options
	redstar_op_bases=all
	redstar_op_bases=1

	# Disco options
	disco_max_displacement=16
	disco_probing_displacement=0
	disco_probing_power=20
	disco_max_colors=3325
	disco_max_colors_at_once=256
	disco_noise_vectors=1
	disco_t_sources="0 16 32 48 8 24 40 56"
	disco_slurm_nodes=1
	disco_chroma_geometry="1 2 2 2"
	disco_chroma_minutes=120
	disco_max_rhs=24
	disco_proj="
  <projectorType>MGPROTON</projectorType>
  <type>mg</type>
  <prolongator>
    <num_null_vecs>24</num_null_vecs>
    <blocking>4 4 4 4</blocking>
    <null_vecs>
      <solver>
        <type>eo</type>
        <use_Aee_prec>true</use_Aee_prec>
        <solver>
          <type>bicgstab</type>
          <tol>3e-3</tol>
          <max_its>10000</max_its>
          <prefix>eig0</prefix>
          <verbosity>summary</verbosity>
        </solver>
      </solver>
      <tol>0.01</tol>
      <eigensolver>
        <max_block_size>1</max_block_size>
        <max_basis_size>40</max_basis_size>
        <verbosity>VeryDetailed</verbosity>
      </eigensolver>
    </null_vecs>
  </prolongator>
  <proj>
    <type>mg</type>
    <prolongator>
      <num_null_vecs>32</num_null_vecs>
      <blocking>2 2 2 2</blocking>
      <null_vecs>
        <solver>
          <type>eo</type>
          <use_Aee_prec>true</use_Aee_prec>
          <solver>
            <type>bicgstab</type>
            <tol>1e-3</tol>
            <max_its>10000</max_its>
            <prefix>eig1</prefix>
            <verbosity>summary</verbosity>
          </solver>
        </solver>
        <tol>3e-3</tol>
        <eigensolver>
          <max_block_size>1</max_block_size>
          <max_basis_size>40</max_basis_size>
          <verbosity>VeryDetailed</verbosity>
        </eigensolver>
      </null_vecs>
    </prolongator>
    <proj>
      <type>defl</type>
      <rank>800</rank>
      <tol>1e-6</tol>
      <solver>
        <type>eo</type>
        <use_Aee_prec>true</use_Aee_prec>
        <solver>
          <type>bicgstab</type>
          <tol>3e-8</tol>
          <max_its>10000</max_its>
          <prefix>eig2</prefix>
          <verbosity>summary</verbosity>
        </solver>
      </solver>
      <eigensolver>
        <max_block_size>8</max_block_size>
        <max_basis_size>80</max_basis_size>
        <verbosity>VeryDetailed</verbosity>
      </eigensolver>
    </proj>
  </proj>
"
	disco_file_name() {
		if [ $color_part != avg ]; then
			echo "${confspath}/${confsprefix}/disco2/${confsname}.disco.t0_${t_source}.cp_${color_part}.sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/disco2/${confsname}.disco.t0_${t_source}.avg.sdb${cfg}"
		fi
	}
	disco_transfer_back="nop"
	disco_delete_after_transfer_back="nop"
	disco_transfer_from_jlab="nop"
	disco_insertions="\
z
$(
	for ldir in 1 2 3 ; do for dir in 1 -1 ; do for dist in $( seq 1 $disco_max_displacement ) ; do
		echo -n z
		for i in $( seq 1 $dist ); do echo -n " $(( ldir*dir ))" ; done
		echo
	done; done; done
)"

	# Redstar options
	redstar_t_corr=20 # Number of time slices
	redstar_nvec=$nvec
	redstar_tag="."
	redstar_auto_phasing="0 1 3"
	redstar_2pt="yes"
	redstar_2pt_max_mom=9
	redstar_2pt_moms="\
0 0 0  0 0 0
$(
	for i in `seq 1 $redstar_2pt_max_mom`; do
		echo 0 0 $i   0 0 $i
		echo 0 0 -$i  0 0 -$i
	done
)"
	redstar_3pt="yes"
	redstar_3pt_snkmom_srcmom="\
   0   0   0   2   0   1
   0   0   0   2   0   2
   0   0   0   2   2   1
   0   0   1  -3   0   1
   0   0   1   1  -2   0
   0   0   1   1   0   3
   0   0   1   1   1   2
   0   0   1   2   0   1
   0   0   1   2   0   2
   0   0   1   2   1   1
   0   0   1   2   2   1
   0   0   2   1   0   3
   0   0   2   1   1   1
   0   0   2   2   0   0
   0   0   3   1   0   1
   0   0   3   1   0   2
   0   0   3   1   1   1
   0   0   3   1   1   2
   0   1  -3  -1  -1  -2
   0   1  -3  -1  -1  -1
   0   1  -2  -1  -1  -1
   0   1  -1  -2  -1  -2
   0   1  -1  -1  -1  -2
   0   1  -1  -1  -1  -1
   0   1  -1  -1  -1   0
   0   1   0   1   2  -1
   0   1   1   1   0   3
   0   1   2   1   0   3
   0   1   3   1   0   1
   0   2  -2   1   0  -1
   1  -2  -2  -1   0  -1
   1  -2   2   0  -2   5
   1  -1  -2  -1   0  -3
   1  -1  -1  -1   0  -3
   1  -1   4   2   0   6
   1  -1   5   2  -2   4
   1  -1   6   2  -2   5
   1   0  -4   1   1  -2
   1   0  -4   2   0  -1
   1   0  -3  -1   0  -2
   1   0  -3  -1   0  -1
   1   0  -2  -1   0  -3
   1   0  -2  -1   0  -1
   1   0  -2  -1   0   0
   1   0  -1  -1   0  -3
   1   0  -1  -1   0  -1
   1   0  -1   2   0  -2
   1   0   0  -1   0  -2
   1   0   0   2   0  -1
   1   0   0   2   0   2
   1   0   1   0   0   3
   1   0   1   0   0   4
   1   0   1   3   0   1
   1   0   2   0   0   5
   1   0   2   0   0   6
   1   0   3   0   0   1
   1   0   4  -1  -1   2
   1   0   4  -1   0   2
   1   0   4  -1   0   4
   1   0   4   0   0   1
   1   0   4   0   0   2
   1   0   5  -1   0   2
   1   0   5  -1   0   4
   1   0   5  -1   0   5
   1   0   5   0   0   2
   1   0   5   0   0   4
   1   0   6  -1  -1   4
   1   0   6  -1   0   4
   1   0   6  -1   0   5
   1   0   6  -1   0   6
   1   0   6   0   0   2
   1   0   6   0   0   4
   1   0   6   0   0   5
   1   0   6   2   2   5
   1   1  -1  -1  -1  -1
   1   1   1   0   0   3
   1   1   2   0   0   4
   1   1   2   0   0   5
   1   1   4  -1  -1   4
   1   1   4   0  -1   4
   1   1   4   0   0   6
   1   1   5  -1  -1   5
   1   1   5   0  -1   4
   1   1   5   0  -1   5
   1   1   5   0   0   4
   1   1   6  -1  -1   5
   1   1   6  -1  -1   6
   1   1   6   0  -1   5
   1   1   6   0  -1   6
   1   1   6   0   0   5
   2   0  -2   1   0  -3
   2   0   2   1   0   0
   2   0   5   1   0   1
   2   2   1   0   0   0
   2   2   4   1   0   6
   2   2   5   0   0   4
   2   2   6   0   0   5
   3   0  -1   2   0   0
   5   0   1   4   0  -1 "
	redstar_2pt_moms="
$(
		echo $redstar_3pt_snkmom_srcmom | while read m0 m1 m2 m3 m4 m5 ; do
			echo $m0 $m1 $m2  $m0 $m1 $m2
			echo $m3 $m4 $m5  $m3 $m4 $m5
		done | sort -u
)
$redstar_3pt_snkmom_srcmom"
	redstar_2pt_moms="$( echo "$redstar_2pt_moms" | auto_phase_moms )"
	redstar_3pt_snkmom_srcmom="$( echo "$redstar_3pt_snkmom_srcmom" | auto_phase_moms )"
	redstar_disco="nop" # contracting for disco
	if [ $redstar_op_bases == 1 ]; then
		redstar_000="NucleonMG1g1MxD0J0S_J1o2_G1g1"
		redstar_n00="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1"
		redstar_nn0="NucleonMG1g1MxD0J0S_J1o2_H1o2D2E"
		redstar_nnn="NucleonMG1g1MxD0J0S_J1o2_H1o2D3E1"
		redstar_nm0="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nm0E"
		redstar_nnm="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nnmE"
	elif [ $redstar_op_bases == 3 ]; then
		redstar_000="NucleonMG1g1MxD0J0S_J1o2_G1g1 NucleonMG1g1MxD2J1M_J1o2_G1g1 NucleonMHg1SxD2J1M_J1o2_G1g1"
		redstar_n00="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D4E1 NucleonMHg1SxD2J1M_J1o2_H1o2D4E1"
		redstar_nn0="NucleonMG1g1MxD0J0S_J1o2_H1o2D2E NucleonMG1g1MxD2J1M_J1o2_H1o2D2E NucleonMHg1SxD2J1M_J1o2_H1o2D2E"
		redstar_nnn="NucleonMG1g1MxD0J0S_J1o2_H1o2D3E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D3E1 NucleonMHg1SxD2J1M_J1o2_H1o2D3E1"
		redstar_nm0="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nm0E NucleonMG1g1MxD2J1M_J1o2_H1o2C4nm0E NucleonMHg1SxD2J1M_J1o2_H1o2C4nm0E"
		redstar_nnm="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nnmE NucleonMG1g1MxD2J1M_J1o2_H1o2C4nnmE NucleonMHg1SxD2J1M_J1o2_H1o2C4nnmE"
	else
		redstar_000="NucleonMHg1MxD0J0S_J3o2_Hg1 NucleonMG1u1MxD0J0S_J1o2_G1u1 NucleonMG1u2MxD0J0S_J1o2_G1u1 NucleonMG1u3MxD0J0S_J1o2_G1u1 NucleonMHu1MxD0J0S_J3o2_Hu1 NucleonMG1g2MxD0J0S_J1o2_G1g1 NucleonMG1g1MxD0J0S_J1o2_G1g1 NucleonMG1g3MxD0J0S_J1o2_G1g1"
		redstar_n00="NucleonMHg1MxD0J0S_J3o2_H1o2D4E1 NucleonMHg1MxD0J0S_J3o2_H3o2D4E3 NucleonMG1u1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1u2MxD0J0S_J1o2_H1o2D4E1 NucleonMG1u3MxD0J0S_J1o2_H1o2D4E1 NucleonMHu1MxD0J0S_J3o2_H1o2D4E1 NucleonMHu1MxD0J0S_J3o2_H3o2D4E3 NucleonMG1g2MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g3MxD0J0S_J1o2_H1o2D4E1"
		redstar_nn0="NucleonMHg1MxD0J0S_J3o2_H1o2D2E NucleonMHg1MxD0J0S_J3o2_H3o2D2E NucleonMG1u1MxD0J0S_J1o2_H1o2D2E NucleonMG1u2MxD0J0S_J1o2_H1o2D2E NucleonMG1u3MxD0J0S_J1o2_H1o2D2E NucleonMHu1MxD0J0S_J3o2_H1o2D2E NucleonMHu1MxD0J0S_J3o2_H3o2D2E NucleonMG1g2MxD0J0S_J1o2_H1o2D2E NucleonMG1g1MxD0J0S_J1o2_H1o2D2E NucleonMG1g3MxD0J0S_J1o2_H1o2D2E"
	fi
	redstar_insertion_operators="\
fl_a0xDX__J0_A1
a_a0xDX__J0_A1
omegal_rhoxDX__J1_T1
rho_rhoxDX__J1_T1
hl_b1xDX__J1_T1
b_b1xDX__J1_T1
etal_pion_2xDX__J0_A1
pion_pion_2xDX__J0_A1
hl_b0xDX__J0_A1
b_b0xDX__J0_A1
omegal_rho_2xDX__J1_T1
rho_rho_2xDX__J1_T1
fl_a1xDX__J1_T1
a_a1xDX__J1_T1
etal_pionxDX__J0_A1
pion_pionxDX__J0_A1
" # use for 3pt correlation functions
	redstar_insertion_disps="\
z0 
$(
        for (( n=1 ; n<=12 ; ++n )) do
                echo -n z$n
                for (( z=0 ; z<n ; ++z )) do echo -n " 3"; done
                echo
                echo -n zn$n
                for (( z=0 ; z<n ; ++z )) do echo -n " -3"; done
                echo
        done
)"
	gprop_insertion_disps="${redstar_insertion_disps}"
	redstar_use_disco="`
		if [ $redstar_3pt == yes -a $redstar_disco == yes ] ; then echo yes ; else echo nop ; fi
`"
	rename_moms() {
		[ $# == 3 ] && echo "mom$1.$2.$3"
		[ $# == 6 ] && echo "snk$1.$2.$3src$4.$5.$6"
	}
	corr_file_name() {
		local prefix_path="auto_phasing_3_${redstar_auto_phasing_3}_4p_${redstar_auto_phasing_4plus// /,}"
		prefix_path_extra="_2pt_test_nvec${prop_nvec}"
		local tsep_extra=""
		[ ${redstar_3pt} == yes ] && tsep_extra="_tsep${tsep}"
		if [ x$cfg != xavg -a x$cfg != x ] ; then
			local ins_path="/ins_${insertion_op}_tsep_${tsep}"
			echo "${confspath}/${confsprefix}/corr/${prefix_path}${prefix_path_extra}/t0_${t_source}${ins_path}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.phase_${phase_leader}_tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_${prefix_path}${tsep_extra}.sdb${cfg}"
		elif [ x$cfg == xavg ] ; then
			echo "${confspath}/${confsprefix}/corr/${prefix_path}${prefix_path_extra}/avg/${confsname}.nuc_local.n${redstar_nvec}.phase_${phase_leader}_tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_${prefix_path}${tsep_extra}.sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/corr/${prefix_path}${prefix_path_extra}/t0_avg/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.phase_${phase_group}_tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_${prefix_path}${tsep_extra}.sdb${cfg}"
		fi
	}
	pack_file_name() {
		local prefix_path="auto_phasing_3_${redstar_auto_phasing_3}_4p_${redstar_auto_phasing_4plus// /,}"
		prefix_path_extra="_2pt-disco"
		echo "${confspath}/${confsprefix}/corr/${prefix_path}${prefix_path_extra}/corr_pack_cfg_${cfg}.tar.gz"
	}
	redstar_slurm_nodes=3
	redstar_minutes=30

	globus_check_dirs="${confspath}/${confsprefix}/corr-none"
}

#
# SLURM configuration for eigs, props, genprops, baryons and mesons
#

chromaform="${HOME}/work_qch_sf/chromaform-h100"
chroma="$chromaform/install/chroma-sp-quda-qdp-jit-double-nd4-cmake-superbblas-cuda-next/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512" # -libdevice-path /opt/rocm-6.0.0/llvm/lib"

redstar="/home/eloy/PHY/src/chromaform/install/redstar-colorvec-hadron-cpu-adat"
redstar_corr_graph="$redstar/bin/redstar_corr_graph"
redstar_npt="$redstar/bin/redstar_npt"

adat="$chromaform/install-here/adat-pdf-next-meta-superbblas-sp"
dbavg="$adat/bin/dbavg"
dbavgsrc="$adat/bin/dbavgsrc"
dbavg_disco="$adat/bin/dbavg_disco"
dbmerge="$adat/bin/dbmerge"
dbutil="$adat/bin/dbutil"

slurm_procs_per_node=4
slurm_cores_per_node=96
slurm_gpus_per_node=4
slurm_sbatch_prologue="#!/bin/bash
#SBATCH -A qch@h100
#SBATCH -C h100
#SBATCH --gres=gpu:4 --hint=nomultithread --cpus-per-task=24
#SBATCH --gpu-bind=none --tasks-per-node=4"

slurm_script_prologue="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=$(( slurm_cores_per_node/slurm_gpus_per_node - 1))
export SLURM_CPU_BIND=\"cores\"
export SB_MPI_GPU=1
#export SB_CACHEGB_GPU=60
export MPICH_GPU_SUPPORT_ENABLED=1
export SB_MPI_NONBLOCK=0
#export SB_NUM_GPUS_ON_NODE=1
export QUDA_ENABLE_P2P=0
export QUDA_ENABLE_GDR=0
export QUDA_ENABLE_NVSHMEM=0
export QUDA_ENABLE_MPS=0
"

#
# Options for launch
#

BASH_INVOCATION_OPTIONS=
srun_aggregate=nop
max_jobs=400 # maximum jobs to be launched
max_minutes=120 # maximum hours for a single job
slurm_max_bundled_jobs=200 # maximum bundled jobs in a slurm job
slurm_max_jobs=400 # maximum bundled jobs in a slurm job

#
# Path options
#
# NOTE: we try to recreate locally the directory structure at jlab; please give consistent paths

confspath="$HOME/work_qch"
this_ep="36d521b3-c182-4071-b7d5-91db5d380d42:scratch/"  # frontier
jlab_ep="a2f9c453-2bb6-4336-919d-f195efcf327b:~/qcd/cache/isoClover/b6p3/" # jlab#gw2
jlab_local="/cache/isoClover/b6p3"
jlab_tape_registry="/mss/lattice/isoClover/b6p3"
