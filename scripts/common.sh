#!/bin/bash
# =============================================================================
# LP-WGS Pipeline - Common Utilities
# =============================================================================
# Source this file at the beginning of each script:
#   source "$(dirname "$0")/../scripts/common.sh"
# =============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $*"
    fi
}

# -----------------------------------------------------------------------------
# Validation Functions
# -----------------------------------------------------------------------------

# Check if a file exists and is readable
check_file() {
    local file="$1"
    local description="${2:-File}"
    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        exit 1
    fi
    if [[ ! -r "$file" ]]; then
        log_error "$description is not readable: $file"
        exit 1
    fi
    log_info "$description validated: $file"
}

# Check if a directory exists (optionally create it)
check_dir() {
    local dir="$1"
    local create="${2:-false}"
    local description="${3:-Directory}"

    if [[ ! -d "$dir" ]]; then
        if [[ "$create" == "true" ]]; then
            mkdir -p "$dir"
            log_info "Created $description: $dir"
        else
            log_error "$description not found: $dir"
            exit 1
        fi
    else
        log_info "$description exists: $dir"
    fi
}

# Validate that a command/tool is available
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd"
        log_error "Please load the appropriate module or install the tool."
        exit 1
    fi
    log_info "Command available: $cmd"
}

# Validate array job setup
check_array_job() {
    if [[ -z "${SLURM_ARRAY_TASK_ID:-}" ]]; then
        log_error "This script must be run as a SLURM array job"
        log_error "Use: sbatch --array=1-N script.slurm"
        exit 1
    fi
}

# Validate a variable is set and not empty
check_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"

    if [[ -z "$var_value" ]]; then
        log_error "Required variable not set: $var_name"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# File List Helpers
# -----------------------------------------------------------------------------

# Get the Nth line from a file (1-indexed)
get_line() {
    local file="$1"
    local line_num="$2"
    sed -n "${line_num}p" "$file"
}

# Count lines in a file
count_lines() {
    local file="$1"
    wc -l < "$file" | tr -d ' '
}

# Validate array index is within bounds
validate_array_index() {
    local file_list="$1"
    local index="${SLURM_ARRAY_TASK_ID:-1}"
    local max_lines

    check_file "$file_list" "Sample list"
    max_lines=$(count_lines "$file_list")

    if [[ "$index" -gt "$max_lines" ]]; then
        log_error "Array task ID ($index) exceeds number of samples ($max_lines)"
        exit 1
    fi

    if [[ "$index" -lt 1 ]]; then
        log_error "Array task ID must be >= 1, got: $index"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Module Loading
# -----------------------------------------------------------------------------

# Load a module with error checking
load_module() {
    local module_name="$1"

    if ! module load "$module_name" 2>/dev/null; then
        log_warn "Could not load module: $module_name"
        log_warn "Attempting to continue without module loading..."
    else
        log_info "Loaded module: $module_name"
    fi
}

# -----------------------------------------------------------------------------
# Job Information
# -----------------------------------------------------------------------------

# Print job information at start of script
print_job_info() {
    log_info "=========================================="
    log_info "Job Name: ${SLURM_JOB_NAME:-N/A}"
    log_info "Job ID: ${SLURM_JOB_ID:-N/A}"
    log_info "Array Task ID: ${SLURM_ARRAY_TASK_ID:-N/A}"
    log_info "Node: ${SLURM_NODELIST:-N/A}"
    log_info "CPUs: ${SLURM_CPUS_PER_TASK:-N/A}"
    log_info "Memory: ${SLURM_MEM_PER_NODE:-N/A}"
    log_info "Working Directory: $(pwd)"
    log_info "=========================================="
}

# Print summary at end of script
print_job_summary() {
    local status="${1:-completed}"
    log_info "=========================================="
    log_info "Job $status at $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "=========================================="
}

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

# Trap for cleanup on exit
setup_cleanup() {
    local cleanup_func="${1:-default_cleanup}"
    trap "$cleanup_func" EXIT ERR INT TERM
}

default_cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with error code: $exit_code"
    fi
}
