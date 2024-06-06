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
	onthefly_chroma_minutes=30
	max_moms_per_job=100
	onthefly_all_tsources_per_job=yes
	disco_stage=vac
	disco_stage=""

	# Ensemble properties
	confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050"
	ensemble="cl21_32_64_b6p3_m0p2350_m0p2050"
	confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
	tag="test$disco_stage"
	confs="`seq 1000 10 4500`"
	#confs=1000
	s_size=32 # lattice spatial size
	t_size=64 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }
	lime_transfer_from_jlab="yes"

	# Colorvecs options
	max_nvec=128  # colorvecs to compute
	nvec=64  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.mod${cfg}"; }
	eigs_slurm_nodes=2
	eigs_chroma_geometry="1 2 2 4"
	eigs_chroma_minutes=600
	eigs_transfer_back="nop"
	eigs_delete_after_transfer_back="nop"
	eigs_transfer_from_jlab="yes"

	# Props options
	prop_t_sources="0 16 32 48"
	prop_t_sources="`seq 0 63`"
	prop_t_fwd=16
	prop_t_back=0
	prop_nvec=64
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
		local n node
		if [ ${zphase} == 0.00 ]; then
			n="${confspath}/${confsprefix}/prop_db/${confsname}.prop.n${prop_nvec}.light.t0_${t_source}.sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/phased/prop_db/d001_${zphase}/${cfg}/${confsname}.phased_${zphase}.prop.n${prop_nvec}.light.t0_${t_source}.sdb${cfg}"
		fi
		if [ $run_onthefly == yes -a $run_props == yes ] ; then
			n="${localpath}/${n//\//_}"
			if [ x$1 == xsingle ] ; then
				echo $n
			else
				for (( node=0 ; node<gprop_slurm_nodes*slurm_procs_per_node ; ++node )) ; do
					echo "${n}.part_$node"
				done
			fi
		else
			echo $n
		fi
	}
	prop_transfer_back="nop"
	prop_delete_after_transfer_back="nop"
	prop_transfer_from_jlab="nop"

	# Genprops options
	gprop_t_sources="${prop_t_sources}"
	gprop_t_seps="4 6 8 10 12 14"
	gprop_zphases="${prop_zphases}"
	gprop_nvec=$nvec
	gprop_moms="0 0 0"
	gprop_moms="`echo "$gprop_moms" | while read mx my mz; do echo "$mx $my $mz"; echo "$(( -mx )) $(( -my )) $(( -mz ))"; done | sort -u`"
	gprop_max_tslices_in_contraction=1
	gprop_max_mom_in_contraction=1
	gprop_slurm_nodes=1
	gprop_chroma_geometry="1 1 2 4"
	gprop_chroma_minutes=120
	localpath="/scratch/eloy"
	gprop_file_name() {
		local t_seps_commas="`echo $gprop_t_seps | xargs | tr ' ' ,`"
		local n node
		if [ $zphase == 0.00 ]; then
			n="${confspath}/${confsprefix}/unsmeared_meson_dbs/t0_${t_source}/unsmeared_meson.n${gprop_nvec}.${t_source}.tsnk_${t_seps_commas}.sdb${cfg}"
		else
			n="${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${gprop_nvec}.${t_source}.tsnk_${t_seps_commas}.sdb${cfg}"
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
	baryon_zphases="${prop_zphases}"
	baryon_chroma_max_tslices_in_contraction=8 # as large as possible
	baryon_chroma_max_moms_in_contraction=4 # as large as possible (zero means do all momenta at once)
	baryon_chroma_max_vecs=64 # as large as possible (zero means do all eigenvectors are contracted at once)
	baryon_slurm_nodes=1
	baryon_chroma_geometry="1 1 1 8"
	baryon_chroma_minutes=120
	baryon_file_name() {
		local n node
		if [ ${zphase} == 0.00 ]; then
			n="${confspath}/${confsprefix}/baryon_db/${confsname}.n${baryon_nvec}.absmomz_0_4.baryon.colorvec.t_0_$((t_size-1)).sdb${cfg}"
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
          <!-- elem><left>0</left><middle>0</middle><right>1</right></elem>
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
          <elem><left>0</left><middle>3</middle><right>3</right></elem -->
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
		echo "${confspath}/${confsprefix}/disco${disco_stage}/${confsname}.disco.s1.sdb${cfg}"
	}
	disco_transfer_back="yes"
	disco_delete_after_transfer_back="nop"
	disco_transfer_from_jlab="nop"

	# Redstar options
	redstar_t_corr=16 # Number of time slices
	redstar_nvec=$nvec
	redstar_tag="."
	redstar_2pt="nop"
	redstar_2pt_moms="\
-2 0 2
0 2 -2
-1 2 2
2 2 1
-1 0 3
-3 0 1
0 -1 3
3 0 1
1 1 1
-1 -1 1
-1 1 1
0 1 -2
-2 0 1
-1 0 2
0 -1 2
1 -2 0
-1 1 2
-1 -2 1
-1 0 0
0 -1 0
0 1 1
-1 0 1
0 -1 1
-2 0 0
1 3 1
-2 -1 1
1 -1 0
-2 -2 1
2 -2 0
1 -1 2
-1 3 1
0 -2 -2
-2 1 -1
0 -1 -1
-1 -2 -1
-3 -1 -1
-2 -2 0
2 -1 2
-1 1 0
1 3 -1
-3 0 -1
1 -2 -2
1 3 0
0 -3 0
-2 2 0
1 -1 -1
-1 3 -1
-1 -3 1
1 -3 -1
1 -1 -3
0 2 0
2 2 0
-1 1 -1
-1 -1 -1
1 -1 1
0 -2 0
0 -2 2 "
	redstar_3pt="yes"
	redstar_3pt_snkmom_srcmom="\
0 0 0    0 0 0
0 0 1    0 0 1
0 0 2    0 0 2
0 0 3    0 0 3
0 0 -1    0 0 -1
0 0 -2    0 0 -2
0 0 -3    0 0 -3"
	redstar_3pt_snkmom_srcmom="\
0 0 0    0 0 0"
	redstar_2pt_moms="$(
		echo $redstar_3pt_snkmom_srcmom | while read m0 m1 m2 m3 m4 m5 ; do
			echo $m0 $m1 $m2
			echo $m3 $m4 $m5
		done | sort -u
)"
	redstar_disco="yes"
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
" # use for 3pt and disco correlation functions
	redstar_insertion_operators="\
hc_b0xDX__J0_A1"
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
	redstar_use_meson="nop"
	redstar_use_baryon="yes"
	redstar_use_gprops="`
		if [ $redstar_3pt == yes -a $redstar_disco != yes ] ; then echo yes ; else echo nop ; fi
