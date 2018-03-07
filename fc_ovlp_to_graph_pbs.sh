#!/bin/bash -l

#PBS -N fc_ovlp_graph
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=80G
#PBS -l ncpus=4
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

source activate thegenemyers
cd /work/waterhouse_team/apps/FALCON-integrate/
source env.sh
export PATH=/work/waterhouse_team/apps/FALCON-integrate/fc_env/bin:$PATH

cd $PBS_O_WORKDIR

fc_ovlp_to_graph --overlap-file preads.ovl --min_len 6973 > fc_ovlp_to_graph.log
