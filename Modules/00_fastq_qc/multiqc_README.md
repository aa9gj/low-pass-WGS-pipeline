# MultiQC Report Generation

This repository contains a Slurm batch script for running **MultiQC**, a tool that aggregates results from various bioinformatics quality control tools (like FastQC) into a single, interactive HTML report. This script is designed for use in High-Performance Computing (HPC) environments managed by Slurm.

## Overview

The `multiqc.slurm` script executes MultiQC on a specified directory containing quality control reports. It's typically used after individual sample QC (e.g., using FastQC) to get a comprehensive summary across all samples. The script will generate a MultiQC report in a new directory named `multiqc_results`.

## Prerequisites

* **MultiQC:** Ensure MultiQC is installed and available in your environment, or can be loaded via a module system (as shown in the script with `module load multiqc`).
* **Slurm Workload Manager:** This script is designed for systems running Slurm.
* **Quality Control Reports:** You must have existing quality control reports (e.g., FastQC `.zip` and `.html` files) in a directory that MultiQC can access. In this script, it expects them in `fastqc_results`.

## Usage

1.  **Place your QC reports:**
    Ensure that your FastQC (or other QC tool) output files are located in the directory specified in the `multiqc` command within the script (e.g., `fastqc_results`).

2.  **Submit the job:**
    Navigate to the directory containing `multiqc.slurm` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch multiqc.slurm
    ```

## Script Configuration

You can adjust the following SBATCH directives in `multiqc.slurm` based on your resource requirements:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name pattern. `%j` is replaced by the job ID.
* `--error`: Standard error file name pattern.
* `--time`: Maximum wall-clock time for the job (e.g., `01:00:00` for 1 hour).
* `--mem`: Memory allocation for the job (e.g., `4G` for 4 Gigabytes).
* `--cpus-per-task`: Number of CPU cores allocated to the job. MultiQC is not heavily multi-threaded, so 1 CPU is often sufficient.

## Output

MultiQC will generate an interactive HTML report (e.g., `multiqc_report.html`) and associated data files. All output will be saved in the `multiqc_results` directory, which the script automatically creates if it doesn't exist.

## License

[e.g., MIT License - see LICENSE file for details]
