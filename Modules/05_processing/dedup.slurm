#!/bin/bash
#SBATCH --job-name=gatk_markdup             # Job name
#SBATCH --output=out # Output file (%A: array master job ID, %a: array task ID)
#SBATCH --error=err  # Error file (%A: array master job ID, %a: array task ID)
#SBATCH --array=1-40%5              # Array range; run 4 a time due to the extensive temp files
#SBATCH --ntasks=1                          # Number of tasks
#SBATCH --cpus-per-task=8                   # Number of CPU cores per task
#SBATCH -t 21-00:00:00                     # Time limit hrs:min:sec
#SBATCH --mem=64G                           # Memory limit

ml java/17.0.9

# Define directories
ALIGNED_READS="PATH/TO/alignment_bwa/"
FILE_LIST="${ALIGNED_READS}/sam_file_list.txt"

# Create output directory if it doesn't exist
OUTPUT_DIR="${ALIGNED_READS}/deduplicated"
mkdir -p "$OUTPUT_DIR"

# Extract the SAM file for this array task
SAM_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

# Extract sample name
sample_name=$(basename "$SAM_FILE" .sam)

# Define the output BAM file name
output_bam="${OUTPUT_DIR}/${sample_name}_sorted_dedup_reads.bam"

# Run GATK MarkDuplicatesSpark
gatk MarkDuplicatesSpark -I "${ALIGNED_READS}/${SAM_FILE}" -O "$output_bam" --tmp-dir .
