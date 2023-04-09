# This shell script is executed at the beginning of create_*.sh, launch.sh, cancel.sh and check.sh

ensembles="ensemble0"

ensemble0() {
	# Tasks to run
	run_eigs="nop"
	run_props="nop"
	run_gprops="nop"
	run_baryons="yes"
	run_mesons="nop"
	run_redstar="nop"

	# Ensemble properties
	confsprefix="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
	ensemble="cl21_32_64_b6p3_m0p2350_m0p2050"
	confsname="cl21_32_64_b6p3_m0p2350_m0p2050"
	tag="cl21_32_64_b6p3_m0p2350_m0p2050-5162"
	confs="`seq 11000 10 13990`"
	confs="`seq 11000 10 12000`"
	s_size=32 # lattice spatial size
	t_size=64 # lattice temporal size

	# configuration filename
	lime_file_name() { echo "${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"; }

	# Colorvecs options
	max_nvec=128  # colorvecs to compute
	nvec=64  # colorvecs to use
	eigs_smear_rho=0.08 # smearing factor
	eigs_smear_steps=10 # smearing steps
	# colorvec filename
	colorvec_file_name() { echo "${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.n${max_nvec}.mod${cfg}"; }
	eigs_transfer_back="yes"
	eigs_delete_after_transfer_back="nop"

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
	prop_delete_after_transfer_back="yes"

	# Genprops options
	gprop_t_sources="0 16 32 48"
	gprop_t_seps="4 6 8 10 12 14"
	gprop_zphases="0.00 2.00"
	gprop_file_name() {
		if [ $zphase == 0.00 ]; then
			echo "${confspath}/${confsprefix}/unsmeared_meson_dbs/t0_${t_source}/unsmeared_meson.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
		fi
	}
	gprop_transfer_back="yes"
	gprop_delete_after_transfer_back="yes"

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
	baryon_zphases="0.00"
	baryon_file_name() {
		if [ ${zphase} == 0.00 ]; then
			echo "${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).sdb${cfg}"
		else
			echo "${confspath}/${confsprefix}/baryon_db/${confsname}.n${nvec}.m2_0_0.baryon.colorvec.t_0_$((t_size-1)).phased_${zphase}.sdb${cfg}"
		fi
	}
	baryon_transfer_back="yes"
	baryon_delete_after_transfer_back="nop"
}

confspath="$SCRATCH/b6p3"

chromaform="$HOME/hadron/chromaform-perlmutter"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-cmake-superbblas-cuda/bin/chroma"
chroma_extra_args="-pool-max-alloc 0 -pool-max-alignment 512"

chroma_python="$HOME/hadron/runs-eloy/chroma_python"

slurm_sbatch_prologue="#!/bin/bash
#SBATCH -A hadron_g
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH --gpu-bind=none
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --gpus-per-task=1"

slurm_script_prologue="
. $chromaform/env.sh
. $chromaform/env_extra.sh
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=32
export SLURM_CPU_BIND=\"cores\"
"

max_jobs=20 # maximum jobs to be launched
max_hours=5 # maximum hours for a single job

PYTHON=python3
this_ep="6bdc7956-fc0f-4ad2-989c-7aa5ee643a79:${SCRATCH}/b6p3/"  # perlmutter
jlab_ep="a2f9c453-2bb6-4336-919d-f195efcf327b:~/qcd/cache/isoClover/" # jlab#gw2
