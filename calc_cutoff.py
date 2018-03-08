#!/usr/bin/env python
import functional
import click
from Bio import SeqIO


def parse_genome_size(genome_size_str):
    #source: https://github.com/rrwick/DASCRUBBER_wrapper GPL
    genome_size_str = genome_size_str.lower()
    try:
        last_char = genome_size_str[-1]
        if last_char == 'g':
            value_str = genome_size_str[:-1]
            multiplier = 1000000000
        elif last_char == 'm':
            value_str = genome_size_str[:-1]
            multiplier = 1000000
        elif last_char == 'k':
            value_str = genome_size_str[:-1]
            multiplier = 1000
        else:
            value_str = genome_size_str
            multiplier = 1
        if '.' in value_str:
            genome_size = int(round(float(value_str) * multiplier))
        else:
            genome_size = int(value_str) * multiplier
    except (ValueError, IndexError):
        sys.exit('Error: could not parse genome size')
    if genome_size < 1:
        sys.exit('Error: genome size must be a positive value')
    elif genome_size < 100:
        print_warning('genome size is very small (' + int_to_str(genome_size) + ' bases). '
                      'Did you mean to use a suffix (G, M, k)?')
    elif genome_size > 100000000000:
        print_warning('genome size is very large (' + int_to_str(genome_size) + ' bases). '
                      'Is that a mistake?')
    return genome_size

def calc_coverage(genome_size, fasta_fofn_file):
    seq_lengths = 0
    with open(fasta_fofn_file) as f:
        for line in f:
            #seq_lengths = [len(i) for i in SeqIO.parse(line.strip(), "fasta")]
            for seq_record in SeqIO.parse(line.strip(), "fasta"):
                seq_lengths += len(seq_record)

    coverage = float(seq_lengths) / genome_size

    return coverage

@click.command()
@click.option('--genome_size', type=str, help='Estimated genome size (examples: 2G, 5.6M or 900k)')
@click.option('--fofn', type=str, help='File contains the path of all FASTA files (fasta2DB_input.fofn')
@click.option('--db_stats', help='File with captured output of DBstats. DBstats -b1 DB_NAME > DBstats.out')
def main(genome_size, fofn, db_stats):
    genome_size_formated = parse_genome_size(genome_size)
    coverage = calc_coverage(genome_size_formated, fofn)
    target = int(genome_size_formated * coverage)
    capture = open(db_stats)
    stats = capture.read()

    print genome_size_formated
    print coverage
    print functional.calc_cutoff(target, stats)


if __name__ == '__main__':
    main()