`"
	redstar_use_disco="`
		if [ $redstar_3pt == yes -a $redstar_disco == yes ] ; then echo yes ; else echo nop ; fi
`"
	redstar_black_list_cnf_tslice="\
2000 36
2010 12
2010 28
2020 4
2030 20
2030 52
2030 60
2040 36
2050 12
2070 44
2070 52
2070 60
2080 12
2080 36
2090 12
2100 12
2110 52
2110 60
2120 36
2130 28
2150 20
2150 52
2150 60
2160 4
2160 36
2190 44
2190 52
2190 60
2200 4
2200 36
2200 44
2230 12
2230 52
2230 60
2240 36
2250 12
2260 28
2270 52
2270 60
2280 20
2280 36
2300 12
2310 52
2310 60
2320 36
2320 44
2330 4
2350 52
2350 60
2360 36
2380 12
2380 28
2390 12
2390 52
2390 60
2400 20
2400 36
2430 12
2430 52
2430 60
2440 36
2440 44
2470 52
2470 60
2480 4
2480 36
2510 28
2510 52
2510 60
2520 20
2520 36
2550 20
2550 52
2550 60
2560 36
2560 44
2570 12
2580 12
2590 12
2590 52
2590 60
2600 36
2610 20
2620 4
2620 12
2630 12
2630 52
2630 60
2640 28
2640 36
2670 52
2670 60
2680 20
2680 36
2680 44
2710 52
2710 60
2720 36
2730 12
2750 52
2750 60
2760 12
2760 36
2780 28
2790 52
2790 60
2800 36
2800 44
2810 12
2820 20
2830 52
2830 60
2840 12
2840 36
2850 4
2850 12
2870 12
2870 52
2870 60
2880 36
2890 20
2900 28
2910 52
2910 60
2920 36
2920 44
2950 52
2950 60
2960 12
2960 20
2960 36
2970 4
2980 12
2990 12
2990 52
2990 60
3000 36
3010 12
3020 28
3030 52
3030 60
3040 36
3060 44
3070 12
3070 52
3070 60
3080 20
3080 36
3100 4
3100 12
3110 52
3110 60
3120 36
3130 12
3140 28
3150 12
3150 52
3150 60
3160 36
3180 4
3180 44
3190 12
3190 52
3190 60
3200 12
3200 20
3200 36
3220 12
3230 4
3230 52
3230 60
3240 12
3240 36
3260 28
3270 52
3270 60
3280 36
3310 44
3310 52
3310 60
3320 20
3320 36
3340 4
3350 52
3350 60
3360 4
3360 36
3380 28
3390 52
3390 60
3400 36
3430 44
3430 52
3430 60
3440 20
3440 36
3450 12
3470 52
3470 60
3480 12
3480 36
3500 4
3500 28
3510 52
3510 60
3520 36
3550 44
3550 52
3550 60
3560 20
3560 36
3570 12
3590 52
3590 60
3600 36
3630 52
3630 60
3640 36
3650 4
3670 44
3670 52
3670 60
3680 20
3680 28
3680 36
3710 12
3710 52
3710 60
3720 36
3730 12
3750 52
3750 60
3760 12
3760 36
3780 4
3790 44
3790 52
3790 60
3800 12
3800 20
3800 28
3800 36
3830 52
3830 60
3840 36
3870 52
3870 60
3880 36
3890 12
3890 28
3910 4
3910 12
3910 44
3910 52
3910 60
3920 20
3920 36
3930 28
3950 52
3950 60
3960 36
3990 52
3990 60
4000 12
4000 36
4010 12
4030 44
4030 52
4030 60
4040 20
4040 36
4050 4
4050 28
4070 12
4070 52
4070 60
4080 36
4090 0
4090 12
4090 16
4090 32
4110 52
4110 60
4120 36
4150 44
4150 52
4150 60
4160 20
4160 36
4170 4
4170 12
4180 28
4190 52
4190 60
4200 36
4210 0
4210 16
4210 32
4230 12
4230 52
4230 60
4240 36
4240 44
4270 52
4270 60
4280 20
4280 36
4290 12
4300 28
4310 52
4310 60
4320 36
4330 4
4340 12
4350 12
4350 52
4350 60
4360 36
4370 44
4390 52
4390 60
4400 4
4400 20
4400 36
4410 12
4420 28
4430 52
4430 60
4440 36
4450 12
4460 12
4470 52
4470 60
4480 36
4480 44
4500 4
1000 1
1000 11
1000 12
1000 60
1000 64
1010 64
1020 36
1020 52
1020 60
1020 64
1030 36
1030 52
1030 60
1030 64
1040 64
1050 4
1050 12
1050 20
1050 64
1060 36
1060 64
1070 28
1070 44
1070 52
1070 60
1070 64
1080 64
1090 12
1090 64
1100 36
1100 64
1110 12
1110 52
1110 60
1110 64
1120 12
1120 52
1120 64
1130 12
1130 64
1140 12
1140 36
1140 64
1150 52
1150 60
1150 64
1160 52
1160 60
1160 64
1170 12
1170 20
1170 60
1170 64
1180 4
1180 36
1180 64
1190 12
1190 36
1190 44
1190 52
1190 60
1190 64
1200 12
1200 28
1200 64
1210 12
1210 36
1210 64
1220 52
1220 60
1220 64
1230 64
1240 52
1240 64
1250 52
1250 64
1260 64
1270 12
1270 64
1280 52
1280 60
1280 64
1290 12
1290 20
1290 60
1290 64
1300 4
1300 12
1300 64
1310 36
1310 64
1320 36
1320 64
1330 12
1330 44
1330 64
1340 12
1340 28
1340 52
1340 60
1340 64
1350 28
1350 36
1350 64
1360 64
1370 64
1380 64
1390 36
1390 52
1390 64
1400 64
1410 12
1410 20
1410 64
1420 4
1420 12
1420 52
1420 60
1430 36
1430 52
1430 60
1440 12
1450 12
1450 44
1460 52
1460 60
1470 12
1470 28
1470 36
1480 36
1490 12
1500 52
1500 60
1510 36
1530 20
1540 52
1540 60
1550 12
1550 36
1560 4
1570 44
1580 52
1580 60
1590 36
1590 52
1590 60
1610 28
1620 52
1620 60
1630 36
1640 36
1650 12
1650 20
1660 12
1660 52
1660 60
1670 36
1680 4
1680 12
1690 12
1690 44
1700 52
1700 60
1710 12
1710 36
1720 12
1730 12
1740 28
1740 52
1740 60
1750 36
1770 20
1780 52
1780 60
1790 12
1790 36
1800 4
1820 44
1820 52
1820 60
1830 36
1850 12
1860 12
1860 52
1860 60
1870 28
1870 36
1880 12
1890 20
1900 12
1900 52
1900 60
1910 36
1920 0
1920 1
1920 2
1920 3
1920 4
1920 5
1920 6
1920 7
1920 8
1920 9
1920 10
1920 11
1920 12
1920 13
1920 14
1920 15
1920 16
1920 17
1920 18
1920 19
1920 20
1920 21
1920 22
1920 23
1920 24
1920 25
1920 26
1920 27
1920 28
1920 29
1920 30
1920 31
1920 32
1920 33
1920 34
1920 35
1920 36
1920 37
1920 38
1920 39
1920 40
1920 41
1920 42
1920 43
1920 44
1920 45
1920 46
1920 47
1920 49
1920 50
1920 51
1920 52
1920 53
1920 54
1920 55
1920 56
1920 57
1920 58
1920 59
1920 60
1920 61
1920 62
1920 63
1930 4
1930 12
1950 44
1950 52
1950 60
1960 12
1960 36
1980 12
1990 12
1990 52
1990 60"
	rename_moms() {
		[ $# == 3 ] && echo "mom$1.$2.$3"
		[ $# == 6 ] && echo "snk$1.$2.$3src$4.$5.$6"
	}
	corr_file_name() {
		if [ ${zphase} == 0.00 ]; then
			if [ $t_source == avg ]; then
				echo "${confspath}/${confsprefix}/corr/unphased${disco_stage}/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			else
				echo "${confspath}/${confsprefix}/corr/unphased${disco_stage}/t0_${t_source}/ins_${insertion_op}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			fi
		else
			if [ $t_source == avg ]; then
				echo "${confspath}/${confsprefix}/corr/z${zphase}/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			else
				echo "${confspath}/${confsprefix}/corr/z${zphase}/t0_${t_source}/ins_${insertion_op}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			fi
		fi
	}
	redstar_slurm_nodes=1
	redstar_minutes=30
	redstar_jobs_per_node=8 # use for computing corr graphs
	redstar_max_concurrent_jobs=32
	redstar_transfer_back="nop"
	redstar_delete_after_transfer_back="nop"
	redstar_transfer_from_jlab="nop"

	globus_check_dirs="${confspath}/${confsprefix}/corr/z2.00"
}

chroma_python="$PWD/chroma_python"
PYTHON=python3

#
# SLURM configuration for eigs, props, genprops, baryons and mesons
#

chromaform="/qcd/work/JLabLQCD/eromero/chromaform-24s/alt_ompi5_gcc14"
chroma="$chromaform/install/chroma-sp-mgproto-qphix-qdpxx-double-nd4-avx512-superbblas-cpu-next/bin/chroma"
chroma_extra_args=" -by 4 -bz 4 -pxy 0 -pxyz 0 -c 8 -sy 1 -sz 1 -minct 1"

redstar="$chromaform/install/redstar-pdf-colorvec-pdf-hadron-cpu-adat-pdf-superbblas"
redstar_corr_graph="$redstar/bin/redstar_corr_graph"
redstar_npt="$redstar/bin/redstar_npt"

adat="$chromaform/install/adat-pdf-superbblas"
dbavg="$adat/bin/dbavg"
dbdisco_vac_sub="$adat/bin/dbdisco_vac_sub"
dbmerge="$adat/bin/dbmerge"
dbutil="$adat/bin/dbutil"

slurm_procs_per_node=8
slurm_cores_per_node=64
slurm_gpus_per_node=8
slurm_sbatch_prologue="#!/bin/bash
#SBATCH -A usertest
#SBATCH -p 24s"

slurm_script_prologue="
. $chromaform/env_extra0.sh
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=8
export SLURM_CPU_BIND=cores
export MY_ARGS=\"\"
srun() {
	scontrol show hostnames \"\${SLURM_JOB_NODELIST}\" > /tmp/nodefile
	mpirun --map-by ppr:${slurm_procs_per_node}:node:PE=\${OMP_NUM_THREADS} --report-bindings -hostfile /tmp/nodefile \"\${@}\"
}
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
. $chromaform_cpu/env_extra0.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=$slurm_threads_per_proc_cpu
"

#
# SLURM configuration for redstar
#

slurm_script_prologue_redstar="
ulimit -c 0 # dissable core dumps
. $chromaform/env_extra0.sh
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=8
export OMP_PLACES=threads
export OMP_PROC_BIND=true
export SB_ANARCHOFS=0
export MY_ARGS=\"\"
"

#
# Options for launch
#

max_jobs=99999 # maximum jobs to be launched
max_hours=2 # maximum hours for a single job

#
# Path options
#
# NOTE: we try to recreate locally the directory structure at jlab; please give consistent paths

confspath="/qcd/work/JLabLQCD/eromero/run_disco/chroma-scripts-cori/data"
this_ep="36d521b3-c182-4071-b7d5-91db5d380d42:scratch/"  # frontier
jlab_ep="a2f9c453-2bb6-4336-919d-f195efcf327b:~/qcd/cache/isoClover/b6p3/" # jlab#gw2
jlab_local="/cache/isoClover/b6p3"
jlab_tape_registry="/mss/lattice/isoClover/b6p3"
jlab_user="$USER"
jlab_ssh="ssh qcdi1402.jlab.org"
