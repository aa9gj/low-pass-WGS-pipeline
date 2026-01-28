#!/bin/bash
#SBATCH --job-name=gatk_markdup
#SBATCH --output=logs/dedup_%A_%a.out
#SBATCH --error=logs/dedup_%A_%a.err
#SBATCH --array=1-40%5                       # Run 5 at a time due to temp file space
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 21-00:00:00
#SBATCH --mem=64G

# =============================================================================
# Mark Duplicates Script
# Marks duplicate reads using GATK MarkDuplicatesSpark
# Note: Creates large temporary files - ensure sufficient disk space
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
ALIGNED_READS="/path/to/alignment_bwa"       # Directory containing SAM files
FILE_LIST="${ALIGNED_READS}/sam_file_list.txt"
TMP_DIR="${ALIGNED_READS}/tmp"               # Temp directory (needs lots of space)

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting mark duplicates job"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Load required module
module load java/17.0.9 || log_info "Module load skipped"

# Create output and temp directories
OUTPUT_DIR="${ALIGNED_READS}/deduplicated"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TMP_DIR"
mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$FILE_LIST" ]]; then
    log_error "File list not found: $FILE_LIST"
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
# Extract the SAM file for this array task
SAM_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$FILE_LIST")

if [[ -z "$SAM_FILE" ]]; then
    log_error "Could not extract SAM file for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

# Construct full path
SAM_PATH="${ALIGNED_READS}/${SAM_FILE}"
if [[ ! -f "$SAM_PATH" ]]; then
    log_error "SAM file not found: $SAM_PATH"
    exit 1
fi

# Extract sample name
sample_name=$(basename "$SAM_FILE" .sam)
log_info "Processing sample: $sample_name"

# Define output BAM file
output_bam="${OUTPUT_DIR}/${sample_name}_sorted_dedup_reads.bam"

# Run GATK MarkDuplicatesSpark
log_info "Running GATK MarkDuplicatesSpark..."
gatk MarkDuplicatesSpark \
    -I "$SAM_PATH" \
    -O "$output_bam" \
    --tmp-dir "$TMP_DIR"

# Validate output
if [[ ! -s "$output_bam" ]]; then
    log_error "Output BAM file is empty or missing: $output_bam"
    exit 1
fi

log_info "Mark duplicates completed successfully: $output_bam"
