#!/bin/bash

#SBATCH --job-name=beagle_impute
#SBATCH --output=./beagle.out
#SBATCH --error=./beagle.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=99:00:00

java -jar beagle.01Mar24.d36.jar /
ref=AutoAndXPAR.Dog10K.phased.vcf.gz/
gt=joint_calls.snps.recalibrated.vcf.gz /
out=canfam4_lpwgs.vcf
