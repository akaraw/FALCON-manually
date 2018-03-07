#!/bin/bash -l

#PBS -N preads
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=160G
#PBS -l ncpus=4
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

source activate thegenemyers
cd /work/waterhouse_team/apps/FALCON-integrate/
source env.sh
export PATH=/work/waterhouse_team/apps/FALCON-integrate/fc_env/bin:$PATH

cd $PBS_O_WORKDIR


fc_ovlp_filter --stream --db assemblyDB --max_diff 100 --max_cov 100 --min_cov 1 --bestn 10 --n_core 4 --fofn preads_lasfiles.fofn --min_len 6973 > preads.ovl
