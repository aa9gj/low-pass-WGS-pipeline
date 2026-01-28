#!/bin/bash
#SBATCH --job-name=flagstat_array
#SBATCH --output=logs/flagstat_%A_%a.out
#SBATCH --error=logs/flagstat_%A_%a.err
#SBATCH --array=1-40                         # Update to match your sample count
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1

# =============================================================================
# Alignment Statistics Script
# Calculates alignment statistics using samtools flagstat
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THIS PATH
# -----------------------------------------------------------------------------
BAM_DIR="/path/to/sorted/bam/files"
OUT_DIR="flagstat_out"
BAM_LIST="bam_list.txt"                      # Optional: list of BAM files

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting alignment statistics calculation"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

mkdir -p "${OUT_DIR}"
mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -d "$BAM_DIR" ]]; then
    log_error "BAM directory not found: $BAM_DIR"
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
# Get list of BAM files
mapfile -t BAM_FILES < <(ls "${BAM_DIR}"/*sorted.bam 2>/dev/null)

if [[ ${#BAM_FILES[@]} -eq 0 ]]; then
    log_error "No sorted BAM files found in: $BAM_DIR"
    exit 1
fi

# Select file for this array task (1-indexed)
INDEX=$((SLURM_ARRAY_TASK_ID - 1))
if [[ $INDEX -ge ${#BAM_FILES[@]} ]]; then
    log_error "Array task ID $SLURM_ARRAY_TASK_ID exceeds number of BAM files (${#BAM_FILES[@]})"
    exit 1
fi

BAM_FILE="${BAM_FILES[$INDEX]}"
BAM_BASENAME=$(basename "${BAM_FILE}" .bam)

if [[ ! -f "$BAM_FILE" ]]; then
    log_error "BAM file not found: $BAM_FILE"
    exit 1
fi

log_info "Processing: $BAM_FILE"

# Run samtools flagstat
samtools flagstat "${BAM_FILE}" > "${OUT_DIR}/${BAM_BASENAME}.flagstat.txt"

if [[ ! -s "${OUT_DIR}/${BAM_BASENAME}.flagstat.txt" ]]; then
    log_error "Flagstat output is empty"
    exit 1
fi

log_info "Alignment stats saved: ${OUT_DIR}/${BAM_BASENAME}.flagstat.txt"
