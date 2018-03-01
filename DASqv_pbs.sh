#!/bin/sh
# Source: https://unix.stackexchange.com/a/421328/34872
# use the first 3 arguments for the values to pass to DASqv
db="$1"
H="$2"
cov="$3"

# use shift to get rid of them once we have them in variables, ...
shift 3

# ... so we can loop over the remaining filenames (1 or more) on the command line
for filename in $(find . -type f -name "*.*.las"); do
  outfile="$(basename "$filename" .las).DAStrim"
  qsub <<EOF
#!/bin/bash -l

#PBS -N DASqv
#PBS -l walltime=48:00:00
#PBS -j oe
#PBS -l mem=1G
#PBS -l ncpus=1
#PBS -M m.lorenc@qut.edu.au
##PBS -m bea

cd "\$PBS_O_WORKDIR"

source activate thegenemyers

DASqv -v -H"$H" -c"$cov" "$db" "$filename" | 
  sed -n -e "/Recommend/ { s/Recommend //;
                           s/'//g;
                           s:$: $db $filename:;
                           p }" > "$outfile"


EOF

done
