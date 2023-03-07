#!/bin/bash

source ensembles.sh

for ens in $ensembles; do
	# Load the variables from the function
	eval "$ens"

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
		lime_file_name="`lime_file_name`"
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
			gprop_file_prefix="${prop_file%.sdb*}"

			#
			# Genprops creation
			#

			N_COLOR_FILES=1
			gprop_xml="$runpath/gprop_t${t_source}_z${zphase}.xml"
			mkdir -p `dirname ${gprop_xml}`
			$PYTHON $chroma_python/unsmeared_hadron_node.py  -c ${cfg} -e ${ensemble} -g ${lime_file_pre} -n ${nvec} -f ${N_COLOR_FILES} -v ${colorvec_file_pre} -t ${t_offset} -k ${t_seps_commas} -p ${gprop_file_prefix} -d "${GDM}" -s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} -i QUDA-MG --phase "0.00 0.00 $zphase" --max-rhs 1 --max_tslices_contractions 16 --genprop5 --genprop4-format > $gprop_xml

			output="$runpath/gprop_t${t_source}_z${zphase}.out"
			cat << EOF > $runpath/gprop_t${t_source}_z${zphase}.sh
$slurm_sbatch_prologue
#SBATCH -o $runpath/gprop_t${t_source}_z${zphase}.out0
#SBATCH -t 0:40:00
#SBATCH --nodes=2
#SBATCH --gpus-per-task=1
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J gprop-${cfg}-${t_source}

run() {
	$slurm_script_prologue
	cd $runpath
	rm -f ${gprop_file}*
	srun $chroma -i ${gprop_xml} -geom 1 2 2 2 $chroma_extra_args &> $output
}

check() {
	grep -q "FINISHED chroma" ${output} && exit 0
	exit 1
}

deps() {
	echo $lime_file $colorvec_file
}

outs() {
	echo $gprop_file
}

class() {
	# class max_minutes nodes
	echo b 600 1
}

globus() {
	[ $gprop_transfer_back == yes ] && echo ${this_ep}$gprop_file ${jlab_ep}/${gprop_file#${confspath}}
}

eval "\${1:-run}"
EOF

		done # t_source
		done # zphase
	done # cfg
done # ens
