# FALCON-manually
For users who can't get PacBio's [FALCON](https://github.com/PacificBiosciences/FALCON-integrate) assembler running on their cluster

## Setup

### Install Gene Myers' tools
Those tools can be found [here](https://github.com/thegenemyers). Easier way to install them is with help of [bioconda](https://github.com/bioconda/bioconda-recipes) `conda install damasker daligner dascrubber dazz_db dextractor`

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
fasta2DB bananaDB -ffasta2DB_input.fofn

DBsplit -x500 -s250 bananaDB
DBdust bananaDB
```

### Commands to check each result
```
grep "ill" <job_output>.o*                             # check whether no jobs have been killed
grep "Mem" <job_output>.o* | cut -d':' -f3 | sort -    # Memory usage
grep "CPU" <job_output>.o* | cut -d" " -f5 | sort -    # Time usage
```

## PREASSEMBLY 


### TANmask
```
source activate thegenemyers
HPC.TANmask bananaDB -mdust -T4 -fTANmask
sh HPC.parallel_pbs.sh TANmask.01.OVL             #MEM:9GB; CPU time:00:06:25
sh HPC.parallel_pbs.sh TANmask.02.CHECK.OPT       #MEM:0.3GB; CPU time:00:00:02
sh HPC.parallel_pbs.sh TANmask.03.MASK            #MEM:0.4GB; CPU time:00:00:01  
sh TANmask.04.RM
qsub catrackTAN_pbs.sh
#      Catrack -v bananaDB tan
#      rm .bananaDB.*.tan.*
PBS Job 2678948.pbs
CPU time  : 00:00:01
Wall time : 00:00:11
Mem usage : 8164kb
```

## HPC.REPmask
```
source activate thegenemyers
HPC.REPmask -g1 -c20 -mdust -mtan bananaDB -T4 -fREPmask
sh HPC.parallel_pbs.sh REPmask.01.OVL           #MEM:30GB; CPU time:02:00:01
sh HPC.parallel_pbs.sh REPmask.02.CHECK.OPT     #MEM:1.4GB; CPU time:00:00:03
sh HPC.parallel_pbs.sh REPmask.03.MASK          #MEM:0.01GB; CPU time:00:00:06
sh REPmask.04.RM
Catrack -v bananaDB rep1
rm .bananaDB.*.rep1.*
```

## HPC.daligner
```
source activate thegenemyers
DBstats -b1 -mdust -mtan -mrep1 bananaDB > DBstats.out

/work/waterhouse_team/apps/bin> python  calc_cutoff.py --genome_size 1800000000 --coverage 38 --db_stats
/work/waterhouse_team/banana/assembly/DBstats.out
6973

HPC.daligner -mdust -mtan -mrep1 -H6973 -T4 -fdaligner bananaDB   
sh HPC.parallel_pbs.sh daligner.01.OVL        #MEM:22GB; CPU time:01:12:00
sh HPC.parallel_pbs.sh daligner.02.CHECK.OPT  #MEM:0.001GB; CPU time:00:00:08
sh HPC.parallel_pbs.sh daligner.03.MERGE      #MEM:3GB; CPU time:00:00:06
sh HPC.parallel_pbs.sh daligner.04.CHECK.OPT  #MEM:1.3GB; CPU time:00:00:08
sh daligner.05.RM.OPT  
sh HPC.parallel_pbs.sh daligner.06.MERGE      #MEM:4GB; CPU time:00:00:09
sh HPC.parallel_pbs.sh daligner.07.CHECK.OPT  #MEM:1.3GB; CPU time:00:00:09
sh daligner.08.RM

```

# DASCRUBBER
```
./DASqv_pbs.sh bananaDB 6973 38               #MEM:0.5GB; CPU time:00:00:19
Catrack -v bananaDB qual
rm .bananaDB.*.qual.*
```

```
find . -name "*.DAStrim" -type f -exec cat {} + > DAStrim-cmds
sh HPC.parallel_pbs.sh DAStrim-cmds           #MEM:1.1GB; CPU time:00:00:26
Catrack -v bananaDB trim  
```

```
sh DASpatch_pbs.sh bananaDB                 #MEM:1.4GB; CPU time:00:00:16
Catrack -v bananaDB patch  
```

```
qsub DASedit_pbs.sh                         #MEM:0.9GB; CPU time:02:04:50

```

```

```
## HPC.daligner with DASedit DB
```
source activate thegenemyers
DBstats -b1 bananaDB-DASedit > DBstats.out

HPC.daligner -H6973 -T4 -fdalignerDASedit bananaDB-DASedit   
sh HPC.parallel_pbs.sh dalignerDASedit.01.OVL        #MEM:24GB; CPU time:05:17:29
sh HPC.parallel_pbs.sh dalignerDASedit.02.CHECK.OPT        #MEM:0.001GB; CPU time:00:00:08
sh HPC.parallel_pbs.sh dalignerDASedit.03.MERGE            #MEM:5GB; CPU time:00:02:00
sh HPC.parallel_pbs.sh dalignerDASedit.04.CHECK.OPT        #MEM:1.3GB; CPU time:00:04:00
sh dalignerDASedit.06.MERGE  
sh HPC.parallel_pbs.sh dalignerDASedit.06.MERGE            #MEM:4GB; CPU time:00:04:00
sh HPC.parallel_pbs.sh dalignerDASedit.07.CHECK.OPT       #MEM:1.3GB; CPU time:00:04:00
sh dalignerDASedit.08.RM

```

##LA4FALCON
I would recommend against "falcon sense greedy" if your haplotypes are similar. "falcon sense skip contained" is rarely used except in particular cases. Therefore: use 'fo.' (https://github.com/PacificBiosciences/FALCON/issues/606#issuecomment-365724325)

use `--stream` from LA4Falcon, instead of slurping all at once; can save memory for large data

```
sh pread_pbs.sh                                         #MEM:80GB; CPU time:10:03:32
```




LA4Falcon -H2000 -fo $pre.new.db bac.new.$i.las|  fc_consensus.py
--output_full --min_idt 0.70 --min_cov 5 --min_cov_aln 0 --max_n_read 200
--n_core 4  > $pre.new.$i.las.untrimmed.fa

bash_cutoff = '$(python2.7 -m falcon_kit.mains.calc_cutoff --coverage {} {} <(DBstats -b1 {}))'.format(
params['seed_coverage'], params['genome_size'], db_fn)


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

## ASSEMBLY

### Create a new dazzler DB from the preads.fasta file and DBsplit the database
```
source activate thegenemyers
find . -name "*.las.preads.fasta" -type f > assemblyDB_input.fofn
fasta2DB assemblyDB -fassemblyDB_input.fofn

DBsplit -x500 -s250 assemblyDB
DBdust assemblyDB
Catrack -v assemblyDB dust
Catrack: Track file ./.assemblyDB.dust.anno already exists!  ????
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

### Filter overlaps
`overlap_filtering_setting = --max_diff 100 --max_cov 100 --min_cov 1 --bestn 10 --n_core 4`

Future development:
```
rule auto_filter:
    input: "preads4falcon.fasta"
    output: "_preads.ovl"
    run:
        if os.path.isfile("preads.ovl"):
            shell("rm preads.ovl")
        nreads=0
        ccov=0
        with open(input[0]) as f:
            for l in f:
                if l.startswith('>'):
                    nreads+=1
                else:
                    ccov+=len(l.strip())
        cov=int(ccov/estgensize)
        fdr=10
        cdf=0
        for i in range(0,cov+100):
            cdf+=(math.e**(-cov)*(cov**i))/math.factorial(i)
            if (1-cdf)*nreads<=fdr:
                max_cov=i
                min_cov=cov-(max_cov-cov) if cov-(max_cov-cov)>0 else 0
                max_diff=max_cov-min_cov
                break
        else:
            print("filter parameters could not be calculated due to low coverage, not filtering!")
            return

        if os.path.getsize("preads_lasfiles_local.fofn")>0:
            shell("python2 `which fc_ovlp_filter` --db {subject}_preads --fofn preads_lasfiles_local.fofn --max_diff {max_diff} --max_cov {max_cov} --min_cov {min_cov} --bestn 10 --n_core 24 > preads.ovl")
        else:
            shell("touch preads.ovl")

        print("Pread coverage depth: %s" % cov)
        print("Pread cum. read length: %s" % ccov)
        print("Number of preads: %s" % nreads)
        print("max_cov",max_cov)
        print("max_diff",max_diff)
        print("min_cov",min_cov)
```

######### compare preads vs preads_stream
use `--stream` from LA4Falcon, instead of slurping all at once; can save memory for large data
```
find . -name "assemblyDB.*.las" -type f > preads_lasfiles.fofn
qsub fc_ovlp_filter.sh                                    ???#MEM:153688792kb; CPU time:121:22:46
```
or

```
sh fc_ovlp_filter_hpc.sh
sh fc_ovlp_filter_pbs.sh fc_ovlp_filter_cmds.txt          ???#MEM:55340412kb; CPU time:00:28:35
cat preads.*.ovl > preads.ovl  ???
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
`time python -m falcon_kit.mains.ovlp_to_graph {fc_ovlp_to_graph_option} --overlap-file preads.ovl >| fc_ovlp_to_graph.log`

```
qsub fc_ovlp_to_graph_pbs.sh                              ???#MEM:7070664kb; CPU time:00:07:39
```

### Output data in dazzler database to preads4falcon.fasta
DB2Falcon generates automatically `preads4falcon.fasta`
```
qsub DB2Falcon_pbs.sh                                     ???#MEM:7070664kb; CPU time:00:01:54
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
qsub fc_graph_to_contig_pbs.sh

```



-----
PBS Job 2905124.pbs
CPU time  : 00:18:53
Wall time : 00:19:00
Mem usage : 33032488kb


## Acknoledment

* https://github.com/rrwick/DASCRUBBER-wrapper (also for Nano)
* https://github.com/thiesgehrmann/FungalAssemblerPipeline

