# This shell script is executed at the beginning of create_*.sh, launch.sh, cancel.sh and check.sh

. common.sh

ensembles="ensemble0"

ensemble0() {
	# Tasks to run
	run_eigs="nop"
	run_props="yes"
	run_gprops="yes"
	run_baryons="yes"
	run_mesons="nop"
	run_discos="nop"
	run_redstar="yes"

	run_onthefly="yes"
	onthefly_chroma_minutes=120
	max_moms_per_job=100

	# Ensemble properties
	confsprefix="cl21_48_128_b6p5_m0p2070_m0p1750"
	ensemble="cl21_48_128_b6p5_m0p2070_m0p1750"
	confsname="cl21_48_128_b6p5_m0p2070_m0p1750"
	tag="cl21_48_128_b6p5_m0p2070_m0p1750"
	confs="`seq 1010 30 2000`"
	confs="1010"
	confs="${confs//1250/}"
	s_size=48 # lattice spatial size
	t_size=128 # lattice temporal size

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
	prop_create_if_missing="nop"
	prop_t_fwd=18
	prop_t_back=0
	prop_nvec=128
	prop_zphases="0.00 2.00 -2.00"
	prop_zphases="0.00"
	prop_mass="-0.2070"
	prop_clov="1.170082389372972"
	prop_mass_label="U${prop_mass}"
	prop_slurm_nodes=3
	prop_chroma_geometry="1 1 3 8"
	prop_chroma_minutes=120
	prop_max_rhs=1
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
              <RsdTarget>1e-7</RsdTarget>
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
	prop_inv_nop="
              <invType>MGPROTON</invType>

              <type>eo</type>
              <solver>
                <type>mr</type>
                <tol>1e-8</tol>
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
					echo "afs:${n}.part_$node"
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
	gprop_t_seps="4 6 8 10 12 14 16"
	max_tseps_per_job=4
	gprop_zphases="${prop_zphases}"
	gprop_nvec=$prop_nvec
	gprop_moms="0 0 0"
	gprop_moms="`echo "$gprop_moms" | while read mx my mz; do echo "$mx $my $mz"; echo "$(( -mx )) $(( -my )) $(( -mz ))"; done | sort -u`"
	gprop_max_rhs=$prop_max_rhs
	gprop_max_tslices_in_contraction=1
	gprop_max_mom_in_contraction=1
	gprop_slurm_nodes="${prop_slurm_nodes}"
	gprop_chroma_geometry="${prop_chroma_geometry}"
	gprop_chroma_minutes=120
	localpath="/mnt/bb/$USER"
	gprop_file_name() {
		local t_seps_commas="`echo $tseps | xargs | tr ' ' ,`"
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
	meson_nvec=$prop_nvec
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
	baryon_nvec=$prop_nvec
	baryon_zphases="${prop_zphases}"
	baryon_chroma_max_tslices_in_contraction=1 # as large as possible
	baryon_chroma_max_moms_in_contraction=4 # as large as possible (zero means do all momenta at once)
	baryon_chroma_max_vecs=32 # as large as possible (zero means do all eigenvectors are contracted at once)
	baryon_slurm_nodes=3
	baryon_chroma_geometry="1 1 3 8"
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
					echo "afs:${n}.part_$node"
				done
			fi
		else
			echo $n
		fi
	}
	baryon_transfer_back="nop"
	baryon_delete_after_transfer_back="nop"
	baryon_transfer_from_jlab="nop"
	redstar_op_bases=3
	baryon_extra_xml="
        <!-- List of displacement arrays -->
        <displacement_list>
          <elem><left>0</left><middle>0</middle><right>0</right></elem>

	$( [ $redstar_op_bases == 3 -o $redstar_op_bases == all ] && echo "
          <elem><left>0</left><middle>0</middle><right>1 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 2</right></elem>
          <elem><left>0</left><middle>0</middle><right>1 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2 3</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 1</right></elem>
          <elem><left>0</left><middle>0</middle><right>3 2</right></elem>" )
	$( [ $redstar_op_bases == all ] && echo "
          <elem><left>0</left><middle>0</middle><right>1</right></elem>
          <elem><left>0</left><middle>0</middle><right>2</right></elem>
          <elem><left>0</left><middle>0</middle><right>3</right></elem>
          <elem><left>0</left><middle>1</middle><right>1</right></elem>
          <elem><left>0</left><middle>1</middle><right>2</right></elem>
          <elem><left>0</left><middle>1</middle><right>3</right></elem>
          <elem><left>0</left><middle>2</middle><right>2</right></elem>
          <elem><left>0</left><middle>2</middle><right>3</right></elem>
          <elem><left>0</left><middle>3</middle><right>3</right></elem>" )
        </displacement_list>
"

	# Disco options
	disco_max_displacement=8
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
	redstar_t_corr=16 # Number of time slices
	redstar_nvec=$prop_nvec
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
	redstar_3pt_snkmom_srcmom="$( for (( z=-3 ; z<=3 ; ++z )) do echo "0 0 $z 0 0 $z" ; done )"
	redstar_2pt_moms="$(
		echo "$redstar_3pt_snkmom_srcmom" | while read m0 m1 m2 m3 m4 m5 ; do
			echo $m0 $m1 $m2
			echo $m3 $m4 $m5
		done | sort -u
)"
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
		echo "too lazy"; return -1
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
		local prefix_path="z${zphase}"
		[ ${zphase} == 0.00 ] && prefix_path="unphased"
		local prefix_path_extra="_2pt"
		[ ${redstar_3pt} == yes ] && prefix_path_extra="_3pt"
		local tsep_extra=""
		[ ${redstar_3pt} == yes ] && tsep_extra="_tsep${tsep}"
		local ins_path=""
		[ $t_source != avg ] && ins_path="/ins_${insertion_op}_tsep_${tsep}"
		echo "${confspath}/${confsprefix}/corr/${prefix_path}${prefix_path_extra}/t0_${t_source}${ins_path}/$( rename_moms $mom )/${confsname}.nuc_local.n${redstar_nvec}.tsrc_${t_source}_ins${insertion_op}${redstar_tag}.mom_${mom// /_}_z${zphase}${tsep_extra}.sdb${cfg}"
	}
	redstar_slurm_nodes=3
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
chroma="$chromaform/install/chroma-sp-qdpxx-double-nd4-superbblas-hip-next/bin/chroma"
chroma="$chromaform/install/chroma-sp-quda-qdp-jit-double-nd4-cmake-superbblas-hip-next/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512  -libdevice-path /opt/rocm-6.0.0/llvm/lib"

redstar="$chromaform/install-redstar/redstar-pdf-colorvec-pdf-hadron-hip-adat-pdf-superbblas-sp"
redstar_corr_graph="$redstar/bin/redstar_corr_graph"
redstar_npt="$redstar/bin/redstar_npt"

adat="$chromaform/install-redstar/adat-pdf-superbblas-sp"
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
#SBATCH --gpu-bind=none
#SBATCH -C nvme"

slurm_script_prologue="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=$(( slurm_cores_per_node/slurm_gpus_per_node - 1))
export SLURM_CPU_BIND=\"cores\"
export SB_MPI_GPU=1
export SB_CACHEGB_GPU=60
export MPICH_GPU_SUPPORT_ENABLED=1
export SB_MPI_NONBLOCK=0
#export SB_NUM_GPUS_ON_NODE=1
export MPICH_GPU_IPC_CACHE_MAX_SIZE=1
export QUDA_ENABLE_P2P=0
export QUDA_ENABLE_GDR=0
export QUDA_ENABLE_NVSHMEM=0
export QUDA_ENABLE_MPS=0
"

#
# SLURM configuration for redstar
#

slurm_script_prologue_redstar="
. $chromaform/env.sh
. $chromaform/env_extra0.sh
export OPENBLAS_NUM_THREADS=1
export SLURM_CPU_BIND=\"cores\"
export OMP_NUM_THREADS=$(( slurm_cores_per_node/slurm_gpus_per_node - 2))
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
