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

# Step 1: Select SNPs only from the joint callset (This part is correct)
gatk --java-options "-Xmx28g" SelectVariants -R $REF -V $JOINTVCF --select-type-to-include SNP -O joint_calls.snps.vcf.gz

# Step 2: Run VariantRecalibrator
gatk --java-options "-Xmx28g" VariantRecalibrator -R $REF -V joint_calls.snps.vcf.gz --resource:dog_array_snps,known=false,training=true,truth=true,prior=12.0 $RESOURCE_VCF -an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an MQ -mode SNP -O joint.snps.recal --tranches-file joint.snps.tranches --rscript-file joint.snps.plots.R
