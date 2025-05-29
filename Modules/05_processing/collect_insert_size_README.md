# GATK CollectInsertSizeMetrics Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the collection of insert size metrics and generates corresponding histograms using GATK's `CollectInsertSizeMetrics` tool. It's designed for efficient parallel processing of multiple BAM files on high-performance computing (HPC) clusters.

---

## What It Does

For each BAM file listed in `bam.list.txt`, the script performs the following:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9 in this example) is loaded, which is a core dependency for GATK.
2.  **Collects Insert Size Metrics**: Uses `gatk CollectInsertSizeMetrics` to analyze the insert sizes of paired-end reads in the input BAM file. This provides insights into the quality and characteristics of your library preparation.
3.  **Generates Output Files**: Produces two output files per sample:
    * A `.txt` file containing the insert size statistics (e.g., mean, median, standard deviation).
    * A `.pdf` file visualizing the insert size distribution as a histogram.

This workflow is optimized for parallel execution across multiple samples using SLURM's array job functionality.

---

## How to Use It

### Prerequisites

* **GATK**: Make sure GATK is installed and available in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. You might need to adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input BAM files**: You should have sorted and preferably deduplicated BAM files ready.

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

3.  **Specify Output Directory**:
    * In the script, replace `<OUTPUT-DIR>` with the **full path to the directory** where you want to save the output metrics and histogram files. For example: `output_dir=/path/to/your/metrics_results`. Ensure this directory exists or will be created by your workflow.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time`: `04:00:00` sets the time limit to 4 hours. Adjust this based on your expected runtime for each file. Insert size metrics calculation is generally fast but depends on file size.
    * `--cpus-per-task`: `8` cores are allocated per task. GATK tools can often utilize multiple threads.
    * `--mem`: `32G` of memory is allocated per task. Adjust this based on your BAM file sizes.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `collect_metrics.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory containing your `collect_metrics.sh` script and `bam.list.txt`, then submit the job to SLURM:
    ```bash
    sbatch collect_metrics.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are useful for monitoring and debugging:
* `out`: Standard output for each task.
* `err`: Standard error for each task.

### Metrics and Histogram Files

For each input BAM file, two output files will be generated in the specified `<OUTPUT-DIR>`:

* **`sample_name_insert_size_metrics.txt`**: A plain text file containing detailed insert size statistics (e.g., mean, median, mode, standard deviation, and various percentiles).
* **`sample_name_insert_size_histogram.pdf`**: A PDF file visualizing the distribution of insert sizes, which is useful for quick visual inspection of library quality.

---

## Important Notes

* **File Naming**: The script extracts the `sample_name` by taking the part of the BAM file name before the first underscore (`cut -d '_' -f 1`). If your BAM files have a different naming convention, you'll need to modify this line to correctly extract the sample name.
* **Output Directory**: Ensure the specified `output_dir` exists and has appropriate write permissions before running the script.
