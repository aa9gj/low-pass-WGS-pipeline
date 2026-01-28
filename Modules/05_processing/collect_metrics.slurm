#!/bin/bash
#SBATCH --job-name=collect_metrics
#SBATCH --output=logs/metrics_%A_%a.out
#SBATCH --error=logs/metrics_%A_%a.err
#SBATCH --array=1-40                         # Update to match your sample count
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00
#SBATCH --mem=32G

# =============================================================================
# Collect Alignment Metrics Script
# Collects alignment summary metrics using GATK
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
REF_GENOME="/path/to/reference/genome.fa"
BAM_LIST="bam.list.txt"
OUTPUT_DIR="metrics_output"

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting alignment metrics collection"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Load module
module load java/17.0.9 || log_info "Module load skipped"

mkdir -p "$OUTPUT_DIR"
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

output_file="${OUTPUT_DIR}/${sample_name}_alignment_metrics.txt"

log_info "Running GATK CollectAlignmentSummaryMetrics..."
gatk CollectAlignmentSummaryMetrics \
    R="$REF_GENOME" \
    I="$bam_file" \
    O="$output_file"

if [[ ! -s "$output_file" ]]; then
    log_error "Output file is empty or missing: $output_file"
    exit 1
fi

log_info "Metrics collection completed: $output_file"
