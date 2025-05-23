#!/bin/bash

#SBATCH --job-name=flagstat_array
#SBATCH --output=flagstat_%A_%a.out
#SBATCH --error=flagstat_%A_%a.err
#SBATCH --array=0-40
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

# Directories
BAM_DIR="<BAM-sorted-DIR"
OUT_DIR="flagstat_out"

# Make output directory if needed
mkdir -p "${OUT_DIR}"

# Get list of BAM files
BAM_FILES=(${BAM_DIR}/*sorted.bam)

# Select file for this array task
BAM_FILE="${BAM_FILES[$SLURM_ARRAY_TASK_ID]}"
BAM_BASENAME=$(basename "${BAM_FILE}" .bam)

# Run samtools flagstat
samtools flagstat "${BAM_FILE}" > "${OUT_DIR}/${BAM_BASENAME}.flagstat.txt"
