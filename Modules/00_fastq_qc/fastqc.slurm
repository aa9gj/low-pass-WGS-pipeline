#!/bin/bash
#SBATCH --job-name=fastqc_array
#SBATCH --output=logs/fastqc_%A_%a.out
#SBATCH --error=logs/fastqc_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-40                         # Update to match your sample count

# =============================================================================
# FastQC Quality Control Script
# Runs FastQC on paired-end FASTQ files
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SAMPLE_LIST="samples.txt"                    # Tab-delimited: R1<tab>R2
OUTPUT_DIR="fastqc_results"

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting FastQC job"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Load module
module load fastqc || log_info "Module load skipped"

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$SAMPLE_LIST" ]]; then
    log_error "Sample list not found: $SAMPLE_LIST"
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
# Get the correct line from the list
FILE_LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [[ -z "$FILE_LINE" ]]; then
    log_error "Could not extract file line for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

# Split the line into R1 and R2
# shellcheck disable=SC2086
set -- $FILE_LINE
R1="${1:-}"
R2="${2:-}"

if [[ -z "$R1" ]] || [[ -z "$R2" ]]; then
    log_error "Could not parse R1/R2 from: $FILE_LINE"
    exit 1
fi

# Validate files exist
for fq in "$R1" "$R2"; do
    if [[ ! -f "$fq" ]]; then
        log_error "FASTQ file not found: $fq"
        exit 1
    fi
done

log_info "Processing: $R1, $R2"

# Run FastQC
fastqc -o "$OUTPUT_DIR" -t 2 "$R1" "$R2"

log_info "FastQC completed successfully"
