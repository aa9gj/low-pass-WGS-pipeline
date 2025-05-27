#!/bin/bash
#SBATCH --job-name=fastqc_array
#SBATCH --output=fastqc_array_%A_%a.out
#SBATCH --error=fastqc_array_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-<MAX-N>

module load fastqc

mkdir -p fastqc_results

# Get the correct line from the list based on SLURM_ARRAY_TASK_ID
FILE_LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)

# Split the line into two files: R1 and R2
set -- $FILE_LINE
R1=$1
R2=$2

# Run FastQC
fastqc -o fastqc_results -t 2 "$R1" "$R2"
