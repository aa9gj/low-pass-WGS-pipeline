#!/bin/bash
#SBATCH --job-name=coverage_calc
#SBATCH --output=logs/coverage_%A_%a.out
#SBATCH --error=logs/coverage_%A_%a.err
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --array=1-40                         # Update to match your sample count

# =============================================================================
# Coverage Calculation Script
# Converts SAM to sorted BAM and calculates genome-wide coverage
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SAMPLE_LIST="samples.txt"                    # List of sample names (no extension)
# Created using: ls *.sam | sed 's/\.sam$//' > samples.txt

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting coverage calculation"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}, Array Task: ${SLURM_ARRAY_TASK_ID:-N/A}"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

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
mapfile -t SAMPLES < "$SAMPLE_LIST"
SAMPLE="${SAMPLES[$((SLURM_ARRAY_TASK_ID-1))]}"

if [[ -z "$SAMPLE" ]]; then
    log_error "Could not get sample for task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

if [[ ! -f "${SAMPLE}.sam" ]]; then
    log_error "SAM file not found: ${SAMPLE}.sam"
    exit 1
fi

log_info "Processing sample: $SAMPLE"

# 1) Convert SAM to BAM
log_info "Converting SAM to BAM..."
samtools view -@ "${SLURM_CPUS_PER_TASK:-4}" -bS "${SAMPLE}.sam" > "${SAMPLE}.bam"

# 2) Sort BAM
log_info "Sorting BAM..."
samtools sort -@ "${SLURM_CPUS_PER_TASK:-4}" -o "${SAMPLE}.sorted.bam" "${SAMPLE}.bam"

# 3) Index sorted BAM
log_info "Indexing BAM..."
samtools index "${SAMPLE}.sorted.bam"

# 4) Compute average genome-wide coverage
log_info "Calculating coverage..."
AVG=$(samtools depth -a "${SAMPLE}.sorted.bam" \
      | awk '{sum+=$3; cnt++} END {if(cnt>0) printf "%.3f\n", sum/cnt; else print "NA"}')

# Append result with file locking
{
    flock -x 200
    echo -e "${SAMPLE}\t${AVG}" >> coverage_summary.tsv
} 200>coverage_summary.lock

# Cleanup intermediate file
rm -f "${SAMPLE}.bam"

log_info "Done: $SAMPLE - Average coverage = ${AVG}x"
