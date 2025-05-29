# BWA-MEM Slurm Array Job for Paired-End Alignment

This repository provides a Slurm batch script to efficiently align paired-end sequencing reads to a reference genome using **BWA-MEM**. This script leverages Slurm's array job functionality to process multiple samples in parallel, making it ideal for high-throughput sequencing projects on High-Performance Computing (HPC) clusters.

## Overview

The `bwa_mem_array.sh` script automates the read alignment process. For each sample pair listed in `fastq_file_pairs.txt`, it:
1.  Extracts the paths to the R1 (forward) and R2 (reverse) FASTQ files.
2.  Derives a sample name from the R1 filename.
3.  Executes `bwa mem` to align the reads to the specified reference genome.
4.  Outputs the alignment in SAM format to a designated output directory.

## Prerequisites

* **BWA:** Ensure BWA (specifically `bwa mem`) is installed and available in your environment, or can be loaded via a module system.
* **Slurm Workload Manager:** This script is designed for systems running Slurm.
* **Indexed Reference Genome:** You must have a reference genome that has been indexed by BWA. (You can use the `index_ref.sh` script, if available, to prepare your reference).

## Usage

1.  **Prepare your `fastq_file_pairs.txt` file:**
    Create a plain text file named `fastq_file_pairs.txt`. Each line in this file should contain the **space-separated** paths to your R1 and R2 (forward and reverse) FASTQ files for a single sample.

    **Example `fastq_file_pairs.txt`:**
    ```
    /data/raw_reads/sample_A_R1.fastq.gz /data/raw_reads/sample_A_R2.fastq.gz
    /data/raw_reads/sample_B_R1.fastq.gz /data/raw_reads/sample_B_R2.fastq.gz
    # ... add more sample pairs as needed
    ```
    Ensure that the paths are correct and accessible from where you submit the job.

2.  **Update script variables:**
    Open `bwa_mem_array.sh` and modify the following variables:
    * `PARENT_DIR`: Replace `<PATH>` with the absolute path to the directory where your `fastq_file_pairs.txt` file is located and from where you intend to run the script.
    * `REF_GENOME`: Replace `<PATH_TO_REFERENCE_INDEX>` with the absolute path to your BWA-indexed reference genome FASTA file.
    * `OUTPUT_DIR`: Replace `<PATH>` with the absolute path where you want the output SAM files to be saved.
    * `#SBATCH --array=1-<MAX_INDEX>`: Replace `<MAX_INDEX>` with the total number of lines (i.e., the number of sample pairs) in your `fastq_file_pairs.txt` file.

3.  **Submit the job:**
    Navigate to the directory containing `bwa_mem_array.sh` and `fastq_file_pairs.txt` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch bwa_mem_array.sh
    ```

## Script Configuration

You can adjust the following SBATCH directives in `bwa_mem_array.sh` based on your resource requirements and the size of your data:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name pattern. `%A` is replaced by the master job ID, and `%a` by the array task ID.
* `--error`: Standard error file name pattern.
* `--array`: Defines the array job range. `<MAX_INDEX>` should be the number of lines in `fastq_file_pairs.txt`.
* `--ntasks`: Number of tasks per job step (usually 1 for array jobs).
* `--cpus-per-task`: Number of CPU cores allocated to each array task. **This value should match the `-t` parameter provided to `bwa mem` for optimal performance.**
* `--time`: Maximum wall-clock time limit for each array task (e.g., `10:00:00` for 10 hours). Alignment time varies significantly with read and genome size.
* `--mem`: Memory allocation for each array task (e.g., `32G` for 32 Gigabytes). BWA-MEM can be memory-intensive.

## Output

For each sample pair, the script will generate a `.sam` file containing the aligned reads. These files will be named after the sample (derived from the R1 filename, e.g., `sample_A.sam`) and saved into the `OUTPUT_DIR` you specify.
