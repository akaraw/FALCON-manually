# FALCON-manually
For users who can't get PacBio's [FALCON](https://github.com/PacificBiosciences/FALCON-integrate) assembler running on their cluster

## Setup

### Install Gene Myers' tools and some Python libraries 
Those tools can be found [here](https://github.com/thegenemyers). Easier way to install them is with help of [bioconda](https://github.com/bioconda/bioconda-recipes) `conda install damasker daligner dascrubber dazz_db dextractor biopython click data_hacks`

### Install Falcon-integrate
```
module load gcc/4.9.3-2.25      #(Require at least gcc 4.9)
git clone https://github.com/PacificBiosciences/FALCON-integrate.git
cd FALCON-integrate
find . -type f -print0 | xargs -0 sed -i.bak 's|git:|https:|g'
git submodule sync
git submodule update --init --recursive --remote
make init
source env.sh
make config-edit-user
make -j all
make test
```

### Custom scripts

`cp calc_cutoff.py seq_length.py <your path>/FALCON-integrate/FALCON/falcon_kit/`

### Convert RSII format to Sequel format
```
qsub bax2bam_pbs.sh         #Adjust the PATH inside the script
```

### Convert BAM format to FASTA and Arrow format
```
qsub bam2fasta_pbs.sh       #Adjust the PATH inside the script
```

### Create database
```
source activate thegenemyers
find /work/waterhouse_team/All_RawData/Each_Cell_Raw/ -name "*.arrow" -type f > fasta2DB_input.fofn
sed -i.bak 's|.arrow|.fasta|g' fasta2DB_input.fofn
fasta2DB preassemblyDB -ffasta2DB_input.fofn

DBsplit -x500 -s250 preassemblyDB
DBdust preassemblyDB
```

### Commands to check each result
```
grep "ill" <job_output>.o*                             # check whether no jobs have been killed
grep "Mem" <job_output>.o* | cut -d':' -f3 | sort -    # Memory usage
grep "CPU" <job_output>.o* | cut -d" " -f5 | sort -    # Time usage
```

## PREASSEMBLY 
### Damasker: The Dazzler Repeat Masking Suite
#### TANmask - Finding tandem repeats
```
source activate thegenemyers
HPC.TANmask preassemblyDB -mdust -T4 -fTANmask
sh HPC.parallel_pbs.sh TANmask.01.OVL             #MEM:9GB; CPU time:00:06:25
sh HPC.parallel_pbs.sh TANmask.02.CHECK.OPT       #MEM:0.3GB; CPU time:00:00:02
sh HPC.parallel_pbs.sh TANmask.03.MASK            #MEM:0.4GB; CPU time:00:00:01  
sh TANmask.04.RM
Catrack -v preassemblyDB tan
rm .preassemblyDB.*.tan.*
```

#### REPmask - Masking repeats
REPmask will be given a repeat threshold, relative to the overall depth (e.g. if 3, then regions with 3x the base depth are considered repeats. `c = coverage * 3 = 58 * 3 = 174` [source](https://github.com/rrwick/DASCRUBBER-wrapper/blob/master/dascrubber_wrapper.py#L116)

```
source activate thegenemyers
HPC.REPmask -g1 -c174 -mdust -mtan preassemblyDB -T4 -fREPmask
sh HPC.parallel_pbs.sh REPmask.01.OVL           #MEM:30GB; CPU time:02:00:01
sh HPC.parallel_pbs.sh REPmask.02.CHECK.OPT     #MEM:1.4GB; CPU time:00:00:03
sh HPC.parallel_pbs.sh REPmask.03.MASK          #MEM:0.01GB; CPU time:00:00:06
sh REPmask.04.RM
Catrack -v preassemblyDB rep1
rm .preassemblyDB.*.rep1.*
```

### HPC.daligner - Read overlap alignment with daligner (with repeat masking)
```
source activate thegenemyers
```
```
DBstats -b1 -mdust -mtan -mrep1 preassemblyDB > DBstats.out

python  <your path>/FALCON-integrate/FALCON/falcon_kit/calc_cutoff.py --genome_size 1.8G --db_stats DBstats.out
6973
```

In case `calc_cutoff.py` provided a warning that not enough bases are available you could choose the `H` value with help of the below histogram:

```
xargs cat < fasta2DB_input.fofn >> allPacBio.fasta

python /work/waterhouse_team/banana/assembly/qc/seq_length.py allPacBio.fasta | cut -f 2 | histogram.py --percentage -B 100,200,300,400,500,1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000,13000,14000,15000,16000,17000,18000,19000,20000,25000,30000,35000,40000,45000,50000,55000,60000,65000,70000,75000,80000,85000,90001 > allPacBio_histogram.txt

less allPacBio_histogram.txt

# NumSamples = 12472585; Min = 500.00; Max = 82508.00
# Mean = 8465.980366; Variance = 29451586.395049; SD = 5426.931582; Median 8071.000000
# each ∎ represents a count of 13507
  500.0000 -   500.0000 [   705]:  (0.01%)
  500.0000 -  1000.0000 [385058]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (3.09%)
 1000.0000 -  2000.0000 [1013071]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (8.12%)
 2000.0000 -  3000.0000 [943488]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (7.56%)
 3000.0000 -  4000.0000 [800818]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (6.42%)
 4000.0000 -  5000.0000 [815184]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (6.54%)
 5000.0000 -  6000.0000 [785206]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (6.30%)
 6000.0000 -  7000.0000 [738391]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (5.92%)
 7000.0000 -  8000.0000 [704700]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (5.65%)
 8000.0000 -  9000.0000 [725012]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (5.81%)
 9000.0000 - 10000.0000 [810799]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (6.50%)
10000.0000 - 11000.0000 [915613]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (7.34%)
11000.0000 - 12000.0000 [856007]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (6.86%)
12000.0000 - 13000.0000 [683033]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (5.48%)
13000.0000 - 14000.0000 [523801]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (4.20%)
14000.0000 - 15000.0000 [402690]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (3.23%)
15000.0000 - 16000.0000 [311128]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (2.49%)
16000.0000 - 17000.0000 [241817]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (1.94%)
17000.0000 - 18000.0000 [186554]: ∎∎∎∎∎∎∎∎∎∎∎∎∎ (1.50%)
18000.0000 - 19000.0000 [142382]: ∎∎∎∎∎∎∎∎∎∎ (1.14%)
19000.0000 - 20000.0000 [110041]: ∎∎∎∎∎∎∎∎ (0.88%)
20000.0000 - 25000.0000 [274829]: ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎ (2.20%)
25000.0000 - 30000.0000 [ 76372]: ∎∎∎∎∎ (0.61%)
30000.0000 - 35000.0000 [ 20326]: ∎ (0.16%)
35000.0000 - 40000.0000 [  4733]:  (0.04%)
40000.0000 - 45000.0000 [   697]:  (0.01%)
45000.0000 - 50000.0000 [   114]:  (0.00%)
50000.0000 - 55000.0000 [    14]:  (0.00%)
55000.0000 - 60000.0000 [     0]:  (0.00%)
60000.0000 - 65000.0000 [     0]:  (0.00%)
65000.0000 - 70000.0000 [     0]:  (0.00%)
70000.0000 - 75000.0000 [     0]:  (0.00%)
75000.0000 - 80000.0000 [     1]:  (0.00%)
80000.0000 - 82508.0000 [     1]:  (0.00%)
```
```
HPC.daligner -mdust -mtan -mrep1 -H6973 -T4 -fdaligner preassemblyDB   
sh HPC.parallel_pbs.sh daligner.01.OVL        #MEM:22GB; CPU time:01:12:00
sh HPC.parallel_pbs.sh daligner.02.CHECK.OPT  #MEM:0.001GB; CPU time:00:00:08
sh HPC.parallel_pbs.sh daligner.03.MERGE      #MEM:3GB; CPU time:00:00:06
sh HPC.parallel_pbs.sh daligner.04.CHECK.OPT  #MEM:1.3GB; CPU time:00:00:08
sh daligner.05.RM.OPT  
sh HPC.parallel_pbs.sh daligner.06.MERGE      #MEM:4GB; CPU time:00:00:09
sh HPC.parallel_pbs.sh daligner.07.CHECK.OPT  #MEM:1.3GB; CPU time:00:00:09
sh daligner.08.RM
```

### Dascrubber: The Dazzler Read Scrubbing Suite
#### DASqv - Finding intrinsic quality values
```
./DASqv_pbs.sh preassemblyDB 6973 38                #MEM:0.5GB; CPU time:00:00:19
Catrack -v preassemblyDB qual
rm .preassemblyDB.*.qual.*
```
#### DAStrim - Trimming reads and breaking chimeras 
```
find . -name "*.DAStrim" -type f -exec cat {} + > DAStrim-cmds
sh HPC.parallel_pbs.sh DAStrim-cmds                 #MEM:1.1GB; CPU time:00:00:26
Catrack -v preassemblyDB trim  
```

#### DASpatch - Patching low quality segments 
```
sh DASpatch_pbs.sh preassemblyDB                    #MEM:1.4GB; CPU time:00:00:16
Catrack -v preassemblyDB patch  
```

#### DASedit - Building new database of scrubbed reads 
```
qsub DASedit_pbs.sh                                 #MEM:0.9GB; CPU time:02:04:50
```

#### HPC.daligner with DASedit DB
```
source activate thegenemyers
HPC.daligner -H6973 -T4 -fdalignerDASedit preassemblyDB-DASedit   
sh HPC.parallel_pbs.sh dalignerDASedit.01.OVL               #MEM:24GB; CPU time:05:17:29
sh HPC.parallel_pbs.sh dalignerDASedit.02.CHECK.OPT         #MEM:0.001GB; CPU time:00:00:08
sh HPC.parallel_pbs.sh dalignerDASedit.03.MERGE             #MEM:5GB; CPU time:00:02:00
sh HPC.parallel_pbs.sh dalignerDASedit.04.CHECK.OPT         #MEM:1.3GB; CPU time:00:04:00
sh dalignerDASedit.06.MERGE  
sh HPC.parallel_pbs.sh dalignerDASedit.06.MERGE             #MEM:4GB; CPU time:00:04:00
sh HPC.parallel_pbs.sh dalignerDASedit.07.CHECK.OPT         #MEM:1.3GB; CPU time:00:04:00
sh dalignerDASedit.08.RM
```

### LA4FALCON
@skingan *"recommend against "falcon sense greedy" (`fog`) if your haplotypes are similar. "falcon sense skip contained" ('fso') is rarely used except in particular cases. Therefore: use 'fo.'"* [source](https://github.com/PacificBiosciences/FALCON/issues/606#issuecomment-365724325)

Below is code snippet how FALCON handle this tast:
```
LA4Falcon_flags = 'P' if params.get('LA4Falcon_preload') else ''
    if config["falcon_sense_skip_contained"]:
        LA4Falcon_flags += 'fso'
    elif config["falcon_sense_greedy"]:
        LA4Falcon_flags += 'fog'
    else:
        LA4Falcon_flags += 'fo'
    if LA4Falcon_flags:
LA4Falcon_flags = '-' + ''.join(set(LA4Falcon_flags))

falcon_sense_option = --output_multi --min_idt 0.70 --min_cov 4 --max_n_read 200 --n_core 6
LA4Falcon -H$CUTOFF %s {db_fn} {las_fn} | python -m falcon_kit.mains.consensus {falcon_sense_option} >| {out_file_bfn}" % LA4Falcon_flags
```

Here is the script how I ran it:
```
sh pread_pbs.sh                                         #MEM:80GB; CPU time:10:03:32
```

## ASSEMBLY

### Create a new dazzler DB from the preads.fasta file and DBsplit the database
```
source activate thegenemyers
find . -name "*.las.preads.fasta" -type f > assemblyDB_input.fofn
fasta2DB assemblyDB -fassemblyDB_input.fofn

DBsplit -x500 -s250 assemblyDB
DBdust assemblyDB
```

### HPCdaligner
```
source activate thegenemyers
HPC.daligner -mdust -H6973 -T4 -fdaligner-assemblyDB assemblyDB   
sh HPC.parallel_pbs.sh daligner-assemblyDB.01.OVL         #MEM:70GB; CPU time:09:44:01
sh HPC.parallel_pbs.sh daligner-assemblyDB.02.CHECK.OPT   #MEM:0.001GB; CPU time:00:00:08
sh HPC.parallel_pbs.sh daligner-assemblyDB.03.MERGE       #MEM:5GB; CPU time:00:03:00
sh HPC.parallel_pbs.sh daligner-assemblyDB.04.CHECK.OPT   #MEM:1.5GB; CPU time:00:03:00
sh daligner-assemblyDB.05.RM.OPT  
```

### Output data in dazzler database to preads4falcon.fasta
DB2Falcon generates automatically `preads4falcon.fasta`
```
qsub DB2Falcon_pbs.sh                                     #MEM:10GB; CPU time:00:01:54
```

### Filter overlaps
`fc_ovlp_filter_auto.py` automatically calculate settings for fc_ovlp_filter or use FALCON example settings e.g. `overlap_filtering_setting = --max_diff 100 --max_cov 100 --min_cov 1 --bestn 10 --n_core 4`

```
find . -name "assemblyDB.*.las" -type f > preads_lasfiles.fofn
qsub fc_ovlp_filter_pbs.sh                                    #MEM:160GB; CPU time:121:22:46
```


Future development:
```
rule stats:
    input: "preads_lasfiles_local.fofn"
    output: "ovlp.stats"
    shell:
        #"fc_ovlp_stats --n_core 24 --fofn {input} --db {subject}_preads.db > ovlp.stats"
        "fc_ovlp_stats --n_core 24 --fofn {input} > ovlp.stats"

rule plot_stats:
    input: "ovlp.stats"
    run:
        from matplotlib import pyplot as plt
        import numpy as np
        _3p=np.array([])
        _5p=np.array([])
        lengths=np.array([])
        with open(input[0]) as stats:
            for l in stats:
                i=l.split()
                np.append(_5p,i[2])
                np.append(_3p,i[3])
                np.append(lengths,i[1])
        plt.hist(_3p,label="3' overlap count")
        plt.hist(_5p,label="5' overlap count")
        plt.title("overlap distribution")
        plt.show()
        plt.clf()
        plt.hist(lengths)
        plt.title("pread length distribution")
        plt.show()
```

### Construct assembly graph
` falcon_kit.mains.ovlp_to_graph {fc_ovlp_to_graph_option}`
```
qsub fc_ovlp_to_graph_pbs.sh                              #MEM:7GB; CPU time:00:07:39
```

### Creating contigs
https://github.com/PacificBiosciences/FALCON/blob/master/falcon_kit/mains/graph_to_contig.py
requires those files:
* c_path
* utg_data
* ctg_paths
* sg_edges_list
* preads4falcon_.fasta

Output is `p_ctg.fa`
```
qsub fc_graph_to_contig_pbs.sh                             #MEM:35GB; CPU time:00:20:00

```


## Acknowledgment
The above pipeline is based on a Snakefile developed by @jasperlinthorst, [DASCRUBBER-wrapper](https://github.com/rrwick/DASCRUBBER-wrapper) developed by @rrwick and some input from @thegenemyers



