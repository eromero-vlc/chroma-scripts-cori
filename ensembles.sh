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

	# Ensemble properties
	confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
	ensemble="cl21_32_64_b6p3_m0p2350_m0p2050"
	confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
	tag="cl21_32_64_b6p3_m0p2350_m0p2050"
	confs="`seq 5170 10 20070`"
	#confs="`seq 5170 10 5990`"
	#confs="`seq 6000 10 9990`"
	confs="`seq 5170 10 9990`"
	confs="`seq 5170 10 6990`"
	s_size=32 # lattice spatial size
	t_size=64 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }
	lime_transfer_from_jlab="yes"

	# Colorvecs options
	max_nvec=128  # colorvecs to compute
	nvec=128  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${max_nvec}.mod${cfg}"; }
	eigs_slurm_nodes=2
	eigs_chroma_geometry="1 2 2 4"
	eigs_chroma_minutes=600
	eigs_transfer_back="nop"
	eigs_delete_after_transfer_back="nop"
	eigs_transfer_from_jlab="yes"

	# Props options
	prop_t_sources="0 16 32 48"
	prop_t_sources="`seq 0 63`"
	prop_create_if_missing="nop"
	prop_t_fwd=32
	prop_t_back=0
	prop_nvec=128
	prop_zphases="0.00 2.00 -2.00"
	prop_zphases="0.00"
	prop_mass="-0.2350"
	prop_clov="1.20536588031793"
	prop_mass_label="U${prop_mass}"
	prop_slurm_nodes=1
	prop_chroma_geometry="1 1 2 4"
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
	prop_inv="
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
	localpath="/mnt/bb/$USER"
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
	baryon_chroma_max_tslices_in_contraction=1 # as large as possible
	baryon_chroma_max_moms_in_contraction=4 # as large as possible (zero means do all momenta at once)
	baryon_chroma_max_vecs=32 # as large as possible (zero means do all eigenvectors are contracted at once)
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
          <elem><left>0</left><middle>0</middle><right>1 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 3</right></elem>
        </displacement_list>
