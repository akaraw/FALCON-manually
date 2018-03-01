#!/bin/bash

for i in $(find /work/waterhouse_team/All_RawData/Each_Cell_Raw -type f -name "*.subreads.bam"); 
do
  dir=$(dirname $i)
  fn=$(basename $i)
 
  #cat <<EOF
  qsub <<EOF
#!/bin/bash -l

#PBS -N dextractor
#PBS -l walltime=10:00:00
#PBS -j oe
#PBS -l mem=1G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

cd $dir;

source activate thegenemyers

dextract -fa -o${fn%.bam} $fn

EOF

done
