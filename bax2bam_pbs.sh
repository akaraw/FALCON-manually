#!/bin/bash

for i in $(ls -d /work/waterhouse_team/All_RawData/Each_Cell_Raw/RSII_SMRT*/Analysis_Results); 
do
  cd $i
  baxs=($(find . -type f -name "*.bax.h5"))
 
  #cat <<EOF
  qsub <<EOF
#!/bin/bash -l

#PBS -N bax2bam
#PBS -l walltime=50:00:00
#PBS -j oe
#PBS -l mem=20G
#PBS -l ncpus=2
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

source /work/waterhouse_team/apps/pacbio/setup-env.sh
cd $i;

bax2bam ${baxs[@]} -o ${baxs[0]%%.[0-9].bax.h5} --subread

EOF

done
