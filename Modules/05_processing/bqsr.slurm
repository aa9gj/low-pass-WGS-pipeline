#!/bin/bash
#SBATCH --job-name=base_recal
#SBATCH --output=logs/bqsr_%A_%a.out
#SBATCH --error=logs/bqsr_%A_%a.err
#SBATCH --array=1-40%5                       # Run 5 at a time
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH -t 21-00:00:00
#SBATCH --mem=64G

# =============================================================================
# Base Quality Score Recalibration (BQSR) Script
# Generates recalibration table for base quality scores
#
# NOTE: BQSR requires known variant sites. This works well for:
# - Human (dbSNP, Mills indels, 1000G indels)
# - Mouse (MGI/dbSNP variants)
# - Other species with well-annotated variant databases
#
# For species without known sites, consider skipping BQSR.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
REF_GENOME="/path/to/reference/genome.fa"
KNOWN_SITES="/path/to/known_sites.vcf.gz"    # Required for BQSR
BAM_LIST="bam_list.txt"
OUTPUT_DIR="."                               # Directory for recal tables

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting Base Quality Score Recalibration"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

# Load module
module load java/17.0.9 || log_info "Module load skipped"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$REF_GENOME" ]]; then
    log_error "Reference genome not found: $REF_GENOME"
    exit 1
fi

if [[ ! -f "$KNOWN_SITES" ]]; then
    log_error "Known sites VCF not found: $KNOWN_SITES"
    log_error "BQSR requires known variant sites for your species"
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

output_table="${OUTPUT_DIR}/${sample_name}_recal_data.table"

log_info "Running GATK BaseRecalibrator..."
gatk BaseRecalibrator \
    -I "$bam_file" \
    -R "$REF_GENOME" \
    --known-sites "$KNOWN_SITES" \
    -O "$output_table"

if [[ ! -s "$output_table" ]]; then
    log_error "Output recalibration table is empty or missing"
    exit 1
fi

log_info "BQSR completed successfully: $output_table"