"

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
	redstar_2pt="yes"
	redstar_2pt_max_mom=3
	redstar_2pt_moms="\
0 0 0
$(
	for i in `seq 1 $redstar_2pt_max_mom`; do
		echo $i 0 0
		echo -$i 0 0
	done
	for i in `seq 1 $redstar_2pt_max_mom`; do
		echo 0 $i 0
		echo 0 -$i 0
	done
	for i in `seq 1 $redstar_2pt_max_mom`; do
		echo 0 0 $i
		echo 0 0 -$i
	done
)"
	redstar_3pt="nop"
	redstar_3pt_snkmom_srcmom="\
1 0 5   0 0 5   
0 1 4   0 0 4   
0 1 5   0 0 5   
0 1 6   0 0 6   
1 0 4   0 0 4   
1 1 5   0 0 5   
1 0 6   0 0 6   
1 1 4   0 0 4   
1 1 4   0 1 4   
1 1 4   1 0 4   
1 1 6   1 0 6   
1 1 5   0 1 5   
1 1 5   1 0 5   
1 1 6   0 0 6   
1 1 6   0 1 6   
2 0 4   1 0 4   
2 0 5   1 0 5   
2 0 6   1 0 6"
#	redstar_2pt_moms="$(
#		echo $redstar_3pt_snkmom_srcmom | while read m0 m1 m2 m3 m4 m5 ; do
#			echo $m0 $m1 $m2
#			echo $m3 $m4 $m5
#		done | sort -u
#)"
	redstar_disco="nop" # contracting for disco
	redstar_000="NucleonMG1g1MxD0J0S_J1o2_G1g1 NucleonMG1g1MxD2J1M_J1o2_G1g1 NucleonMHg1SxD2J1M_J1o2_G1g1"
	redstar_n00="NucleonMG1g1MxD0J0S_J1o2_H1o2D4E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D4E1 NucleonMHg1SxD2J1M_J1o2_H1o2D4E1"
	redstar_nn0="NucleonMG1g1MxD0J0S_J1o2_H1o2D2E NucleonMG1g1MxD0J0S_J1o2_H1o2D2E NucleonMG1g1MxD2J1M_J1o2_H1o2D2E NucleonMHg1SxD2J1M_J1o2_H1o2D2E"
	redstar_nnn="NucleonMG1g1MxD0J0S_J1o2_H1o2D3E1 NucleonMG1g1MxD2J1M_J1o2_H1o2D3E1 NucleonMHg1SxD2J1M_J1o2_H1o2D3E1"
	redstar_nm0="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nm0E NucleonMG1g1MxD2J1M_J1o2_H1o2C4nm0E NucleonMHg1SxD2J1M_J1o2_H1o2C4nm0E"
	redstar_nnm="NucleonMG1g1MxD0J0S_J1o2_H1o2C4nnmE NucleonMG1g1MxD2J1M_J1o2_H1o2C4nnmE NucleonMHg1SxD2J1M_J1o2_H1o2C4nnmE"
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
	rename_moms() {
		[ $# == 3 ] && echo "mom$1.$2.$3"
		[ $# == 6 ] && echo "snk$1.$2.$3src$4.$5.$6"
	}
	corr_file_name() {
		if [ ${zphase} == 0.00 ]; then
			if [ $t_source == avg ]; then
				echo "${confspath}/${confsprefix}/corr/unphased_2pt_disco/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			else
				echo "${confspath}/${confsprefix}/corr/unphased_2pt_disco/t0_${t_source}/ins_${insertion_op}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			fi
		else
			if [ $t_source == avg ]; then
				echo "${confspath}/${confsprefix}/corr/z${zphase}-2pt/t0_${t_source}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			else
				echo "${confspath}/${confsprefix}/corr/z${zphase}-2pt/t0_${t_source}/ins_${insertion_op}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}.sdb${cfg}"
			fi
		fi
	}
	redstar_slurm_nodes=1
	redstar_minutes=30
	redstar_jobs_per_node=8 # use for computing corr graphs
	redstar_max_concurrent_jobs=24000
	redstar_transfer_back="nop"
	redstar_delete_after_transfer_back="nop"
	redstar_transfer_from_jlab="nop"

	globus_check_dirs="${confspath}/${confsprefix}/corr-none"
}

chroma_python="$PWD/chroma_python"
PYTHON=python3

#
# SLURM configuration for eigs, props, genprops, baryons and mesons
#

chromaform="$HOME/scratch/chromaform_rocm6.1"
chroma="$chromaform/install/chroma-sp-quda-qdp-jit-double-nd4-cmake-superbblas-hip-next/bin/chroma"
chroma="$chromaform/install/chroma-sp-qdpxx-double-nd4-superbblas-hip-next/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512"

redstar="$chromaform/install-redstar-nompi/redstar-pdf-colorvec-pdf-hadron-hip-adat-pdf-superbblas-sp"
redstar_corr_graph="$redstar/bin/redstar_corr_graph"
redstar_npt="$redstar/bin/redstar_npt"

adat="$chromaform/install/adat-pdf-superbblas-sp"
adat="$chromaform/install-dev/adat-pdf-superbblas-sp"
adat="$chromaform/install-redstar-nompi/adat-pdf-superbblas-sp"
dbavg="$adat/bin/dbavg"
dbavgsrc="$adat/bin/dbavgsrc"
dbavg_disco="$adat/bin/dbavg_disco"
dbmerge="$adat/bin/dbmerge"
dbutil="$adat/bin/dbutil"

slurm_procs_per_node=8
slurm_cores_per_node=56
slurm_gpus_per_node=8
slurm_sbatch_prologue="#!/bin/bash
#SBATCH -A NPH122
#SBATCH -p batch
#SBATCH --gpu-bind=closest
#SBATCH -C nvme"

slurm_script_prologue="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=6
export SB_MPI_GPU=1
export SB_CACHEGB_GPU=60
export MPICH_GPU_SUPPORT_ENABLED=1
export SB_MPI_NONBLOCK=0
export SB_NUM_GPUS_ON_NODE=1
export MPICH_GPU_IPC_CACHE_MAX_SIZE=1
"

#
# SLURM configuration for redstar
#

slurm_script_prologue_redstar="
. $chromaform/env.sh
. $chromaform/env_extra0.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=$(( slurm_cores_per_node/slurm_gpus_per_node - 1))
export MPICH_GPU_SUPPORT_ENABLED=0 # gpu-are MPI produces segfaults
"

#
# Options for launch
#

max_jobs=25 # maximum jobs to be launched
max_hours=2 # maximum hours for a single job

#
# Path options
#
# NOTE: we try to recreate locally the directory structure at jlab; please give consistent paths

confspath="$HOME/scratch"
this_ep="36d521b3-c182-4071-b7d5-91db5d380d42:scratch/"  # frontier
jlab_ep="a2f9c453-2bb6-4336-919d-f195efcf327b:~/qcd/cache/isoClover/b6p3/" # jlab#gw2
jlab_local="/cache/isoClover/b6p3"
jlab_tape_registry="/mss/lattice/isoClover/b6p3"
jlab_user="$USER"
jlab_ssh="ssh qcdi1402.jlab.org"
