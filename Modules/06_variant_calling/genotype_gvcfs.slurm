#!/bin/bash
#SBATCH --job-name=genoGVCF_chr
#SBATCH --output=logs/genoGVCF_%A_%a.out
#SBATCH --error=logs/genoGVCF_%A_%a.err
#SBATCH --array=1-39                         # Adjust for your chromosome count
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=99:00:00

# =============================================================================
# GenotypeGVCFs Script
# Performs joint genotyping on GenomicsDB workspace per chromosome
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
REF_GENOME="/path/to/reference/genome.fa"
DBDIR="/path/to/genomicsdb"
OUTPUT_DIR="/path/to/output/genotypes"

# Chromosomes array - adjust for your species
# Dog (canFam4): 38 autosomes + X
# Human: chr1-chr22, chrX, chrY
# Mouse: chr1-chr19, chrX, chrY
CHROMS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chr30 chr31 chr32 chr33 chr34 chr35 chr36 chr37 chr38 chrX)

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting GenotypeGVCFs"
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

if [[ ! -d "$DBDIR" ]]; then
    log_error "GenomicsDB directory not found: $DBDIR"
    exit 1
fi

if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    log_error "Must be run as SLURM array job"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
CHR=${CHROMS[$((SLURM_ARRAY_TASK_ID-1))]}

if [[ -z "$CHR" ]]; then
    log_error "Invalid chromosome index for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

log_info "Processing chromosome: $CHR"

DB_PATH="$DBDIR/${CHR}"
if [[ ! -d "$DB_PATH" ]]; then
    log_error "GenomicsDB workspace not found: $DB_PATH"
    exit 1
fi

OUT_VCF="${OUTPUT_DIR}/${CHR}.vcf.gz"

log_info "Running GenotypeGVCFs..."
gatk --java-options "-Xmx60g" GenotypeGVCFs \
    -R "$REF_GENOME" \
    -V "gendb://$DB_PATH" \
    -O "$OUT_VCF"

if [[ ! -s "$OUT_VCF" ]]; then
    log_error "Output VCF is empty or missing: $OUT_VCF"
    exit 1
fi

log_info "GenotypeGVCFs completed successfully: $OUT_VCF"
