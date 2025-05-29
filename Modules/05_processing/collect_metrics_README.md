# GATK Alignment Summary Metrics Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the collection of crucial alignment statistics using GATK's `CollectAlignmentSummaryMetrics` tool. Designed for efficient parallel processing on High-Performance Computing (HPC) clusters, it helps you quickly assess the overall quality of your sequencing alignments across multiple samples.

---

## What It Does

For each BAM file listed in `bam.list.txt`, the script performs the following:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9 in this example) is loaded, which is a core dependency for GATK.
2.  **Collects Alignment Metrics**: Uses `gatk CollectAlignmentSummaryMetrics` to analyze the input BAM file against the reference genome. This generates a comprehensive set of statistics on how well your reads aligned.
3.  **Generates Output File**: Produces a `.txt` file per sample containing detailed alignment metrics.

This workflow is optimized for parallel execution across numerous samples using SLURM's array job functionality.

---

## How to Use It

### Prerequisites

* **GATK**: Make sure GATK is installed and available in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. Adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input BAM files**: You should have sorted and preferably deduplicated BAM files ready.
* **Reference Genome**: A FASTA file of the reference genome used for alignment (e.g., `genome.fa`).

### Setup

1.  **Create `bam.list.txt`**: This file should contain the **full path** to each input BAM file, with one path per line. For example:
    ```
    /path/to/project/sample_A_sorted_dedup.bam
    /path/to/project/sample_B_sorted_dedup.bam
    /path/to/project/sample_C_sorted_dedup.bam
    ```

2.  **Update SLURM Array Index**:
    * `#SBATCH --array=1-40`: This example runs 40 tasks.
    * **Modify `40`**: Replace `40` with the **total number of BAM files** listed in your `bam.list.txt`.

3.  **Update Paths in Script**:
    * **Reference Genome**: Change `ref="PATH/TO/REF.fa"` to the **actual full path** of your reference genome FASTA file.
    * **Output Directory**: Replace `<OUTPUT-DIR>` with the **full path to the directory** where you want to save the output metrics files. For example: `output_dir=/path/to/your/alignment_metrics_results`. Ensure this directory exists or will be created by your workflow.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time`: `04:00:00` sets the time limit to 4 hours. Adjust this based on your expected runtime for each file. This step is generally fast.
    * `--cpus-per-task`: `8` cores are allocated per task. GATK tools can often utilize multiple threads.
    * `--mem`: `32G` of memory is allocated per task. Adjust this based on your BAM file sizes.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `collect_alignment_metrics.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory containing your `collect_alignment_metrics.sh` script and `bam.list.txt`, then submit the job to SLURM:
    ```bash
    sbatch collect_alignment_metrics.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are useful for monitoring and debugging:
* `out`: Standard output for each task.
* `err`: Standard error for each task.

### Alignment Metrics File

For each input BAM file, a new metrics file will be generated in the specified `<OUTPUT-DIR>`:

* **`sample_name_alignment_metrics.txt`**: A plain text file containing detailed alignment statistics (e.g., total reads, PF reads, mapped reads, reads duplicated, insert size metrics, etc.). This file is invaluable for assessing mapping quality and overall data integrity.

---

## Important Notes

* **File Naming**: The script extracts the `sample_name` by taking the part of the BAM file name before the first underscore (`cut -d '_' -f 1`). If your BAM files have a different naming convention, you'll need to modify this line to correctly extract the sample name.
* **Output Directory**: Ensure the specified `output_dir` exists and has appropriate write permissions before running the script.
