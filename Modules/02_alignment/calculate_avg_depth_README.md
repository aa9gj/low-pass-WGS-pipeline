# Genome Coverage Calculation with Samtools

This repository contains a Slurm batch script designed to streamline the process of converting SAM alignment files to sorted and indexed BAM files, and subsequently calculating the average genome-wide sequencing coverage for each sample. It leverages Slurm's array job capabilities for efficient parallel processing on High-Performance Computing (HPC) clusters.

## Overview

The `coverage_calc.sh` script performs the following steps for each sample:

1.  **SAM to BAM Conversion**: Converts the input `.sam` file to a compressed binary `.bam` file.
2.  **BAM Sorting**: Sorts the `.bam` file by genomic coordinate, which is required for indexing and many downstream tools.
3.  **BAM Indexing**: Creates a `.bai` index file for the sorted BAM, enabling fast retrieval of reads from specific genomic regions.
4.  **Average Coverage Calculation**: Uses `samtools depth -a` to compute coverage at every position and then calculates the average genome-wide coverage.
5.  **Results Aggregation**: Appends the sample name and its average coverage to a shared `coverage_summary.tsv` file.

## Prerequisites

* **Samtools**: Ensure `samtools` is installed and available in your environment, or can be loaded via a module system.
* **Slurm Workload Manager**: This script is designed for systems running Slurm.
* **Input SAM Files**: You must have `.sam` alignment files for your samples available in the directory from which the script will be executed.

## Usage

1.  **Prepare your `samples.txt` file:**
    Create a plain text file named `samples.txt` containing one sample name per line, *without* the `.sam` extension. This file should list all the base names of your SAM input files.

    You can generate this file from your SAM files using a command like:
    ```bash
    ls *.sam | sed 's/\.sam$//' > samples.txt
    ```

    **Example `samples.txt`:**
    ```
    sample_A
    sample_B
    sample_C
    ```

2.  **Update the Slurm array size:**
    Open `coverage_calc.sh` and replace `40` in the line `#SBATCH --array=1-40` with the actual total number of samples (lines) in your `samples.txt` file.

3.  **Create a `logs` directory:**
    The script is configured to output Slurm logs into a `logs` directory. Create this directory before submitting the job:
    ```bash
    mkdir -p logs
    ```

4.  **Submit the job:**
    Navigate to the directory containing `coverage_calc.sh`, `samples.txt`, and your `.sam` files on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch coverage_calc.sh
    ```

## Script Configuration

You can adjust the following SBATCH directives in `coverage_calc.sh` based on your resource requirements:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name pattern for each array task.
* `--error`: Standard error file name pattern for each array task.
* `--time`: Maximum wall-clock time limit for each array task (e.g., `06:00:00` for 6 hours). Processing time will depend on SAM file size.
* `--cpus-per-task`: Number of CPU cores allocated to each array task. This value is passed to `samtools` for multi-threading.
* `--mem`: Memory allocation for each array task (e.g., `32G` for 32 Gigabytes). Sorting large BAM files can be memory-intensive.
* `--array`: Defines the array job range. Replace `40` with the number of samples in `samples.txt`.

## Output

Upon successful completion, the script will generate the following files for each sample:

* `[SAMPLE_NAME].bam`: The unsorted BAM file.
* `[SAMPLE_NAME].sorted.bam`: The sorted BAM file.
* `[SAMPLE_NAME].sorted.bam.bai`: The index file for the sorted BAM.

Additionally, a single aggregated results file will be created or appended to:

* `coverage_summary.tsv`: A tab-separated file containing two
