#!/bin/bash
# =============================================================================
# LP-WGS Pipeline - Setup Validation Script
# =============================================================================
# Run this script before starting the pipeline to verify all dependencies
# and configuration are correctly set up.
#
# Usage: ./scripts/validate_setup.sh [config_file]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

info() {
    echo -e "[INFO] $1"
}

header() {
    echo ""
    echo "=============================================="
    echo "$1"
    echo "=============================================="
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_DIR="$(dirname "$SCRIPT_DIR")"

# -----------------------------------------------------------------------------
# Check Required Tools
# -----------------------------------------------------------------------------
header "Checking Required Tools"

REQUIRED_TOOLS=(
    "bwa:BWA aligner"
    "samtools:SAMtools"
    "gatk:GATK toolkit"
    "picard:Picard tools"
    "bcftools:BCFtools"
    "tabix:Tabix/htslib"
    "java:Java runtime"
)

OPTIONAL_TOOLS=(
    "fastqc:FastQC"
    "multiqc:MultiQC"
    "R:R statistical software"
)

for tool_info in "${REQUIRED_TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    desc="${tool_info#*:}"

    if command -v "$tool" &> /dev/null; then
        version=$("$tool" --version 2>&1 | head -1 || echo "version unknown")
        pass "$desc ($tool) - $version"
    else
        fail "$desc ($tool) not found in PATH"
    fi
done

info ""
info "Checking optional tools..."

for tool_info in "${OPTIONAL_TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    desc="${tool_info#*:}"

    if command -v "$tool" &> /dev/null; then
        pass "$desc ($tool) available"
    else
        warn "$desc ($tool) not found (optional)"
    fi
done

# -----------------------------------------------------------------------------
# Check Configuration File
# -----------------------------------------------------------------------------
header "Checking Configuration"

CONFIG_FILE="${1:-$PIPELINE_DIR/config/pipeline.config}"

if [[ -f "$CONFIG_FILE" ]]; then
    pass "Configuration file exists: $CONFIG_FILE"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"

    # Check key configuration variables
    if [[ -n "${REF_GENOME:-}" ]]; then
        if [[ -f "$REF_GENOME" ]]; then
            pass "Reference genome file exists: $REF_GENOME"

            # Check for index files
            if [[ -f "${REF_GENOME}.fai" ]]; then
                pass "Reference genome index (.fai) exists"
            else
                fail "Reference genome index (.fai) missing"
            fi

            if [[ -f "${REF_GENOME}.bwt" ]] || [[ -f "${REF_GENOME}.0123" ]]; then
                pass "BWA index files exist"
            else
                fail "BWA index files missing - run: bwa index $REF_GENOME"
            fi

            dict_file="${REF_GENOME%.fa}.dict"
            dict_file2="${REF_GENOME%.fasta}.dict"
            if [[ -f "$dict_file" ]] || [[ -f "$dict_file2" ]] || [[ -f "${REF_GENOME}.dict" ]]; then
                pass "Sequence dictionary (.dict) exists"
            else
                fail "Sequence dictionary missing - run: picard CreateSequenceDictionary"
            fi
        else
            fail "Reference genome file not found: $REF_GENOME"
        fi
    else
        fail "REF_GENOME not set in configuration"
    fi

    if [[ -n "${OUTPUT_BASE_DIR:-}" ]]; then
        if [[ -d "$OUTPUT_BASE_DIR" ]] || mkdir -p "$OUTPUT_BASE_DIR" 2>/dev/null; then
            pass "Output directory accessible: $OUTPUT_BASE_DIR"
        else
            fail "Cannot create output directory: $OUTPUT_BASE_DIR"
        fi
    else
        warn "OUTPUT_BASE_DIR not set in configuration"
    fi

    if [[ -n "${SAMPLE_LIST:-}" ]]; then
        if [[ -f "$SAMPLE_LIST" ]]; then
            num_samples=$(wc -l < "$SAMPLE_LIST" | tr -d ' ')
            pass "Sample list exists with $num_samples samples: $SAMPLE_LIST"
        else
            warn "Sample list file not found: $SAMPLE_LIST"
        fi
    else
        warn "SAMPLE_LIST not set in configuration"
    fi

else
    fail "Configuration file not found: $CONFIG_FILE"
    info "Copy config/pipeline.config.example to config/pipeline.config and customize it"
fi

# -----------------------------------------------------------------------------
# Check Pipeline Structure
# -----------------------------------------------------------------------------
header "Checking Pipeline Structure"

REQUIRED_DIRS=(
    "Modules/00_fastq_qc"
    "Modules/01_reference"
    "Modules/02_alignment"
    "Modules/04_coverage"
    "Modules/05_processing"
    "Modules/06_variant_calling"
    "Modules/09_imputation"
    "scripts"
    "config"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$PIPELINE_DIR/$dir" ]]; then
        pass "Directory exists: $dir"
    else
        fail "Directory missing: $dir"
    fi
done

# -----------------------------------------------------------------------------
# Check SLURM Environment
# -----------------------------------------------------------------------------
header "Checking SLURM Environment"

if command -v sbatch &> /dev/null; then
    pass "SLURM sbatch command available"
    if command -v squeue &> /dev/null; then
        pass "SLURM squeue command available"
    fi
    if command -v sinfo &> /dev/null; then
        partitions=$(sinfo -h -o "%P" 2>/dev/null | head -5 | tr '\n' ', ' || echo "unknown")
        pass "SLURM partitions available: $partitions"
    fi
else
    warn "SLURM not available - scripts can still be run manually"
fi

# -----------------------------------------------------------------------------
# Check Disk Space
# -----------------------------------------------------------------------------
header "Checking Disk Space"

if [[ -n "${OUTPUT_BASE_DIR:-}" ]] && [[ -d "$OUTPUT_BASE_DIR" ]]; then
    available=$(df -h "$OUTPUT_BASE_DIR" | awk 'NR==2 {print $4}')
    info "Available disk space in output directory: $available"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
header "Validation Summary"

echo ""
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo -e "Warnings: ${YELLOW}$WARN_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo -e "${RED}Setup validation FAILED${NC}"
    echo "Please fix the issues above before running the pipeline."
    exit 1
elif [[ $WARN_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}Setup validation PASSED with warnings${NC}"
    echo "The pipeline may work, but some optional features may be unavailable."
    exit 0
else
    echo -e "${GREEN}Setup validation PASSED${NC}"
    echo "The pipeline is ready to run."
    exit 0
fi
