#!/bin/bash

confs="`seq 1000 10 2310`"
#confs="`seq 1000 10 1310`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050"
ensemble="cl21_48_96_b6p3_m0p2416_m0p2050"
tag="cl21_48_96_b6p3_m0p2416_m0p2050"
t_sources="`seq 0 24 95`"
t_seps="4 6 8 10 12 14"
zphase="0.00"

confs="`seq 100 10 860`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-1000"
ensemble="cl21_48_96_b6p3_m0p2416_m0p2050"

confs="`seq 100 10 950`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-1200"
ensemble="cl21_48_96_b6p3_m0p2416_m0p2050"

confs="`seq 2430 10 5410`"
confsprefix="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams/cl21_48_96_b6p3_m0p2416_m0p2050"
confsname="cl21_48_96_b6p3_m0p2416_m0p2050"
tag="cl21_48_96_b6p3_m0p2416_m0p2050-djm-streams"
ensemble="cl21_48_96_b6p3_m0p2416_m0p2050"

s_size=48 # lattice spatial size
t_size=96 # lattice temporal size
max_nvec=128 # number of eigenvector computed
nvec=128 # Number of eigenvectors used to compute perambulators
tagcnf="n$max_nvec"
confspath="$HOME/b6p3"
chromaform="$HOME/chromaform0"
chroma="$chromaform/install/chroma2-quda-qdp-jit-double-nd4/bin/chroma"
chroma_python="$HOME/runs/chroma_python"

this_ep="ef1a9560-7ca1-11e5-992c-22000b96db58:"
jlab_ep="a6fccca2-d1a2-11e5-9a63-22000b96db58:~/qcd/cache/isoClover/"

for t_source in $t_sources; do
   mkdir -p ${confspath}/${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}
done
#for d in cfgs cfgs_mod eigs_mod ; do
#rm -f ${confspath}/${confsprefix}/$d
#ln -s ${origconfspath}/${confsprefix}/$d ${confspath}/${confsprefix}/$d
#done

MG_PARAM_FILE="`mktemp`"
#MGPROTO
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
Blocking		  3,3,4,3:2,2,2,2
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

lime_file="${confspath}/${confsprefix}/cfgs/${confsname}_cfg_${cfg}.lime"
lime_file_pre="${confspath}/${confsprefix}/cfgs/${confsname}_cfg"
[ -f $lime_file ] || continue
gauge_file="${confspath}/${confsprefix}/cfgs_mod/${confsname}.3d.gauge.${tagcnf}.mod${cfg}"
#if [ "X${zphase}X" != XX ]; then
#colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.phased_${zphase}.mod${cfg}"
#colorvec_file_pre="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.phased_${zphase}"
#else
colorvec_file="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}.mod${cfg}"
colorvec_file_pre="${confspath}/${confsprefix}/eigs_mod/${confsname}.3d.eigs.${tagcnf}"
#exit 1
#fi
colorvec_file_dep=""
#colorvec_file_dep="`cat ${runpath}/../run_eigs_${cfg}/run.bash.launched | tr -d '[:blank:]'`"
#if [ -z $colorvec_file_dep ] ; then echo Not found $colorvec_file; continue; fi

t_seps_commas="`echo $t_seps | xargs | tr ' ' ,`"

if [ "X${zphase}X" != XX ]; then
gprop_file_root="${confsprefix}/phased/unsmeared_meson_dbs/d001_${zphase}/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0"
gprop_file_prefix="${confspath}/${gprop_file_root}"
gprop_file="${gprop_file_prefix}.sdb${cfg}"
gprop_file_globus="${confsprefix}/unsmeared_meson_dbs/t0_${t_source}/unsmeared_meson.phased_d001_${zphase}.n${nvec}.${t_source}.tsnk_${t_seps_commas}.Gamma_gt_g5gz_g5gx_g5gy_g5gt_gxgy_gxgz_gxgt_gygz_gygt_gzgt.absDisp000-008.qXYZ_0,0,0.sdb${cfg}"
else
  exit 1
fi

#
# Genprops creation
#

N_COLOR_FILES=1
if [ "X${zphase}X" != XX ]; then
python $chroma_python/unsmeared_hadron_node.py  -c ${cfg} -e ${ensemble} -g ${lime_file_pre} -n ${nvec} -f ${N_COLOR_FILES} -v ${colorvec_file_pre} -t ${t_offset} -k ${t_seps_commas} -p ${gprop_file_prefix} -d "${GDM}" -s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} -i QUDA-MG --genprop5 --phase "0.00 0.00 $zphase"  --max-rhs 1 --multiple-writers --max_tslices_contractions 4 > $runpath/gprop_creation_${t_source}.xml
else
python $chroma_python/unsmeared_hadron_node.py  -c ${cfg} -e ${ensemble} -g ${lime_file_pre} -n ${nvec} -f ${N_COLOR_FILES} -v ${colorvec_file_pre} -t ${t_offset} -k ${t_seps_commas} -p ${gprop_file_prefix} -d "${GDM}" -s MG -a UNSMEARED_HADRON_NODE_DISTILLATION_SUPERB -M ${MG_PARAM_FILE} -i QUDA-MG --genprop5 --max-rhs 1 --multiple-writers --max_tslices_contractions 4 > $runpath/gprop_creation_${t_source}.xml
fi

LT=4
cat << EOF > $runpath/gprop_create_run_${t_source}.sh
#!/bin/bash
#BSUB -P LGT115
#BSUB -W 2:00
#BSUB -nnodes 16
#BSUB -alloc_flags "gpumps smt1"
#BSUB -J gprop-${cfg}-${t_source}
#BSUB -o $runpath/gprop_create_run_${t_source}.out0
#DEPENDENCY $colorvec_file_dep
`
	for (( i=1 ; i<=LT ; i++ )); do
		echo "#CREATE ${gprop_file}"
		echo "#GLOBUS_COPY ${this_ep}${gprop_file}.${i}_outof_$LT ${jlab_ep}${gprop_file_globus}.${i}_outof_$LT"
	done
`
source $chromaform/env.sh
cd $runpath
export SB_LOG=1
export SB_DEBUG=0
export SB_ASYNC_ALLTOALL=0
export OMP_NUM_THREADS=7
export SB_TRACK_MEM=0
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5

rm -f ${gprop_file}.*

echo jsrun -n96 -g1 -r6 -c7 -a1 $chroma -i $runpath/gprop_creation_${t_source}.xml -geom 2 4 3 4 -pool-max-alloc 0 -pool-max-alignment 512 &> $runpath/gprop_create_run_${t_source}.out
jsrun -n96 -g1 -r6 -c7 -a1 $chroma -i $runpath/gprop_creation_${t_source}.xml -geom 2 4 3 4 -pool-max-alloc 0 -pool-max-alignment 512 &>> $runpath/gprop_create_run_${t_source}.out
EOF

done # t_source
done # cfg
