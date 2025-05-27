#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --output=multiqc_%j.out
#SBATCH --error=multiqc_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

# Load MultiQC module
module load multiqc

# Run MultiQC on the FastQC reports
multiqc fastqc_results -o multiqc_results
