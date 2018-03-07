#!/usr/bin/env python

# usage: python auto.py --genome_size 1800000000

import math
import click

@click.command()
@click.option('--genome_size', type=float, help='estimate genome size')
def main(genome_size):
    nreads=0
    ccov=0
    with open("preads4falcon.fasta") as f:
        for l in f:
            if l.startswith('>'):
                nreads+=1
            else:
                ccov+=len(l.strip())
    cov=int(ccov/genome_size)
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
            exit("filter parameters could not be calculated due to low coverage, not filtering!")

#        if os.path.getsize("preads_lasfiles_local.fofn")>0:
#            shell("python2 `which fc_ovlp_filter` --db {subject}_preads --fofn preads_lasfiles_local.fofn --max_diff {max_diff} --max_cov {max_cov} --min_cov {min_cov} --bestn 10 --n_core 24 > preads.ovl")

    print("Pread coverage depth: %s" % cov)
    print("Pread cum. read length: %s" % ccov)
    print("Number of preads: %s" % nreads)
    print("max_cov",max_cov)
    print("max_diff",max_diff)
    print("min_cov",min_cov)

if __name__ == '__main__':
    main()
