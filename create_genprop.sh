#!/bin/bash

source ensembles.sh

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
	lowDispBound=8 # EXCLUSIVE!
	minX=0
	minY=0
	#minZ=$(( $lowDispBound + 1 ))
	minZ=0
	maxX=0
	maxY=0
	maxZ=8
	threeMom="0,0,0" # momentum transfer
	gammas="gt g5gz g5gx g5gy g5gt gxgy gxgz gxgt gygz gygt gzgt"
	disps="+z,$maxZ -z,$maxZ none"
	gdm=""
	prettyGDM=""
	for g in $gammas; do
		prettyGDM="${prettyGDM}${g}_"
		for d in $disps; do
			gdm="$gdm;$g:$d:$threeMom"
		done
	done
	GDM=`echo $gdm | cut -b 2-`

	for cfg in $confs; do
		lime_file="`lime_file_name`"
		colorvec_file="`colorvec_file_name`"
		[ -f $lime_file ] || continue

		runpath="$PWD/${tag}/conf_${cfg}"
		mkdir -p $runpath

		for t_source in $gprop_t_sources; do
		for zphase in $gprop_zphases; do

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
			mkdir -p `dirname ${gprop_file}`

			#
			# Genprops creation
			#

			N_COLOR_FILES=1
			gprop_xml="$runpath/gprop_t${t_source}_z${zphase}.xml"
			mkdir -p `dirname ${gprop_xml}`
			$PYTHON $chroma_python/unsmeared_hadron_node.py  -c 1000 -e ${ensemble} -g flime -n ${gprop_nvec} -f ${N_COLOR_FILES} -v fcolorvec -t ${t_offset} -k ${t_seps_commas} -p fgprop -d "${GDM}" -s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} -i QUDA-MG --phase "0.00 0.00 $zphase" --max-rhs 1 --max_tslices_contractions 16 --genprop5 --genprop5-format | sed "s@flime_1000.lime@${lime_file}@; s@fcolorvec.mod1000@${colorvec_file}@; s@fgprop.sdb1000@${gprop_file}@" > $gprop_xml

			output="$runpath/gprop_t${t_source}_z${zphase}.out"
			cat << EOF > $runpath/gprop_t${t_source}_z${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/gprop_t${t_source}_z${zphase}.out0
#SBATCH -t $gprop_chroma_minutes
#SBATCH --nodes=$gprop_slurm_nodes
#SBATCH -J gprop-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f ${gprop_file}*
	srun -n $(( slurm_procs_per_node*gprop_slurm_nodes )) -N $gprop_slurm_nodes \$MY_ARGS $chroma -i ${gprop_xml} -geom $gprop_chroma_geometry $chroma_extra_args &> $output
}

check() {
	grep -q "CHROMA: ran successfully" 2>&1 ${output} > /dev/null && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $gprop_file
}

class() {
	# class max_minutes nodes jobs_per_node
	echo b $gprop_chroma_minutes $gprop_slurm_nodes 1
}

globus() {
	[ $gprop_transfer_back == yes ] && echo ${gprop_file}.globus ${this_ep}${gprop_file#${confspath}} ${jlab_ep}${gprop_file#${confspath}} ${gprop_delete_after_transfer_back}
}

eval "\${1:-run}"
EOF

		done # t_source
		done # zphase
	done # cfg
done # ens
