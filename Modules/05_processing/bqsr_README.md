# GATK Base Quality Score Recalibration (BQSR) Table Generation (SLURM Optimized)

This SLURM-enabled Bash script automates the generation of Base Quality Score Recalibration (BQSR) tables using GATK's `BaseRecalibrator` tool. It's designed to process multiple BAM files in parallel on a high-performance computing (HPC) cluster, helping you prepare your sequencing data for accurate variant calling.

---

## What It Does

For each BAM file listed in `bam_list.txt`, the script performs the following steps:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9 in this example) is loaded, which is a core dependency for GATK.
2.  **Generates Recalibration Table**: Uses `gatk BaseRecalibrator` to build a recalibration table. This table models the empirical error rates of bases by comparing their observed quality scores with those at known variant sites.
3.  **Outputs Recalibration Table**: Creates a new `.table` file (e.g., `sample_name_recal_data.table`) that will later be used by `ApplyBQSR` to adjust base quality scores in your BAM files.

This workflow is optimized for parallel execution of multiple samples using SLURM's array job functionality, with a built-in throttle (`%5`) to manage temporary file generation and resource demands.

---

## How to Use It

### Prerequisites

* **GATK**: Make sure GATK is installed and accessible in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. You might need to adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input BAM files**: You should have sorted and deduplicated BAM files ready.
* **Reference Genome**: A FASTA file of the reference genome used for alignment (e.g., `genome.fa`).
* **Known Sites VCF/VCF.GZ**: A VCF or VCF.GZ file containing known variant sites (e.g., dbSNP, 1000 Genomes Project variants). This is crucial for BQSR to accurately model error rates.

### Setup

1.  **Create `bam_list.txt`**: This file should contain the **full path** to each input BAM file, one path per line. For example:
    ```
    /path/to/my_project/sample_A_sorted_dedup.bam
    /path/to/my_project/sample_B_sorted_dedup.bam
    /path/to/my_project/sample_C_sorted_dedup.bam
    ```

2.  **Update Paths in Script**:
    * **Reference Genome**: Change `ref="/PATH/TO/genome.fa"` to the **actual full path** of your reference genome FASTA file.
    * **Known Sites**: Replace `<known_sites>` with the **full path** to your known variants VCF/VCF.GZ file. For example: `--known-sites /path/to/dbsnp.vcf.gz`.

3.  **Adjust SLURM Array Index**:
    * `--array=1-40%5`: This example runs 40 tasks, allowing a maximum of 5 to run concurrently.
    * **Modify `40`**: Replace `40` with the **total number of BAM files** in your `bam_list.txt`.
    * **Adjust `5` (Concurrency)**: You might need to fine-tune the `%5` value based on your cluster's available resources and the I/O demands of `BaseRecalibrator`. Running fewer tasks concurrently can help manage temporary file generation and disk I/O.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `-t`: `21-00:00:00` sets the time limit to 21 days. Adjust this based on your expected runtime for each file. BQSR can be computationally intensive for large BAMs.
    * `--cpus-per-task`: `8` cores are allocated per task. GATK's `BaseRecalibrator` can utilize multiple threads.
    * `--mem`: `64G` of memory is allocated per task. This is a common requirement for GATK tools processing large BAM files.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `generate_bqsr_tables.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory containing your `generate_bqsr_tables.sh` script and `bam_list.txt`, then submit the job to SLURM:
    ```bash
    sbatch generate_bqsr_tables.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are essential for monitoring and debugging:
* `out`: Standard output for each task.
* `err`: Standard error for each task.

### Recalibration Tables

For each input BAM file, a new recalibration table will be generated in the same directory where the script is executed, named following the pattern: `sample_name_recal_data.table`.

For example, if your input BAM was `/path/to/my_project/sample_A_sorted_dedup.bam`, the output would be `sample_A_recal_data.table`. These `.table` files are then used as input for the `ApplyBQSR` step.

---

## Important Notes

* **File Naming**: The script assumes a consistent naming convention where the sample name can be extracted as the first field before the first underscore (e.g., `sample_A` from `sample_A_sorted_dedup.bam`). Adjust `cut -d '_' -f 1` if your file names differ.
* **Known Sites**: Providing a high-quality, relevant set of known variant sites (`--known-sites`) is critical for accurate BQSR. Using a VCF/VCF.GZ file that matches your species and population is highly recommended.
* **Temporary Files**: GATK can generate large temporary files. Ensure your working directory or the designated temporary directory (`TMPDIR` environment variable) has sufficient space. The `%` throttle in the `--array` option helps manage this by limiting concurrent processes.
