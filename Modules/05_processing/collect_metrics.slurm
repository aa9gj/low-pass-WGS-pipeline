#!/bin/bash
#SBATCH --job-name=metrics             # Job name
#SBATCH --output=out # Output file (%A: array master job ID, %a: array task ID)
#SBATCH --error=err  # Error file (%A: array master job ID, %a: array task ID)
#SBATCH --array=1-40               # Array range; <MAX_INDEX> is the highest index (0-based)
#SBATCH --ntasks=1                          # Number of tasks
#SBATCH --cpus-per-task=8                   # Number of CPU cores per task
#SBATCH --time=04:00:00                     # Time limit hrs:min:sec
#SBATCH --mem=32G                           # Memory limit
ml java/17.0.9
# Path to the reference genome
ref="PATH/TO/REF.fa"

# Get BAM file path for this task from the bam_list.txt
bam_file=$(sed -n "${SLURM_ARRAY_TASK_ID}p" bam.list.txt)

# Extract sample name from BAM file name (adjust as needed)
sample_name=$(basename "${bam_file}" | cut -d '_' -f 1)

# Directory to save the output
output_dir=<OUTPUT-DIR>

# Run GATK CollectAlignmentSummaryMetrics
gatk CollectAlignmentSummaryMetrics \
    R=${ref} \
    I=${bam_file} \
    O=${output_dir}/${sample_name}_alignment_metrics.txt

echo "Finished processing ${bam_file}"
