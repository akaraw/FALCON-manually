#!/bin/bash
while IFS='' read -r line || [[ -n "$line" ]]; do
  cmd=$line 

  #cat <<EOF
  qsub <<EOF
#!/bin/bash -l

#PBS -N HPCdaligner
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=80G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
###PBS -m bea   


cd \$PBS_O_WORKDIR

source activate thegenemyers
echo $cmd
$cmd

EOF

done < "$1"
