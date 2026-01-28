#!/bin/bash
#SBATCH --job-name=bwa_mem_array
#SBATCH --output=logs/bwa_align_%A_%a.out
#SBATCH --error=logs/bwa_align_%A_%a.err
#SBATCH --array=1-40                         # Update to match your sample count
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=10:00:00
#SBATCH --mem=32G

# =============================================================================
# BWA MEM Alignment Script
# Aligns paired-end FASTQ files to reference genome using BWA-MEM
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
PARENT_DIR="/path/to/fastq/directory"        # Directory containing FASTQ files
REF_GENOME="/path/to/reference/genome.fa"    # Reference genome (must be indexed)
OUTPUT_DIR="/path/to/output/alignment"       # Output directory for SAM files
FILE_LIST="fastq_file_pairs.txt"             # Tab-delimited: R1<tab>R2

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting BWA alignment job"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Create output and log directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Navigate to the parent directory
cd "$PARENT_DIR" || { log_error "Cannot access directory: $PARENT_DIR"; exit 1; }

# Validate inputs
if [[ ! -f "$FILE_LIST" ]]; then
    log_error "File list not found: $FILE_LIST"
    exit 1
fi

if [[ ! -f "${REF_GENOME}.bwt" ]] && [[ ! -f "${REF_GENOME}.0123" ]]; then
    log_error "BWA index not found for: $REF_GENOME"
    exit 1
fi

# Validate array job
if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
# Extract the R1 and R2 file names for this array task
R1=$(awk "NR==$SLURM_ARRAY_TASK_ID {print \$1}" "$FILE_LIST")
R2=$(awk "NR==$SLURM_ARRAY_TASK_ID {print \$2}" "$FILE_LIST")

if [[ -z "$R1" ]] || [[ -z "$R2" ]]; then
    log_error "Could not extract R1/R2 for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

# Validate FASTQ files exist
for fq in "$R1" "$R2"; do
    if [[ ! -f "$fq" ]]; then
        log_error "FASTQ file not found: $fq"
        exit 1
    fi
done

# Derive sample name from R1 filename
sample_name=$(basename "$R1" _R1.fastq.gz)
log_info "Processing sample: $sample_name"

# Define the output SAM file name
output_sam="$OUTPUT_DIR/${sample_name}.sam"

# Run BWA MEM
log_info "Running BWA MEM alignment..."
bwa mem -t 8 "$REF_GENOME" \
    -R "@RG\tID:${sample_name}\tPL:ILLUMINA\tSM:${sample_name}" \
    "$R1" "$R2" > "$output_sam"

# Validate output
if [[ ! -s "$output_sam" ]]; then
    log_error "Output SAM file is empty or missing: $output_sam"
    exit 1
fi

log_info "Alignment completed successfully: $output_sam"
