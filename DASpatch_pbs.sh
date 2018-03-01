#!/bin/sh
db="$1"

# ... so we can loop over the remaining filenames (1 or more) on the command line
for filename in $(find . -type f -name "*.*.las"); do
  #cat << EOF
  qsub <<EOF
#!/bin/bash -l

#PBS -N DASpatch
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=10G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

cd "\$PBS_O_WORKDIR"

source activate thegenemyers

DASpatch -v $db $filename

EOF

done
