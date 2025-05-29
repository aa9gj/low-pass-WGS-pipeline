# GATK Base Quality Score Recalibration (BQSR) Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the application of Base Quality Score Recalibration (BQSR) using GATK's `ApplyBQSR` tool. It's designed to process multiple BAM files in parallel on a high-performance computing (HPC) cluster managed by SLURM, optimizing resource usage by controlling the number of concurrent tasks.

---

## What It Does

For each BAM file listed in `bam_list.txt`, the script performs the following:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9) is loaded, which is a dependency for GATK.
2.  **Applies BQSR**: Uses `gatk ApplyBQSR` to recalibrate the base quality scores in the input BAM file. This step uses a previously generated recalibration table (from `BaseRecalibrator`) to adjust base qualities, improving the accuracy of variant calls.
3.  **Outputs Recalibrated BAM**: Creates a new BAM file with recalibrated base quality scores, named using the sample's base name (e.g., `sample_name_sorted_dedup_bqsr_reads.bam`).

This workflow is optimized for parallel execution of multiple samples using SLURM's array job functionality, with a built-in throttle (`%5`) to manage temporary file generation and resource demands.

---

## How to Use It

### Prerequisites

* **GATK**: Ensure GATK is installed and available in your environment's PATH.
* **Java 17.0.9**: The script specifically loads this version. Adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input BAM files**: You should have sorted, deduplicated BAM files ready.
* **BQSR Recalibration Tables (`.table` files)**: For each input BAM file, you must have a corresponding `_recal_data.table` file generated previously by `gatk BaseRecalibrator`. These tables should be named consistently with your sample names (e.g., `sample_name_recal_data.table`).
* **Reference Genome**: A FASTA file of the reference genome used for alignment (e.g., `genome.fa`).

### Setup

1.  **Create `bam_list.txt`**: This file should contain the **full path** to each input BAM file, one path per line. For example:
    ```
    /path/to/my_project/sample_A_sorted_dedup.bam
    /path/to/my_project/sample_B_sorted_dedup.bam
    /path/to/my_project/sample_C_sorted_dedup.bam
    ```
    Ensure that the corresponding `_recal_data.table` files are in the same directory where the script will be run or are accessible via a specified path in the script's environment.

2.  **Update Reference Genome Path**: In the script, change `ref="PATH/TO/genome.fa"` to the **actual full path** of your reference genome FASTA file.

3.  **Adjust SLURM Array Index**:
    * `--array=1-40%5`: This example runs 40 tasks, with a maximum of 5 running concurrently.
    * **Modify `40`**: Replace `40` with the **total number of BAM files** in your `bam_list.txt`.
    * **Adjust `5` (Concurrency)**: You might need to tune the `%5` value based on your cluster's available resources and the I/O demands of `ApplyBQSR`. Running fewer tasks concurrently can help manage temporary file creation and disk I/O.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `-t`: `21-00:00:00` sets the time limit to 21 days. Adjust this based on your expected runtime for each file. BQSR can be computationally intensive for large BAMs.
    * `--cpus-per-task`: `8` cores are allocated per task. GATK can utilize multiple threads for `ApplyBQSR`.
    * `--mem`: `64G` of memory is allocated per task. This is a common requirement for GATK tools processing large BAM files.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, e.g., `apply_bqsr.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory where you saved the script and `bam_list.txt`, then submit the job to SLURM:
    ```bash
    sbatch apply_bqsr.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are crucial for monitoring and debugging:
* `out`: Standard output for each task.
* `err`: Standard error for each task.

### Recalibrated BAM Files

For each input BAM file, a new recalibrated BAM file will be generated in the same directory where the script is executed, named following the pattern: `sample_name_sorted_dedup_bqsr_reads.bam`.

For example, if your input was `/path/to/my_project/sample_A_sorted_dedup.bam` and its corresponding `recal_data.table` was `sample_A_recal_data.table`, the output would be `sample_A_sorted_dedup_bqsr_reads.bam`.

---

## Important Notes

* **File Naming**: The script assumes a consistent naming convention where the sample name can be extracted as the first field before the first underscore (e.g., `sample_A` from `sample_A_sorted_dedup.bam`). Adjust `cut -d '_' -f 1` if your file names differ.
* **BQSR Table Location**: The script assumes the `_recal_data.table` files are in the directory where the script is run. If they are in a different location, you'll need to modify the path used with `--bqsr-recal-file`.
* **Temporary Files**: GATK can generate large temporary files. Ensure your working directory or the designated temporary directory (`TMPDIR` environment variable) has sufficient space. The `%` throttle in the `--array` option helps manage this by limiting concurrent processes.
