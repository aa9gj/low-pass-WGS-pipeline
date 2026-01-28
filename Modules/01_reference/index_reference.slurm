#!/bin/bash
#SBATCH --job-name=index_ref
#SBATCH --output=logs/index_ref_%j.out
#SBATCH --error=logs/index_ref_%j.err
#SBATCH --time=04:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

# =============================================================================
# Reference Genome Indexing Script
# Creates all required index files for the pipeline:
# - Sequence dictionary (.dict) for GATK
# - FASTA index (.fai) for samtools
# - BWA index files for alignment
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THIS PATH
# -----------------------------------------------------------------------------
REF="/path/to/reference/genome.fa"

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"
# REF="$REF_GENOME"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting reference indexing"
log_info "Reference: $REF"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Load required modules
module load picard || log_info "Picard module load skipped"
module load samtools || log_info "Samtools module load skipped"
module load bwa || log_info "BWA module load skipped"

# Validate reference exists
if [[ ! -f "$REF" ]]; then
    log_error "Reference genome not found: $REF"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------

# 1. Create the .dict file
log_info "Creating sequence dictionary..."
DICT_FILE="${REF%.fa}.dict"
if [[ -f "$DICT_FILE" ]]; then
    log_info "Dictionary already exists, skipping: $DICT_FILE"
else
    picard CreateSequenceDictionary R="$REF" O="$DICT_FILE"
    log_info "Created: $DICT_FILE"
fi

# 2. Create the .fai index
log_info "Creating FASTA index..."
if [[ -f "${REF}.fai" ]]; then
    log_info "FASTA index already exists, skipping: ${REF}.fai"
else
    samtools faidx "$REF"
    log_info "Created: ${REF}.fai"
fi

# 3. Create BWA index files
log_info "Creating BWA index (this may take a while for large genomes)..."
if [[ -f "${REF}.bwt" ]]; then
    log_info "BWA index already exists, skipping"
else
    bwa index "$REF"
    log_info "Created BWA index files"
fi

log_info "All reference indexes generated successfully"
