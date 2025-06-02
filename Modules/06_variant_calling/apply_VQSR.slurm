#!/bin/bash
#SBATCH --job-name=select_SNPs_VQSR
#SBATCH --output=select_SNPs_VQSR.out
#SBATCH --error=select_SNPs_VQSR.err
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00


ml java/17.0.9

REF=REF.fa
JOINTVCF=joint_calls.vcf.gz
RESOURCE_VCF=known_sites.vcf

gatk --java-options "-Xmx28g" ApplyVQSR \
    -R "$REF" \
    -V joint_calls.snps.vcf.gz \
    -O joint_calls.snps.filtered.vcf.gz \
    --recal-file joint.snps.recal \
    --tranches-file joint.snps.tranches \
    -mode SNP \
    --truth-sensitivity-filter-level 99.0 # You can adjust this value based on your tranches plot
