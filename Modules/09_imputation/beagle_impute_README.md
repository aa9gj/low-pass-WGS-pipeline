# Beagle Genotype Imputation and Phasing Script

This repository contains a Slurm batch script designed to perform genotype imputation and phasing using the **Beagle** software. This process is essential in many genomic studies for filling in missing genotype data and determining the phase (haplotype configuration) of genetic variants.

## Overview

The `beagle_impute.sh` script executes the Beagle program with specified input files:
1.  A **reference panel VCF** (`ref=`) which provides a high-quality set of phased haplotypes.
2.  A **genotype VCF** (`gt=`) containing the genotypes you wish to impute and phase.
The script then outputs the imputed and phased genotypes to a new VCF file.

## Prerequisites

* **Java Runtime Environment:** Beagle requires Java to run. Ensure Java is installed and accessible in your environment.
* **Beagle Software:** Download the `beagle.01Mar24.d36.jar` (or your specific version) from the official Beagle website and place it in the same directory as your script, or provide the full path to it.
* **Slurm Workload Manager:** This script is designed for systems running Slurm.
* **Input VCF Files:** You must have a reference panel VCF file (e.g., `AutoAndXPAR.Dog10K.phased.vcf.gz`) and the genotype VCF file you want to impute (e.g., `joint_calls.snps.recalibrated.vcf.gz`). These files should ideally be compressed with `bgzip` and indexed with `tabix`.

## Usage

1.  **Place Beagle JAR:**
    Ensure the `beagle.01Mar24.d36.jar` file is in the same directory as your script, or update the script with the full path to the JAR.

2.  **Update Input/Output Paths:**
    Open `beagle_impute.sh` and modify the `java -jar` command to reflect the correct paths and filenames for your:
    * `ref=`: Path to your reference panel VCF file.
    * `gt=`: Path to your genotype VCF file to be imputed.
    * `out=`: Desired name and path for the output VCF file.

    Example:
    ```bash
    java -jar beagle.01Mar24.d36.jar \
    ref=/path/to/my/reference/AutoAndXPAR.Dog10K.phased.vcf.gz \
    gt=/path/to/my/data/joint_calls.snps.recalibrated.vcf.gz \
    out=my_imputed_phased_data.vcf
    ```

3.  **Submit the job:**
    Navigate to the directory containing `beagle_impute.sh` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch beagle_impute.sh
    ```

## Script Configuration

You can adjust the following SBATCH directives in `beagle_impute.sh` based on your resource requirements and the size of your input data:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name for the job.
* `--error`: Standard error file name for the job.
* `--cpus-per-task`: Number of CPU cores allocated to the job. Beagle can utilize multiple threads.
* `--mem`: Memory allocation for the job (e.g., `128G` for 128 Gigabytes). Imputation of large datasets can be very memory-intensive.
* `--time`: Maximum wall-clock time limit for the job (e.g., `99:00:00` for 99 hours). Imputation can take a long time for large datasets.

## Output

Upon successful completion, the script will generate a new VCF file (named as specified by `out=`) containing the imputed and phased genotypes. This file will be created in the same directory where you execute the script, unless you specify a different path in the `out=` parameter.
