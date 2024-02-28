# This shell script is executed at the beginning of create_*.sh, launch.sh, cancel.sh and check.sh

. common.sh

ensembles="ensemble0"

ensemble0() {
	# Tasks to run
	run_eigs="nop"
	run_props="nop"
	run_gprops="nop"
	run_baryons="yes"
	run_mesons="nop"
	run_discos="nop"
	run_redstar="yes"

	run_onthefly="yes"
	onthefly_chroma_minutes=120
	max_moms_per_job=100

	# Ensemble properties
	confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
	ensemble="cl21_32_64_b6p3_m0p2350_m0p2050"
	confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
	tag="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
	confs="`seq 11000 10 13990`"
	s_size=32 # lattice spatial size
	t_size=64 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }
	lime_transfer_from_jlab="nop"

	# Colorvecs options
	max_nvec=128  # colorvecs to compute
	nvec=64  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${max_nvec}.mod${cfg}"; }
	eigs_slurm_nodes=2
	eigs_chroma_geometry="1 2 2 4"
	eigs_chroma_minutes=600
	eigs_transfer_back="yes"
	eigs_delete_after_transfer_back="nop"
	eigs_transfer_from_jlab="nop"

	# Props options
	prop_t_sources="`seq 0 63`"
	prop_t_fwd=64
	prop_t_back=0
	prop_nvec=96
	prop_zphases="0.00 2.00 -2.00"
	prop_zphases="0.00"
	prop_mass="-0.2350"
	prop_clov="1.20536588031793"
	prop_mass_label="U${prop_mass}"
	prop_slurm_nodes=2
	prop_chroma_geometry="1 2 2 4"
	prop_chroma_minutes=600
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
 "

	# propagator filename
	prop_file_name() {
		local n prot
		if [ ${zphase} == 0.00 ]; then
			n="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${prop_nvec}.light.t0_${t_source}.sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/phased/prop_db/d001_${zphase}/${cfg}/${confsname}.phased_${zphase}.prop.n${prop_nvec}.light.t0_${t_source}.sdb${cfg}"
		fi
		if [ $run_onthefly == yes -a $run_props == yes ] ; then
			prot=""
			[ x$1 != xsingle ] && prot="afs:"
			n="${prot}${localpath}/${n//\//_}"
		fi
		echo $n
	}
	prop_transfer_back="yes"
	prop_delete_after_transfer_back="yes"
	prop_transfer_from_jlab="yes"

	# Genprops options
	gprop_t_sources="${prop_t_sources}"
	gprop_t_seps="4 6 8 10 12 14"
	gprop_zphases="${prop_zphases}"
	gprop_nvec=$nvec
	gprop_moms="\
0 0 0  "  
	gprop_max_mom_in_contraction=1
	gprop_slurm_nodes=1
	gprop_chroma_geometry="1 1 2 4"
	gprop_chroma_minutes=120
	localpath="/tmp"
	gprop_are_local="nop"
	gprop_max_moms_per_job=1
	gprop_file_name() {
		local t_seps_commas="`echo $gprop_t_seps | xargs | tr ' ' ,`"
		local n node
		if [ $zphase == 0.00 ]; then
			n="${confspath}/${confsprefix}/unsmeared_meson_dbs/t0_${t_source}/unsmeared_meson.n${gprop_nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${gprop_nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
		fi
		if [ $run_onthefly == yes -a $run_gprops == yes ] ; then
			n="${localpath}/${n//\//_}"
			if [ x$1 == xsingle ] ; then
				echo $n
			else
				for (( node=0 ; node<gprop_slurm_nodes*slurm_procs_per_node ; ++node )) ; do
					echo "afs:${n}.part_$node"
				done
			fi
		else
			echo $n
		fi
	}
	gprop_transfer_back="nop"
	gprop_delete_after_transfer_back="nop"
	gprop_transfer_from_jlab="nop"

	# Meson options
	meson_nvec=$nvec
	meson_zphases="0.00 2.00"
	meson_slurm_nodes=2
	meson_chroma_max_tslices_in_contraction="1" # as large as possible
	meson_chroma_geometry="1 2 2 4"
	meson_chroma_minutes=600
	meson_chroma_parts=4 # split the time slices into this many different files
	meson_file_name() {
		if [ ${zphase} == 0.00 ]; then
			n="${confspath}/${confsprefix}/meson_db/${confsname}.n${meson_nvec}.m2_0_0.meson.colorvec.t_0_$((t_size-1)).sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/meson_db/${confsname}.n${meson_nvec}.m2_0_0.meson.colorvec.t_0_$((t_size-1)).phased_${zphase}.sdb${cfg}"
		fi
		if [ $meson_chroma_parts == 1 ]; then
			echo $n
		else
			for i in `seq 1 $meson_chroma_parts`; do
				echo $n.part_$i
			done
		fi
	}
	meson_transfer_from_jlab="nop"
	meson_extra_xml="
        <mom_list>
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
        </mom_list>
        <!-- List of displacement arrays -->
        <displacement_list>
          <elem></elem>
          <elem>1</elem>
          <elem>2</elem>
          <elem>3</elem>
          <elem>1 1</elem>
          <elem>2 2</elem>
          <elem>3 3</elem>
          <elem>1 2</elem>
          <elem>1 3</elem>
          <elem>2 1</elem>
          <elem>2 3</elem>
          <elem>3 1</elem>
          <elem>3 2</elem>
        </displacement_list>
