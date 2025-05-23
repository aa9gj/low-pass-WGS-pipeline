#!/bin/bash
#SBATCH --job-name=merge_index_jointvcf
#SBATCH --output=merge_index_jointvcf.out
#SBATCH --error=merge_index_jointvcf.err
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --time=06:00:00

# Load modules if your cluster needs them:
# module load bcftools
# module load htslib

VCF_DIR=<VCF-DIR-Path>
cd $VCF_DIR

# List all chrom VCFs in correct order. Adjust as needed!
VCFLIST="chr1.vcf.gz chr2.vcf.gz chr3.vcf.gz chr4.vcf.gz chr5.vcf.gz chr6.vcf.gz chr7.vcf.gz chr8.vcf.gz chr9.vcf.gz chr10.vcf.gz chr11.vcf.gz chr12.vcf.gz chr13.vcf.gz chr14.vcf.gz chr15.vcf.gz chr16.vcf.gz chr17.vcf.gz chr18.vcf.gz chr19.vcf.gz chr20.vcf.gz chr21.vcf.gz chr22.vcf.gz chr23.vcf.gz chr24.vcf.gz chr25.vcf.gz chr26.vcf.gz chr27.vcf.gz chr28.vcf.gz chr29.vcf.gz chr30.vcf.gz chr31.vcf.gz chr32.vcf.gz chr33.vcf.gz chr34.vcf.gz chr35.vcf.gz chr36.vcf.gz chr37.vcf.gz chr38.vcf.gz chrX.vcf.gz"

# Merge all chromosome VCFs into a single joint callset
bcftools concat -a -O z -o joint_calls.vcf.gz $VCFLIST

# Index the merged VCF
tabix -p vcf joint_calls.vcf.gz
