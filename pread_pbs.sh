#!/bin/bash
db=preassemblyDB-DASedit
H=6973
for i in $(find . -type f -name "*DASedit.*.las"); 
do
  #cat <<EOF
  qsub <<EOF
#!/bin/bash -l

#PBS -N preads
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=80G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

source activate thegenemyers
cd /work/waterhouse_team/apps/FALCON-integrate/
source env.sh
export PATH=/work/waterhouse_team/apps/FALCON-integrate/fc_env/bin:$PATH

cd \$PBS_O_WORKDIR
LA4Falcon -fo -H$H $db $i | fc_consensus --output_multi --n_core 1 > ${i}.preads.fasta

EOF

done
