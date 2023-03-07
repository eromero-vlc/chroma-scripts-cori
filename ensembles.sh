# This shell script is executed at the beginning of create_*.sh, launch.sh, cancel.sh and check.sh

ensembles="ensemble0"

ensemble0() {
	# Tasks to run
	run_eigs="yes"
	run_props="yes"
	run_gprops="yes"
	run_baryons="yes"
	run_mesons="yes"
	run_redstar="yes"

	# Ensemble properties
	confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050_extension/backups/cl21_32_64_b6p3_m0p2350_m0p2050-11200"
	confsname="cl21_32_64_b6p3_m0p2350_m0p2050-11200"
	tag="cl21_32_64_b6p3_m0p2350_m0p2050_extension-backups-11200"
	confs="`seq 11500 10 13620`"
	s_size=32 # lattice spatial size
	t_size=64 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }

	# Colorvecs options
	max_nvec=96  # colorvecs to compute
	nvec=96  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eig/${confsname}_eigen_z0_light.${cfg}.eig"; }
	eigs_transfer_back="yes"

	# Props options
	prop_t_sources="`seq 0 63`"
	prop_t_fwd=64
	prop_t_back=0
	prop_zphases="0.00 2.00"
	prop_mass="-0.2350"
	prop_clov="1.20536588031793"
	prop_mass_label="U-0.2350"
	# propagator filename
	prop_file_name() {
		if [ ${zphase} == 0.00 ]; then
			echo "${confspath}/${confsprefix}/peram/${cfg}/${confsname}_peram_z0_light.${cfg}.T${t_source}.peram"
		else
			echo "${confspath}/${confsprefix}/phased/prop_db/d001_${zphase}/${cfg}/${confsname}.phased_${zphase}.prop.n${nvec}.light.t0_${t_source}.sdb${cfg}"
		fi
	}
	prop_transfer_back="yes"

	# Genprops options
	gprop_t_sources="0 16 32 48"
	gprop_t_seps="4 6 8 10 12 14"
	gprop_zphases="0.00 2.00"
	gprop_file_name() {
		echo "${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
	}
	gprop_transfer_back="yes"

	# Meson options
	meson_zphases="0.00 2.00"
	meson_file_name() {
		if [ ${zphase} == 0.00 ]; then
			echo "${confspath}/${confsprefix}/meson_db/${confsname}.n${nvec}.m2_0_0.meson.colorvec.t_0_$((t_size-1)).sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/meson_db/${confsname}.n${nvec}.m2_0_0.meson.colorvec.t_0_$((t_size-1)).phased_${zphase}.sdb${cfg}"
		fi
	}

	# Baryon options
	baryon_zphases="0.00 2.00"
	baryon_file_name() {
		if [ ${zphase} == 0.00 ]; then
			echo "${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).phased_${zphase}.sdb${cfg}"
		fi
	}
}

confspath="/mnt/tier2/project/p200054/cache/b6p3"

chromaform="/mnt/tier2/project/p200054/chromaform"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-superbblas-cuda/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512"

chroma_python="/mnt/tier2/project/p200054//chroma_python"

slurm_sbatch_prologue="#!/bin/bash -l
#SBATCH --account=p200054
#SBATCH -p gpu -q short"

slurm_script_prologue="
. $chromaform/env.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=12
export CUDA_VISIBLE_DEVICES=\"0,1,2,3\"
"

max_jobs=50 # should be 100
max_hours=20 # should be 24

PYTHON=python
this_ep="dcb5f28c-dadf-11eb-8324-45cc1b8ccd4a:"
jlab_ep="a6fccca2-d1a2-11e5-9a63-22000b96db58:~/qcd/cache/isoClover/"


