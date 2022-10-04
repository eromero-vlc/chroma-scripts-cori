#!/bin/bash

confs="`seq 3590 10 5420`"
confsprefix="cl21_32_64_b6p3_m0p2390_m0p2050"
confsname="cl21_32_64_b6p3_m0p2390_m0p2050"
ensemble="cl21_32_64_b6p3_m0p2390_m0p2050"
tag="cl21_32_64_b6p3_m0p2390_m0p2050"

s_size=32 # lattice spatial size
t_size=64 # lattice temporal size


t_sources="0 16 32 48"
t_seps="4 6 8 10 12 14"
zphase="-2.00"

max_nvec=64 # number of eigenvector computed
nvec=64  # number of eigenvectors
tagcnf="n$max_nvec"
confspath="/mnt/tier2/project/p200054/cache/b6p3"
chromaform="/mnt/tier2/project/p200054/chromaform"
chroma="$chromaform/install/chroma-quda-qdp-jit-double-nd4-superbblas-cuda/bin/chroma"
chroma_python="/mnt/tier2/project/p200054//chroma_python"

this_ep="9d6d99eb-6d04-11e5-ba46-22000b92c6ec:"
this_ep="dcb5f28c-dadf-11eb-8324-45cc1b8ccd4a:"
jlab_ep="a6fccca2-d1a2-11e5-9a63-22000b96db58:~/qcd/cache/isoClover/"

for t_source in $t_sources; do
   mkdir -p ${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}
done

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

runpath="$PWD/${tag}/run_gprop_${zphase}-$cfg"
mkdir -p $runpath

for t_source in $t_sources; do

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

lime_file="`ls ${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime*`"
lime_file_noref="${lime_file%.ref????}"
ref="${lime_file#${lime_file_noref}}"
lime_file_pre="${confspath}/${confsprefix}/cfgs/${confsname}_cfg"
[ -f $lime_file ] || continue
#if [ "X${zphase}X" != XX ]; then
#colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.phased_${zphase}.mod${cfg}"
#colorvec_file_pre="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.phased_${zphase}"
#else
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.mod${cfg}${ref}"
colorvec_file_pre="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs"
#exit 1
#fi
colorvec_file_dep=""
#colorvec_file_dep="`cat ${runpath}/../run_eigs_${cfg}/run.bash.launched | tr -d '[:blank:]'`"
#if [ -z $colorvec_file_dep ] ; then echo Not found $colorvec_file; continue; fi

t_seps_commas="`echo $t_seps | xargs | tr ' ' ,`"

if [ "X${zphase}X" != XX ]; then
gprop_file_root="${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0"
gprop_file_prefix="${confspath}/${gprop_file_root}"
gprop_file="${gprop_file_prefix}.sdb${cfg}${ref}"
else
  exit 1
fi

#
# Genprops creation
#

N_COLOR_FILES=1
python3 $chroma_python/unsmeared_hadron_node.py  -c ${cfg} -e ${ensemble} -g ${lime_file_pre} -n ${nvec} -f ${N_COLOR_FILES} -v ${colorvec_file_pre} -t ${t_offset} -k ${t_seps_commas} -p ${gprop_file_prefix} -d "${GDM}" -s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} -i QUDA-MG --phase "0.00 0.00 $zphase"  --max-rhs 1 --max_tslices_contractions 16 --reflectionBinary ${ref#.ref} --genprop5 --genprop4-format > $runpath/gprop_creation_${t_source}.xml

LT=4
cat << EOF > $runpath/gprop_create_run_${t_source}.sh
#!/bin/bash -l
#SBATCH -o $runpath/gprop_create_run_${t_source}.out0
#SBATCH --account=p200054
#SBATCH -t 0:40:00
#SBATCH --nodes=2
#SBATCH --gpus-per-task=1
#SBATCH -p gpu -q short
#SBATCH --ntasks-per-node=4 # number of tasks per node
#SBATCH --cpus-per-task=32 # number of cores per task
#SBATCH -J prop-${cfg}-${t_source}

cd $runpath
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=12
export CUDA_VISIBLE_DEVICES="0,1,2,3"
export GPU_DEVICE_ORDINAL="0,1,2,3"
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$chromaform/install/llvm/lib

rm -f ${gprop_file}*
. $chromaform/env.sh

srun $chroma -i $runpath/gprop_creation_${t_source}.xml -geom 1 2 2 2 -pool-max-alloc 0 -pool-max-alignment 512 -libdevice-path /apps/USE/easybuild/release/2021.3/software/CUDA/11.4.2/nvvm/libdevice &> $runpath/gprop_create_run_${t_source}.out
EOF

done # t_source
done # cfg
