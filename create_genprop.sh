#!/bin/bash

source ensembles.sh

mom_word() {
	echo ${1}_${2}_${3}
}

mom_fly() {
	if [ $1 -ge $4 ]; then
		echo $(( $1-$4 )) $(( $2-$5 )) $(( $3-$6 ))
	else
		echo $(( $4-$1 )) $(( $5-$2 )) $(( $6-$3 ))
	fi
}

unpack_moms() {
	echo $1 $2 $3
	echo $(( -$1 )) $(( -$2 )) $(( -$3 ))
}

k_split() {
	local n i f
	n="$1"
	shift
	i="0"
	for f in "$@" "__last_file__"; do
		if [ $f != "__last_file__" ]; then
			echo -n "$f "
			i="$(( i+1 ))"
			if [ $i == $n ]; then
				i="0"
				echo
			fi
		else
			[ $i != 0 ] && echo
		fi
	done
}

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

	# Check for running genprops
	[ $run_gprops != yes ] && continue

	MG_PARAM_FILE="`mktemp`"
	cat <<EOF > $MG_PARAM_FILE
AntiPeriodicT                 True
MGLevels                      3
Blocking                      4,4,3,3:2,2,2,2
NullVecs                      24:32
NullSolverMaxIters            800:800
NullSolverRsdTarget           5e-6:5e-6
OuterSolverNKrylov            5
OuterSolverRsdTarget          1.0e-7
OuterSolverVerboseP           True
VCyclePreSmootherMaxIters     0:0
VCyclePreSmootherRsdTarget    0.0:0.0
VCyclePostSmootherNKrylov     4:4
VCyclePostSmootherMaxIters    8:13
VCyclePostSmootherRsdTarget   0.06:0.06
VCycleBottomSolverMaxIters    100:100
VCycleBottomSolverNKrylov     8:8
VCycleBottomSolverRsdTarget   0.06:0.06
EOF

	# QUDA
	cat <<EOF > $MG_PARAM_FILE
RsdTarget                 1.0e-7
AntiPeriodicT             True
SolverType                GCR
Blocking		  4,4,4,4:2,2,2,2
NullVectors		  24:32
SmootherType		  CA_GCR:CA_GCR:CA_GCR
SmootherTol               0.25:0.25:0.25
CoarseSolverType	  GCR:CA_GCR
CoarseResidual            0.1:0.1:0.1
Pre-SmootherApplications  0:0
Post-SmootherApplications 8:8
SubspaceSolver            CG:CG
RsdTargetSubspaceCreate   5e-06:5e-06
EOF

	# More genprop crap
	maxZ=8
	gammas="one gx gy gxgy gz   gxgz gygz g5gt gt   gxgt gygt g5gz gzgt g5gy g5gx g5"
	disps="+z,$maxZ -z,$maxZ none"

	moms="all"
	if [ $gprop_are_local == yes ]; then
		moms="`
			echo "$redstar_3pt_srcmom_snkmom" | while read momij; do
				mom_word $( mom_fly $momij )
			done
		`"
	fi
	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do
		for mom_group in $moms; do

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

			t_seps_commas="`echo $gprop_t_seps | xargs | tr ' ' ,`"

			gprop_file="`gprop_file_name`"
			[ $gprop_are_local != yes ] && mkdir -p `dirname ${gprop_file}`

			#
			# Genprops creation
			#
			if [ $gprop_are_local == yes ]; then
				gprop_moms="$( unpack_moms ${mom_group//_/ } )"
			fi
			gdm="`
				for g in $gammas; do
					for d in $disps; do
						echo "$gprop_moms" | while read momx momy momz; do
							echo -n ";$g:$d:$momx,$momy,$momz"
						done
					done
				done
			`"
			GDM="`echo $gdm | cut -b 2-`"
			N_COLOR_FILES=1
			gprop_xml="$runpath/gprop_t${t_source}_z${zphase}.xml"
			mkdir -p `dirname ${gprop_xml}`
			$PYTHON $chroma_python/unsmeared_hadron_node.py \
				-c 1000 -e ${ensemble} -g flime -n ${gprop_nvec} -f ${N_COLOR_FILES} \
				-v fcolorvec -t ${t_offset} -k ${t_seps_commas} -p fgprop -d "${GDM}" \
				-s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} \
				-i QUDA-MG --phase "0.00 0.00 $zphase" --max-rhs 1 --max_tslices_contractions 16 \
				--max_mom_contractions ${gprop_max_mom_in_contraction} --genprop5 --genprop5-format | sed "s@flime_1000.lime@${lime_file}@; s@fcolorvec.mod1000@${colorvec_file}@; s@fgprop.sdb1000@${gprop_file}@" > $gprop_xml

			gprop_class="b"
			redstar_tasks=""
			if [ $gprop_are_local == yes ]; then
				gprop_class="d"
				redstar_tasks="`ls $runpath/redstar_t${t_source}_*_z${zphase}_mf${mom_group}.sh.future`"
			fi
			output="$runpath/gprop_t${t_source}_z${zphase}.out"
			cat << EOF > $runpath/gprop_t${t_source}_z${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/gprop_t${t_source}_z${zphase}.out0
#SBATCH -t $gprop_chroma_minutes
#SBATCH --nodes=$gprop_slurm_nodes -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -c $(( slurm_cores_per_node/slurm_procs_per_node ))
#SBATCH -J gprop-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	[ $gprop_are_local == yes ] && mkdir -p `dirname ${gprop_file}`
	rm -f ${gprop_file}*
	srun -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS $chroma -i ${gprop_xml} -geom $gprop_chroma_geometry $chroma_extra_args &> $output
`
	if [ $gprop_are_local ] ; then
		k_split $(( slurm_procs_per_node*gprop_slurm_nodes )) $redstar_tasks | while read js ; do
			echo "cat << EOFo > /tmp/h"
			i=0
			for j in $js; do
				echo $i $j
				i="$((i+1))"
			done
			echo "EOFo"
			num_jobs="$( echo $js | wc -w )"
			echo srun -n $num_jobs -N $gprop_slurm_nodes \\\$MY_ARGS --multi-prog /tmp/h
		done
	fi
`
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null || exit 1
`
	if [ $gprop_are_local ] ; then
		for t in $redstar_tasks; do
			echo "bash $t check || exit 1"
		done
	fi
`
	exit 0
}

deps() {
	echo $lime_file $colorvec_file
`
	if [ $gprop_are_local ] ; then
		for t in $redstar_tasks; do
			echo bash $t deps
		done
	fi
`
}

outs() {
`
	if [ $gprop_are_local ] ; then
		for t in $redstar_tasks; do
			echo bash $t outs
		done
	else
		echo echo $gprop_file
	fi
`
}

class() {
	# class max_minutes nodes jobs_per_node max_concurrent_jobs
	echo $gprop_class $gprop_chroma_minutes $gprop_slurm_nodes 1 0
}

globus() {
	[ $gprop_transfer_back == yes ] && echo ${gprop_file}.globus ${this_ep}${gprop_file#${confspath}} ${jlab_ep}${gprop_file#${confspath}} ${gprop_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # mom_group
		done # t_source
		done # zphase
	done # cfg
done # ens
