#!/bin/bash

# SLURM Script for Extracting Imputation Quality R-squared from Beagle VCF

#SBATCH --job-name=extract_imputation_rsq  # Job name
#SBATCH --output=extract_rsq_%j.out        # Standard output log
#SBATCH --error=extract_rsq_%j.err         # Standard error log
#SBATCH --ntasks=1                         # Run on a single CPU
#SBATCH --cpus-per-task=1                  # Request 1 CPU core (bcftools query is single-threaded)
#SBATCH --mem=8G                           # Request 4 GB of memory (adjust if VCF is extremely large)
#SBATCH --time=06:00:00                    # Time limit hrs:min:sec (adjust as needed)

# --- Configuration Variables ---
# Define your imputed VCF file
# IMPORTANT: CHANGE THIS PATH to your actual Beagle output VCF file
IMPUTED_VCF="canfam4_lpwgs.vcf.gz"

# Output file for R-squared values
RSQ_OUTPUT_FILE="imputation_rsq_values.txt"

echo "Starting R-squared extraction for job ID: ${SLURM_JOB_ID}"
echo "Input Imputed VCF: ${IMPUTED_VCF}"
echo "Output R-squared file: ${RSQ_OUTPUT_FILE}"
echo "Start Time: $(date)"

# --- Check if input VCF exists ---
if [ ! -f "${IMPUTED_VCF}" ]; then
    echo "Error: Imputed VCF file '${IMPUTED_VCF}' not found!"
    echo "Please update the IMPUTED_VCF variable with the correct path."
    exit 1
fi

# --- Extract imputation quality R-squared ---
# Beagle typically outputs DR2 (Dosage R-squared).
# If your Beagle version uses R2 (Allelic R-squared), comment out the DR2 line
# and uncomment the R2 line.
# You can check your VCF header to be sure (e.g., zcat your_vcf.gz | head -n 1000 | grep "INFO=<ID=DR2")

echo "Attempting to extract INFO/DR2..."
bcftools query -f '%CHROM\t%POS\t%ID\t%INFO/DR2\n' "${IMPUTED_VCF}" > "${RSQ_OUTPUT_FILE}"

# Check if the previous command was successful. If not, try R2.
if [ $? -ne 0 ]; then
    echo "Extraction with INFO/DR2 failed. Trying INFO/R2..."
    bcftools query -f '%CHROM\t%POS\t%ID\t%INFO/R2\n' "${IMPUTED_VCF}" > "${RSQ_OUTPUT_FILE}"
    if [ $? -ne 0 ]; then
        echo "Error: Extraction with both INFO/DR2 and INFO/R2 failed."
        echo "Please verify the correct R-squared tag in your VCF header and adjust the bcftools query command."
        exit 1
    fi
fi

if [ -s "${RSQ_OUTPUT_FILE}" ]; then # -s checks if file exists and is not empty
    echo "Successfully extracted R-squared values to ${RSQ_OUTPUT_FILE}"
else
    echo "Warning: R-squared output file ${RSQ_OUTPUT_FILE} is empty or extraction failed silently."
    echo "Please check the VCF content and the bcftools query command."
fi
