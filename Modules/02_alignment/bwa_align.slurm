#!/bin/bash
#SBATCH --job-name=bwa_mem_array             # Job name
#SBATCH --output=out                         # Output file (%A: master job ID, %a: array job ID)
#SBATCH --error=err                          # Error file (%A: master job ID, %a: array job ID)
#SBATCH --array=1-<MAX_INDEX>                # Array range; <MAX_INDEX> is the highest index
#SBATCH --ntasks=1                           # Number of tasks
#SBATCH --cpus-per-task=8                    # Number of CPU cores per task
#SBATCH --time=10:00:00                      # Time limit hrs:min:sec
#SBATCH --mem=32G                            # Memory limit

# Define directories
PARENT_DIR="<PATH>"
REF_GENOME="<PATH_TO_REFERENCE_INDEX>"
OUTPUT_DIR="<PATH>"
FILE_LIST="fastq_file_pairs.txt"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Navigate to the parent directory
cd "$PARENT_DIR" || exit

# Extract the R1 and R2 file names for this array task
R1=$(awk "NR==$SLURM_ARRAY_TASK_ID {print \$1}" "$FILE_LIST")
R2=$(awk "NR==$SLURM_ARRAY_TASK_ID {print \$2}" "$FILE_LIST")

# Derive sample name from R1 filename (e.g., HPET104-0001)
sample_name=$(basename "$R1" _R1.fastq.gz)

# Define the output SAM file name
output_sam="$OUTPUT_DIR/${sample_name}.sam"

# Run BWA MEM and output to a SAM file
bwa mem -t 8 "$REF_GENOME" -R "@RG\tID:${sample_name}\tPL:ILLUMINA\tSM:${sample_name}" "$R1" "$R2" > "$output_sam"
