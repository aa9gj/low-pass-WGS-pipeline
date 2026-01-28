#!/bin/bash
#SBATCH --job-name=apply_bqsr
#SBATCH --output=logs/apply_bqsr_%A_%a.out
#SBATCH --error=logs/apply_bqsr_%A_%a.err
#SBATCH --array=1-40%5                       # Run 5 at a time
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 21-00:00:00
#SBATCH --mem=64G

# =============================================================================
# Apply BQSR Script
# Applies base quality score recalibration to BAM files
#
# NOTE: Run bqsr.slurm first to generate the recalibration tables
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
REF_GENOME="/path/to/reference/genome.fa"
BAM_LIST="bam_list.txt"
RECAL_DIR="."                                # Directory containing recal tables
OUTPUT_DIR="."                               # Directory for output BAMs

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting Apply BQSR"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Load module
module load java/17.0.9 || log_info "Module load skipped"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$REF_GENOME" ]]; then
    log_error "Reference genome not found: $REF_GENOME"
    exit 1
fi

if [[ ! -f "$BAM_LIST" ]]; then
    log_error "BAM list not found: $BAM_LIST"
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
bam_file=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BAM_LIST")

if [[ -z "$bam_file" ]]; then
    log_error "Could not extract BAM file for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

if [[ ! -f "$bam_file" ]]; then
    log_error "BAM file not found: $bam_file"
    exit 1
fi

sample_name=$(basename "${bam_file}" | cut -d '_' -f 1)
log_info "Processing sample: $sample_name"

recal_table="${RECAL_DIR}/${sample_name}_recal_data.table"
if [[ ! -f "$recal_table" ]]; then
    log_error "Recalibration table not found: $recal_table"
    log_error "Run bqsr.slurm first to generate recalibration tables"
    exit 1
fi

output_bam="${OUTPUT_DIR}/${sample_name}_sorted_dedup_bqsr_reads.bam"

log_info "Applying BQSR..."
gatk ApplyBQSR \
    -I "$bam_file" \
    -R "$REF_GENOME" \
    --bqsr-recal-file "$recal_table" \
    -O "$output_bam"

if [[ ! -s "$output_bam" ]]; then
    log_error "Output BAM is empty or missing: $output_bam"
    exit 1
fi

log_info "Apply BQSR completed successfully: $output_bam"
