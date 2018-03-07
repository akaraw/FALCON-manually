#!/usr/bin/env python
import functional
import click

@click.command()
@click.option('--genome_size', type=float, default=20, help='Desired coverage ratio (i.e. over-sampling)')
@click.option('--coverage', type=int, help='Estimated number of bases in genome. (haploid?)')
@click.option('--db_stats', help='File with captured output of DBstats. DBstats -b1 DB_NAME > DBstats.out')
def main(genome_size, coverage, db_stats):
    target = int(genome_size * coverage)
    capture = open(db_stats)
    stats = capture.read()

    print functional.calc_cutoff(target, stats)


if __name__ == '__main__':
    main()
