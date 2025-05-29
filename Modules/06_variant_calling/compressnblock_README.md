# gVCF Compression and Indexing Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the crucial steps of compressing and indexing gVCF (genomic VCF) files. It leverages `bgzip` for efficient compression and `tabix` for creating genomic indexes, which are essential for downstream analyses like joint genotyping with GATK. The script is designed for parallel processing of multiple gVCF files on High-Performance Computing (HPC) clusters.

---

## What It Does

For each gVCF file (`.g.vcf`) found in the specified input directory, the script performs the following:

1.  **Navigates to Directory**: Changes the current directory to where your gVCF files are located.
2.  **Selects File**: Based on the SLURM array task ID, it selects a specific `.g.vcf` file for processing.
3.  **Compresses gVCF**: If the compressed `.g.vcf.gz` file does not already exist, it compresses the gVCF using `bgzip`. `bgzip` creates a block-gzipped file, which is required by `tabix`.
4.  **Indexes Compressed gVCF**: If the index file (`.g.vcf.gz.tbi`) does not already exist, it creates a tabix index for the compressed gVCF using `tabix -p vcf`. This index allows for fast querying of specific genomic regions within the gVCF.

The script includes checks to skip compression or indexing if the output files already exist, making it robust to re-runs.

---

## How to Use It

### Prerequisites

* **`htslib` (bgzip and tabix)**: Ensure `bgzip` and `tabix` are installed and available in your environment's `PATH`. On many HPC systems, you might need to load an `htslib` module (e.g., `module load htslib`).
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Input gVCF files**: You should have your gVCF files (ending with `.g.vcf`) ready in a designated directory.

### Setup

1.  **Define `GVCF_DIR`**: In the script, change `GVCF_DIR=/path/to/gvariants` to the **actual full path** where your input `.g.vcf` files are located.

2.  **Adjust SLURM Array Index**:
    * `#SBATCH --array=1-40`: This example runs 40 tasks.
    * **Modify `40`**: Replace `40` with the **total number of `.g.vcf` files** you have in your `GVCF_DIR`. It's crucial this number matches the actual count of files.

3.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time`: `99:00:00` sets a very generous time limit. Adjust this based on the size of your gVCF files and expected compression/indexing times.
    * `--mem`: `32G` of memory is allocated per task. This should be sufficient for most gVCF files, but adjust if you encounter memory errors.
    * `--cpus-per-task`: `1` CPU core is allocated per task. `bgzip` and `tabix` are generally single-threaded for this operation, but you could potentially increase if your `htslib` version supports multi-threading for these specific commands (though it's less common for `tabix` indexing).

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `compress_index_gvcf.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory where you saved `compress_index_gvcf.sh`, and submit the job to SLURM:
    ```bash
    sbatch compress_index_gvcf.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the directory from which you submit the job, named after the job ID and array task ID:

* `bgzip_tabix_gvcf_JOBID_ARRAYINDEX.out`: Standard output for each task.
* `bgzip_tabix_gvcf_JOBID_ARRAYINDEX.err`: Standard error for each task.

### Compressed and Indexed gVCF Files

For each input `.g.vcf` file, two new files will be generated in the `GVCF_DIR`:

* **`.g.vcf.gz`**: The block-gzipped compressed version of your gVCF file.
* **`.g.vcf.gz.tbi`**: The tabix index file for the compressed gVCF, enabling fast random access.

---

## Important Notes

* **`GVCF_DIR`**: Ensure the specified `GVCF_DIR` is correct and has appropriate read/write permissions.
* **Array Indexing**: The script uses `GVCFS=(*.g.vcf)` to create an array of files. It's crucial that the `#SBATCH --array` value matches the exact number of `.g.vcf` files in that directory.
* **Idempotency**: The `if [ ! -f ... ]` checks ensure that if you re-run the script, it will skip files that have already been successfully compressed and indexed, preventing unnecessary re-computation.
* **Module Loading**: Uncomment and adjust `module load htslib` if your cluster requires explicit module loading for `bgzip` and `tabix`.
