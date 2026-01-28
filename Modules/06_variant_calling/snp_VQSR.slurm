#!/bin/bash
#SBATCH --job-name=select_SNPs_VQSR
#SBATCH --output=logs/snp_vqsr_%j.out
#SBATCH --error=logs/snp_vqsr_%j.err
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --time=12:00:00

# =============================================================================
# SNP Variant Quality Score Recalibration (VQSR) Script
# Extracts SNPs and builds a recalibration model using known variants
#
# Note: VQSR requires:
# - A resource VCF with known/validated variants for training
# - Sufficient variant count in your callset (typically >30 samples)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration - UPDATE THESE PATHS
# -----------------------------------------------------------------------------
REF_GENOME="/path/to/reference/genome.fa"
JOINT_VCF="joint_calls.vcf.gz"               # Joint-called VCF from GenotypeGVCFs
RESOURCE_VCF="known_sites.vcf"               # Known variants for VQSR training
RESOURCE_NAME="known_variants"               # Name for the resource in VQSR

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting SNP VQSR"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}"

# Load module
module load java/17.0.9 || log_info "Module load skipped"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate inputs
if [[ ! -f "$REF_GENOME" ]]; then
    log_error "Reference genome not found: $REF_GENOME"
    exit 1
fi

if [[ ! -f "$JOINT_VCF" ]]; then
    log_error "Joint VCF not found: $JOINT_VCF"
    exit 1
fi

if [[ ! -f "$RESOURCE_VCF" ]]; then
    log_error "Resource VCF not found: $RESOURCE_VCF"
    exit 1
fi

# -----------------------------------------------------------------------------
# Step 1: Select SNPs only from the joint callset
# -----------------------------------------------------------------------------
log_info "Step 1: Extracting SNPs from joint callset..."
gatk --java-options "-Xmx28g" SelectVariants \
    -R "$REF_GENOME" \
    -V "$JOINT_VCF" \
    --select-type-to-include SNP \
    -O joint_calls.snps.vcf.gz

if [[ ! -s "joint_calls.snps.vcf.gz" ]]; then
    log_error "SNP extraction failed"
    exit 1
fi
log_info "SNP extraction complete"

# -----------------------------------------------------------------------------
# Step 2: Run VariantRecalibrator
# -----------------------------------------------------------------------------
log_info "Step 2: Running VariantRecalibrator..."
gatk --java-options "-Xmx28g" VariantRecalibrator \
    -R "$REF_GENOME" \
    -V joint_calls.snps.vcf.gz \
    --resource:${RESOURCE_NAME},known=false,training=true,truth=true,prior=12.0 "$RESOURCE_VCF" \
    -an QD \
    -an MQRankSum \
    -an ReadPosRankSum \
    -an FS \
    -an SOR \
    -an MQ \
    -mode SNP \
    -O joint.snps.recal \
    --tranches-file joint.snps.tranches \
    --rscript-file joint.snps.plots.R

if [[ ! -s "joint.snps.recal" ]]; then
    log_error "VariantRecalibrator failed"
    exit 1
fi

log_info "SNP VQSR completed successfully"
