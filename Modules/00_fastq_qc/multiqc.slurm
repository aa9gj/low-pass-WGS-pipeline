#!/bin/bash
#SBATCH --job-name=multiqc
#SBATCH --output=logs/multiqc_%j.out
#SBATCH --error=logs/multiqc_%j.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

# =============================================================================
# MultiQC Report Generation Script
# Aggregates FastQC reports into a single HTML report
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
INPUT_DIR="fastqc_results"
OUTPUT_DIR="multiqc_results"

# Alternatively, source from config file:
# source "$(dirname "$0")/../../config/pipeline.config"

# -----------------------------------------------------------------------------
# Setup and Validation
# -----------------------------------------------------------------------------
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2; }

log_info "Starting MultiQC report generation"
log_info "Job ID: ${SLURM_JOB_ID:-N/A}"

# Load module
module load multiqc || log_info "Module load skipped"

mkdir -p "$(dirname "$0")/logs" 2>/dev/null || true

# Validate input directory
if [[ ! -d "$INPUT_DIR" ]]; then
    log_error "FastQC results directory not found: $INPUT_DIR"
    exit 1
fi

# Check for FastQC reports
if ! ls "$INPUT_DIR"/*_fastqc.html &> /dev/null; then
    log_error "No FastQC reports found in: $INPUT_DIR"
    exit 1
fi

# -----------------------------------------------------------------------------
# Main Processing
# -----------------------------------------------------------------------------
log_info "Aggregating reports from: $INPUT_DIR"

multiqc "$INPUT_DIR" -o "$OUTPUT_DIR"

if [[ ! -f "$OUTPUT_DIR/multiqc_report.html" ]]; then
    log_error "MultiQC report not generated"
    exit 1
fi

log_info "MultiQC report generated: $OUTPUT_DIR/multiqc_report.html"
