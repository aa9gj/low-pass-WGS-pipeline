#!/bin/bash
#SBATCH --job-name=apply_bqsr             # Job name
#SBATCH --output=out # Output file (%A: array master job ID, %a: array task ID)
#SBATCH --error=err  # Error file (%A: array master job ID, %a: array task ID)
#SBATCH --array=1-40%5              # Array range; run 4 a time due to the extensive temp files
#SBATCH --ntasks=1                          # Number of tasks
#SBATCH --cpus-per-task=8                   # Number of CPU cores per task
#SBATCH -t 21-00:00:00                     # Time limit hrs:min:sec
#SBATCH --mem=64G                           # Memory limit

ml java/17.0.9
# Path to the reference genome
ref="PATH/TO/genome.fa"

# Get BAM file path for this task from the bam_list.txt
bam_file=$(sed -n "${SLURM_ARRAY_TASK_ID}p" bam_list.txt)
sample_name=$(basename "${bam_file}" | cut -d '_' -f 1)
gatk ApplyBQSR -I ${bam_file} -R ${ref} --bqsr-recal-file ${sample_name}_recal_data.table -O ${sample_name}_sorted_dedup_bqsr_reads.bam

echo "Finished processing ${bam_file}"
