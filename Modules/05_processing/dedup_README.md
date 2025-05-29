# GATK MarkDuplicatesSpark Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the process of identifying and marking PCR or optical duplicates in aligned sequencing data using GATK's `MarkDuplicatesSpark` tool. It's designed for efficient, parallel processing of multiple SAM files on High-Performance Computing (HPC) clusters, leveraging Spark for improved performance.

---

## What It Does

For each SAM file listed in `sam_file_list.txt`, the script performs the following:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9 in this example) is loaded, a core dependency for GATK and Spark-based tools.
2.  **Sets Up Directories**: Defines input and output directories, and creates the output directory if it doesn't already exist.
3.  **Identifies and Marks Duplicates**: Uses `gatk MarkDuplicatesSpark` to process the input SAM file. This tool efficiently identifies duplicate reads originating from PCR amplification or optical duplicates, and then marks them in the output BAM file. Marking duplicates is a crucial step in variant calling pipelines to avoid false positive variant calls.
4.  **Outputs Deduplicated BAM**: Creates a new BAM file with duplicates marked (not removed by default, but marked for downstream tools to ignore), named following a clear convention (e.g., `sample_name_sorted_dedup_reads.bam`).

This workflow is optimized for parallel execution across multiple samples using SLURM's array job functionality, with a built-in throttle (`%5`) to manage temporary file generation and resource demands.

---

## How to Use It

### Prerequisites

* **GATK**: Make sure GATK is installed and available in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. Adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input SAM files**: You should have your aligned `.sam` files ready. These are assumed to be in the `ALIGNED_READS` directory specified in the script.

### Setup

1.  **Define `ALIGNED_READS` Path**: In the script, change `ALIGNED_READS="PATH/TO/alignment_bwa/"` to the **actual full path** where your input SAM files are located.

2.  **Create `sam_file_list.txt`**: This file should contain just the **filenames** (not full paths) of your SAM files, one filename per line. For example, if your SAM files are `sample_A.sam`, `sample_B.sam`, etc., your `sam_file_list.txt` would look like this:
    ```
    sample_A.sam
    sample_B.sam
    sample_C.sam
    ```
    Place this `sam_file_list.txt` file inside your `ALIGNED_READS` directory.

3.  **Adjust SLURM Array Index**:
    * `#SBATCH --array=1-40%5`: This example runs 40 tasks, allowing a maximum of 5 to run concurrently. The `%5` is a throttle that limits simultaneous jobs, which is very useful for managing temporary file space and I/O.
    * **Modify `40`**: Replace `40` with the **total number of SAM files** listed in your `sam_file_list.txt`.
    * **Adjust `5` (Concurrency)**: You might need to fine-tune the `%5` value based on your cluster's available resources and the I/O demands of `MarkDuplicatesSpark`. If you experience out-of-disk-space errors due to temporary files, reduce this number.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `-t`: `21-00:00:00` sets the time limit to 21 days. `MarkDuplicatesSpark` can be very time-consuming for large datasets, so ensure sufficient time is allocated.
    * `--cpus-per-task`: `8` cores are allocated per task. `MarkDuplicatesSpark` can significantly benefit from multiple threads.
    * `--mem`: `64G` of memory is allocated per task. This tool can be memory-intensive, especially for large BAM files.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `run_markduplicates.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory where you saved `run_markduplicates.sh` (or a parent directory that can access `ALIGNED_READS`), and submit the job to SLURM:
    ```bash
    sbatch run_markduplicates.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are crucial for monitoring and debugging:

* `out`: Standard output for each task.
* `err`: Standard error for each task.

### Deduplicated BAM Files

For each input SAM file, a new deduplicated BAM file will be generated in the `deduplicated` subdirectory within your `ALIGNED_READS` path. These files will be named following the pattern: `sample_name_sorted_dedup_reads.bam`.

For example, if your input was `sample_A.sam`, the output would be `PATH/TO/alignment_bwa/deduplicated/sample_A_sorted_dedup_reads.bam`.

---

## Important Notes

* **Temporary Files**: `MarkDuplicatesSpark` can generate very large temporary files. The `--tmp-dir .` option tells GATK to use the current working directory for temporary files. Ensure this directory has **ample disk space** (hundreds of GBs to TBs, depending on your data volume). If you run into "No space left on device" errors, consider pointing `--tmp-dir` to a dedicated large-capacity scratch disk.
* **Input File Type**: While this script processes SAM files, `MarkDuplicatesSpark` can also take BAM files as input. If your input files are already BAM, you can adjust the `SAM_FILE` extraction and input path accordingly.
* **Sorting**: GATK tools generally expect sorted BAM/SAM files. While `MarkDuplicatesSpark` can handle unsorted input, it's often more efficient and robust to ensure your input SAM files are coordinate-sorted before this step.
* **Sample Naming**: The script extracts the `sample_name` by taking the base name of the SAM file and removing the `.sam` extension. Ensure your SAM file names are consistent with this expectation.
