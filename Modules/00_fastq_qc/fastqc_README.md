# FastQC Slurm Array Job

This repository contains a Slurm batch script designed to efficiently run FastQC on multiple paired-end sequencing samples using the Slurm workload manager's array job functionality. This is particularly useful for High-Performance Computing (HPC) environments.

## Overview

The `fastqc_array.sh` script reads a list of sample file paths from a `samples.txt` file and processes each sample pair (R1 and R2) in parallel as part of a Slurm array job. FastQC reports are generated in a dedicated `fastqc_results` directory.

## Prerequisites

* **FastQC:** Ensure FastQC is installed and available in your environment, or can be loaded via a module system (as shown in the script with `module load fastqc`).
* **Slurm Workload Manager:** This script is designed for systems running Slurm.

## Usage

1.  **Prepare your `samples.txt` file:**
    Create a plain text file named `samples.txt`. Each line in this file should contain the space-separated paths to your R1 and R2 (forward and reverse) FASTQ files for a single sample.

    **Example `samples.txt`:**
    ```
    /path/to/data/sample_A_R1.fastq.gz /path/to/data/sample_A_R2.fastq.gz
    /path/to/data/sample_B_R1.fastq.gz /path/to/data/sample_B_R2.fastq.gz
    # ... and so on for all your samples
    ```
    Ensure that the paths are correct and accessible from where you submit the job.

2.  **Update the Slurm array size:**
    Open `fastqc_array.sh` and replace `<MAX-N>` in the line `#SBATCH --array=1-<MAX-N>` with the total number of lines (i.e., the number of sample pairs) in your `samples.txt` file.

3.  **Submit the job:**
    Navigate to the directory containing `fastqc_array.sh` and `samples.txt` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch fastqc_array.sh
    ```

## Script Configuration

You can adjust the following SBATCH directives in `fastqc_array.sh` based on your resource requirements:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name pattern. `%A` is replaced by the job ID, and `%a` by the array task ID.
* `--error`: Standard error file name pattern.
* `--time`: Maximum wall-clock time for each array task (e.g., `01:00:00` for 1 hour).
* `--mem`: Memory allocation for each array task (e.g., `4G` for 4 Gigabytes).
* `--cpus-per-task`: Number of CPU cores allocated to each array task. This should match the `-t` parameter for FastQC.
* `--array`: Defines the array job range. Replace `<MAX-N>` with the number of samples in `samples.txt`.

## Output

FastQC will generate HTML reports and ZIP archives for each processed sample. All output files will be saved in the `fastqc_results` directory, which the script automatically creates if it doesn't exist.
