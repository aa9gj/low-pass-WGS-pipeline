#!/bin/bash
#SBATCH --job-name=genoGVCF_chr
#SBATCH --output=genoGVCF_chr_%A_%a.out
#SBATCH --error=genoGVCF_chr_%A_%a.err
#SBATCH --array=1-39                 # Adjust if the number of chromosomes changes
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4            # Adjust as needed
#SBATCH --mem=64G                    # Adjust as needed
#SBATCH --time=99:00:00              # Adjust as needed

ml java/17.0.9

REF=<ref_fasta>
DBDIR=/path/to/genomicsdb

CHROMS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chr30 chr31 chr32 chr33 chr34 chr35 chr36 chr37 chr38 chrX)
CHR=${CHROMS[$((SLURM_ARRAY_TASK_ID-1))]}

OUT_VCF=/path/to/output/genotypes/${CHR}.vcf.gz

mkdir -p $(dirname $OUT_VCF)

gatk --java-options "-Xmx12g" GenotypeGVCFs \
  -R $REF \
  -V gendb://$DBDIR/${CHR} \
  -O $OUT_VCF
