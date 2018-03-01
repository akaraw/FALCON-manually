#!/bin/bash -l

#PBS -N DASedit
#PBS -l walltime=150:00:00
#PBS -j oe
#PBS -l mem=25G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

cd $PBS_O_WORKDIR

source activate thegenemyers

DASedit -v preassemblyDB preassemblyDB-DASedit
