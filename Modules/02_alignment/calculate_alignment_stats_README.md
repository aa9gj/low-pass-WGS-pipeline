# Samtools Flagstat Slurm Array Job

This repository contains a Slurm batch script designed to run `samtools flagstat` on multiple sorted BAM files in parallel using a Slurm array job. This is a common and important step in bioinformatics pipelines to quickly assess the quality and content of alignment files.

---

## Overview

The `flagstat_array.sh` script automates the generation of alignment statistics. For each sorted BAM file identified, it:

1.  Determines the input BAM file based on the Slurm array task ID.
2.  Executes `samtools flagstat` on that BAM file.
3.  Saves the output statistics to a text file in a dedicated output directory.

This approach is highly efficient for processing a large number of BAM files on an HPC cluster.

---

## Prerequisites

* **Samtools:** You'll need `samtools` installed and accessible in your environment (e.g., via `module load samtools` or directly in your `$PATH`).
* **Slurm Workload Manager:** This script is specifically designed for systems using Slurm.
* **Sorted BAM Files:** You must have sorted BAM files (e.g., `*.sorted.bam`) that you want to analyze. These files should be located in the directory you specify.

---

## Usage

1.  **Specify your BAM directory:**
    Open `flagstat_array.sh` and replace `<BAM-sorted-DIR>` with the **absolute path** to the directory containing your sorted BAM files.

    Example:
    ```bash
    BAM_DIR="/path/to/my/sorted_bams"
    ```

2.  **Adjust the array size:**
    Update the `#SBATCH --array=0-40` line. Replace `40` with the actual number of sorted BAM files you have, minus one (since the array starts at 0). You can find this by running `ls <BAM-sorted-DIR>/*sorted.bam | wc -l`.

    For example, if you have 41 BAM files, it would be `0-40`. If you have 10 files, it would be `0-9`.

3.  **Submit the job:**
    Navigate to the directory containing `flagstat_array.sh` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch flagstat_array.sh
    ```

---

## Script Configuration

You can adjust the following SBATCH directives in `flagstat_array.sh` based on your resource requirements:

* `--job-name`: The name for your Slurm job.
* `--output`: Specifies the pattern for standard output files. `%A` is replaced by the master job ID, and `%a` by the array task ID.
* `--error`: Specifies the pattern for standard error files.
* `--array`: Defines the range of array tasks. Make sure `<MAX-N>` matches the number of BAM files you have minus one.
* `--time`: The maximum wall-clock time limit for each array task (e.g., `04:00:00` for 4 hours). Flagstat is usually fast.
* `--mem`: Memory allocation for each array task (e.g., `8G` for 8 Gigabytes).
* `--cpus-per-task`: Number of CPU cores per task.