"

	# Baryon options
	baryon_nvec=$nvec
	baryon_zphases="0.00"
	baryon_chroma_max_tslices_in_contraction=16 # as large as possible
	baryon_chroma_max_moms_in_contraction=1 # as large as possible (zero means do all momenta at once)
	baryon_chroma_max_vecs=12 # as large as possible (zero means do all eigenvectors are contracted at once)
	baryon_slurm_nodes=1
	baryon_chroma_geometry="1 1 1 8"
	baryon_chroma_minutes=120
	baryon_file_name() {
		local n node
		if [ ${zphase} == 0.00 ]; then
			n="${confspath}/${confsprefix}/baryon_db/${confsname}.n${baryon_nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/baryon_db/${confsname}.n${baryon_nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).phased_${zphase}.sdb${cfg}"
		fi
		if [ $run_onthefly == yes -a $run_baryons == yes ] ; then
			n="${localpath}/${n//\//_}"
			if [ x$1 == xsingle ] ; then
				echo $n
			else
				for (( node=0 ; node<baryon_slurm_nodes*slurm_procs_per_node ; ++node )) ; do
					echo "${n}.part_$node"
				done
			fi
		else
			echo $n
		fi
	}
	baryon_transfer_back="nop"
	baryon_delete_after_transfer_back="nop"
	baryon_transfer_from_jlab="nop"
	baryon_extra_xml="
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
"

	# Disco options
	disco_max_z_displacement=8
	disco_probing_displacement=6
	disco_probing_power=10
	disco_noise_vectors=1
	disco_slurm_nodes=2
	disco_chroma_geometry="1 2 2 4"
	disco_chroma_minutes=600
	disco_file_name() {
		echo "${confspath}/${confsprefix}/disco/${confsname}.disco.sdb${cfg}"
	}
	disco_transfer_back="yes"
	disco_delete_after_transfer_back="nop"
	disco_transfer_from_jlab="nop"

	# Redstar options
	redstar_t_corr=14 # Number of time slices
	redstar_nvec=$nvec
	redstar_tag="."
	redstar_use_meson="nop"
	redstar_use_baryon="yes"
	redstar_use_disco="nop"
	redstar_2pt="yes"
	redstar_2pt_moms="\
0 0 0
0 0 1
0 0 -1
0 0 2
0 0 -2"
	redstar_3pt="nop"
	redstar_3pt_snkmom_srcmom="\
0 0 0 0 0 -1
0 0 0 0 0 -2
0 0 0 0 0 2
0 0 -1 0 0 0
0 0 1 0 0 0
0 0 1 0 0 -1
0 0 -1 0 0 -2
0 0 1 0 0 2
0 0 -2 0 0 0
0 0 2 0 0 0
0 0 -2 0 0 -1
0 0 2 0 0 1
0 1 0 0 0 -1
0 1 0 0 0 1
0 1 0 0 0 -2
0 1 0 0 0 2
0 1 0 0 1 -1
0 1 0 0 1 1
0 1 0 0 1 -2
0 1 0 0 1 2
0 1 -1 0 0 0
0 1 1 0 0 0
0 1 -1 0 0 -1
0 1 1 0 0 1
0 1 -1 0 0 -2
0 1 1 0 0 2
0 1 -1 0 1 0
0 1 1 0 1 0
0 1 -1 0 1 -2
0 1 1 0 1 2
0 1 -2 0 0 0
0 1 2 0 0 0
0 1 -2 0 0 -1
0 1 2 0 0 1
0 1 -2 0 0 -2
0 1 2 0 0 2
0 1 -2 0 1 0
0 1 2 0 1 0
0 1 -2 0 1 -1
0 1 2 0 1 1
1 0 0 1 0 -1
1 0 0 1 0 1
1 0 0 1 0 -2
1 0 0 1 0 2
1 0 -1 0 0 -1
1 0 1 0 0 1
1 0 -1 1 0 0
1 0 1 1 0 0
1 0 -1 1 0 -2
1 0 1 1 0 2
1 0 -2 0 0 -2
1 0 2 0 0 2
1 0 -2 1 0 0
1 0 2 1 0 0
1 0 -2 1 0 -1
1 0 2 1 0 1
1 1 0 0 0 -1
1 1 0 0 0 1
1 1 0 0 0 -2
1 1 0 0 0 2
1 1 0 1 0 -1
1 1 0 1 0 1
1 1 0 1 0 -2
1 1 0 1 0 2
1 1 0 1 1 -1
1 1 0 1 1 1
1 1 0 1 1 -2
1 1 0 1 1 2
1 1 -1 0 0 0
1 1 1 0 0 0
1 1 -1 0 0 -1
1 1 1 0 0 1
1 1 -1 0 0 -2
1 1 1 0 0 2
1 1 -1 0 1 -1
1 1 1 0 1 1
1 1 -1 1 0 0
1 1 1 1 0 0
1 1 -1 1 0 -2
1 1 1 1 0 2
1 1 -1 1 1 0
1 1 1 1 1 0
1 1 -1 1 1 -2
1 1 1 1 1 2
1 1 -2 0 0 0
1 1 2 0 0 0
1 1 -2 0 0 -1
1 1 2 0 0 1
1 1 -2 0 0 -2
1 1 2 0 0 2
1 1 -2 0 1 -2
1 1 2 0 1 2
1 1 -2 1 0 0
1 1 2 1 0 0
1 1 -2 1 0 -1
1 1 2 1 0 1
1 1 -2 1 1 0
1 1 2 1 1 0
1 1 -2 1 1 -1
1 1 2 1 1 1
1 1 -3 0 0 -3
1 1 3 0 0 3
2 0 0 0 0 -1
2 0 0 0 0 1
2 0 0 0 0 -2
2 0 0 0 0 2
2 0 0 2 0 -1
2 0 0 2 0 1
2 0 0 2 0 -2
2 0 0 2 0 2
2 0 -1 0 0 0
2 0 1 0 0 0
2 0 -1 0 0 -2
2 0 1 0 0 2
2 0 -1 1 0 -1
2 0 1 1 0 1
2 0 -1 2 0 0
2 0 1 2 0 0
2 0 -1 2 0 -2
2 0 1 2 0 2
2 0 -2 0 0 0
2 0 2 0 0 0
2 0 -2 0 0 -1
2 0 2 0 0 1
2 0 -2 1 0 -2
2 0 2 1 0 2
2 0 -2 2 0 0
2 0 2 2 0 0
2 0 -2 2 0 -1
2 0 2 2 0 1
2 1 0 0 1 -1
2 1 0 0 1 1
2 1 0 0 1 -2
2 1 0 0 1 2
2 1 0 1 0 -1
2 1 0 1 0 1
2 1 0 1 0 -2
2 1 0 1 0 2
2 1 0 2 0 -1
2 1 0 2 0 1
2 1 0 2 0 -2
2 1 0 2 0 2
2 1 0 2 1 -1
2 1 0 2 1 1
2 1 0 2 1 -2
2 1 0 2 1 2
2 1 -1 0 1 0
2 1 1 0 1 0
2 1 -1 0 1 -2
2 1 1 0 1 2
2 1 -1 1 0 0
2 1 1 1 0 0
2 1 -1 1 0 -1
2 1 1 1 0 1
2 1 -1 1 0 -2
2 1 1 1 0 2
2 1 -1 1 1 -1
2 1 1 1 1 1
2 1 -1 2 0 0
2 1 1 2 0 0
2 1 -1 2 0 -1
2 1 1 2 0 1
2 1 -1 2 0 -2
2 1 1 2 0 2
2 1 -1 2 1 0
2 1 1 2 1 0
2 1 -1 2 1 -2
2 1 1 2 1 2
2 1 -2 0 1 0
2 1 2 0 1 0
2 1 -2 0 1 -1
2 1 2 0 1 1
2 1 -2 1 0 0
2 1 2 1 0 0
2 1 -2 1 0 -1
2 1 2 1 0 1
2 1 -2 1 0 -2
2 1 2 1 0 2
2 1 -2 1 1 -2
2 1 2 1 1 2
2 1 -2 2 0 0
2 1 2 2 0 0
2 1 -2 2 0 -1
2 1 2 2 0 1
2 1 -2 2 0 -2
2 1 2 2 0 2
2 1 -2 2 1 0
2 1 2 2 1 0
2 1 -2 2 1 -1
2 1 2 2 1 1 "
#	redstar_3pt_srcmom_snkmom="\
#0 0 -1  0 0 0   
#0 0 -2  0 0 0   
#0 0 2   0 0 0   
#0 0 0   0 0 -1  
#0 0 0   0 0 1  " 
	redstar_000="NucleonMG1g1MxD0J0S_J1o2_G1g1"
	redstar_n00="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1"
	redstar_nn0="NucleonMG1g1MxD0J0S_J1o2_H1o2D2E"
	redstar_nnn="NucleonMG1g1MxD0J0S_J1o2_H1o2D3E1"
	redstar_nm0="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nm0E"
	redstar_nnm="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nnmE"
	redstar_insertion_operators="\
pion_pionxDX__J0_A1
pion_pion_2xDX__J0_A1
rho_rhoxDX__J1_T1
rho_rho_2xDX__J1_T1
b_b1xDX__J1_T1
b_b0xDX__J0_A1
a_a1xDX__J1_T1
a_a0xDX__J0_A1
" # use for 3pt correlation functions
	#redstar_insertion_operators="rho_rhoxDX__J1_T1"
	redstar_insertion_disps="\
z0 
z1 3
z2 3 3
z3 3 3 3
z4 3 3 3 3
z5 3 3 3 3 3
z6 3 3 3 3 3 3
z7 3 3 3 3 3 3 3
z8 3 3 3 3 3 3 3 3
zn1 -3
zn2 -3 -3
zn3 -3 -3 -3
zn4 -3 -3 -3 -3
zn5 -3 -3 -3 -3 -3
zn6 -3 -3 -3 -3 -3 -3
zn7 -3 -3 -3 -3 -3 -3 -3
zn8 -3 -3 -3 -3 -3 -3 -3 -3"
	gprop_insertion_disps="${redstar_insertion_disps}"
	rename_moms() {
		[ $# == 3 ] && echo "mom$1.$2.$3"
		[ $# == 6 ] && echo "snk$1.$2.$3src$4.$5.$6"
	}
	corr_file_name() {
		if [ ${zphase} == 0.00 ]; then
			echo "${confspath}/${confsprefix}/corr/unphased/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/corr/z${zphase}/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
		fi
	}
	redstar_minutes=30
	redstar_jobs_per_node=8
	redstar_max_concurrent_jobs=24000
	redstar_transfer_back="yes"
	redstar_delete_after_transfer_back="nop"
	redstar_transfer_from_jlab="nop"

	globus_check_dirs="${confspath}/${confsprefix}/corr/unphased_2pt"
}

chroma_python="$PWD/chroma_python"
PYTHON=python3

#
# SLURM configuration for eigs, props, genprops, baryons and mesons
#

chromaform="$HOME/hadron/chromaform-perlmutter"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-cmake-superbblas-cuda/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512"
redstar_corr_graph="$chromaform/install/redstar-colorvec-hadron-hip-adat/bin/redstar_corr_graph"
redstar_npt="$chromaform/install/redstar-colorvec-hadron-hip-adat/bin/redstar_npt"

adat="$chromaform/install/adat-pdf-superbblas-sp"
dbavgsrc="$adat/bin/dbavgsrc"
dbmerge="$adat/bin/dbmerge"
dbutil="$adat/bin/dbutil"

anarchofs="$chromaform/install/anarchofs/anarchofs"

slurm_procs_per_node=4
slurm_cores_per_node=56
slurm_gpus_per_node=8
slurm_sbatch_prologue="#!/bin/bash
#SBATCH -A hadron_g
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH --gpu-bind=none
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH --ntasks-per-node=$slurm_procs_per_node # number of tasks per node
#SBATCH --gpus-per-task=1"

slurm_script_prologue="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=32
export SLURM_CPU_BIND=\"cores\"
"

#
# SLURM configuration for disco
#

chromaform_cpu="$SCRATCH/chromaform-perlmutter-cpu-sp"
chroma_cpu="$chromaform_cpu/install/chroma-sp-mgproto-qphix-qdpxx-double-nd4-avx512-superbblas-cpu-next/bin/chroma"
slurm_threads_per_proc_cpu=10
chroma_extra_args_cpu="-by 4 -bz 4 -pxy 0 -pxyz 0 -c $slurm_threads_per_proc_cpu -sy 1 -sz 1 -minct 1 -poolsize 1"

slurm_procs_per_node_cpu=4
slurm_sbatch_prologue_cpu="#!/bin/bash
#SBATCH --account=qjs@cpu
#SBATCH --ntasks-per-node=$slurm_procs_per_node_cpu # number of tasks per node"

slurm_script_prologue_cpu="
. $chromaform_cpu/env.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=$slurm_threads_per_proc_cpu
"

#
# SLURM configuration for redstar
#

slurm_script_prologue_redstar="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=7
export SLURM_CPU_BIND=\"cores\"
#export ROCR_VISIBLE_DEVICES=\"\${MY_JOB_INDEX:-0}\"
"

#
# Options for launch
#

max_jobs=20 # maximum jobs to be launched
max_hours=5 # maximum hours for a single job

#
# Path options
#
# NOTE: we try to recreate locally the directory structure at jlab; please give consistent paths

confspath="$SCRATCH/b6p3"
this_ep="6bdc7956-fc0f-4ad2-989c-7aa5ee643a79:${SCRATCH}/b6p3/"  # perlmutter
jlab_ep="a2f9c453-2bb6-4336-919d-f195efcf327b:~/qcd/cache/isoClover/" # jlab#gw2
jlab_local="/cache/isoClover"
jlab_tape_registry="/mss/lattice/isoClover"
jlab_user="$USER"
jlab_ssh="ssh qcdi1402.jlab.org"
