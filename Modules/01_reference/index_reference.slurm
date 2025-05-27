#!/bin/bash
#SBATCH --job-name=index_ref
#SBATCH --output=index_ref_%j.out
#SBATCH --error=index_ref_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2

# Load required modules (adjust if your system uses conda or different modules)
module load picard
module load samtools
module load bwa

# Reference file name
REF=<genome.fa>

# 1. Create the .dict file 
picard CreateSequenceDictionary R=$REF O=${REF%.fa}.dict

# 2. Create the .fai index
samtools faidx $REF

# 3. Create BWA index files
bwa index $REF

echo "All reference indexes generated."
