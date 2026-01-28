#!/bin/bash
#SBATCH --job-name=beagle_impute
#SBATCH --output=logs/beagle_%j.out
#SBATCH --error=logs/beagle_%j.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=99:00:00

# =============================================================================
# BEAGLE Genotype Imputation Script
# Imputes missing genotypes using a reference panel
#
# Note: Requires:
# - A phased reference panel (species-specific)
# - Input VCF with genotype calls
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
BEAGLE_JAR="/path/to/beagle.jar"
REF_PANEL="/path/to/reference_panel.phased.vcf.gz"
INPUT_VCF="joint_calls.snps.recalibrated.vcf.gz"
OUTPUT_PREFIX="imputed_genotypes"

# Java memory settings (adjust based on available memory)
JAVA_MEM="120g"

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting BEAGLE imputation"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$BEAGLE_JAR" ]]; then
    log_error "BEAGLE JAR not found: $BEAGLE_JAR"
    exit 1
fi

if [[ ! -f "$REF_PANEL" ]]; then
    log_error "Reference panel not found: $REF_PANEL"
    exit 1
fi

if [[ ! -f "$INPUT_VCF" ]]; then
    log_error "Input VCF not found: $INPUT_VCF"
    exit 1
fi

# Check Java is available
if ! command -v java &> /dev/null; then
    log_error "Java not found in PATH"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
log_info "Reference panel: $REF_PANEL"
log_info "Input VCF: $INPUT_VCF"
log_info "Output prefix: $OUTPUT_PREFIX"

java -Xmx${JAVA_MEM} -jar "$BEAGLE_JAR" \
    ref="$REF_PANEL" \
    gt="$INPUT_VCF" \
    out="$OUTPUT_PREFIX"

# Validate output
if [[ ! -f "${OUTPUT_PREFIX}.vcf.gz" ]]; then
    log_error "BEAGLE output not found: ${OUTPUT_PREFIX}.vcf.gz"
    exit 1
fi

log_info "BEAGLE imputation completed successfully"
log_info "Output: ${OUTPUT_PREFIX}.vcf.gz"
