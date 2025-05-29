# Merge and Index Joint VCFs Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates the final step of a common variant calling pipeline: merging chromosome-specific VCF files into a single, genome-wide VCF and then indexing it. This is crucial for creating a comprehensive variant callset ready for filtering, annotation, and downstream analyses. The script uses `bcftools` for merging and `tabix` for indexing.

---

## What It Does

This script performs the following sequential steps to combine chromosome-specific VCF files into a single master VCF for your entire cohort:

1.  **Navigates to Directory**: Changes the current working directory to the specified location where your chromosome-specific VCF files are stored.
2.  **Lists VCFs**: Defines an ordered list of all chromosome VCF files to be merged.
3.  **Merges VCFs**: Uses `bcftools concat` to concatenate all specified chromosome VCFs into one single, compressed VCF file (`joint_calls.vcf.gz`).
    * `-a`: Attempts to concatenate records even if they have different sets of columns (e.g., different INFO/FORMAT fields), ensuring all information is retained.
    * `-O z`: Specifies the output format as compressed VCF (`.vcf.gz`).
4.  **Indexes Merged VCF**: Creates a tabix index (`.vcf.gz.tbi`) for the newly merged `joint_calls.vcf.gz` using `tabix -p vcf`. This index is vital for efficient querying and downstream tools that require random access to the VCF.

---

## How to Use It

### Prerequisites

* **`bcftools`**: Ensure `bcftools` is installed and available in your environment's `PATH`. On many HPC systems, you might need to load a module (e.g., `module load bcftools`).
* **`htslib` (`tabix`)**: Ensure `tabix` is installed and available in your environment's `PATH`. Often, this comes with `bcftools` or as part of an `htslib` module.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Chromosome-specific VCFs**: You must have all your individual chromosome VCFs (e.g., `chr1.vcf.gz`, `chrX.vcf.gz`), preferably gzipped and indexed, ready in the specified `VCF_DIR`. These are typically the output of a `GenotypeGVCFs` run.

### Setup

1.  **Define `VCF_DIR` Path**: In the script, change `VCF_DIR=<VCF-DIR-Path>` to the **actual full path** where your chromosome-specific VCF files are located.

2.  **Update `VCFLIST`**:
    * The `VCFLIST` variable explicitly lists all VCFs in the correct order (e.g., `chr1.vcf.gz chr2.vcf.gz ... chrX.vcf.gz`). **It is CRITICAL that this list is accurate and in genomic order (e.g., chr1, chr2, ..., chrX, chrY, chrMT).**
    * **Adjust this list as needed** to include all the chromosomes present in your data. If you have `chrY.vcf.gz` or `chrMT.vcf.gz`, add them to the list in their correct genomic order.
    * Example for adding chrY and chrMT:
        ```bash
        VCFLIST="chr1.vcf.gz ... chrX.vcf.gz chrY.vcf.gz chrMT.vcf.gz"
        ```

3.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time=06:00:00`: This sets the time limit to 6 hours. Merging VCFs can take time depending on the number of samples and variants. Adjust if your VCFs are extremely large.
    * `--mem=8G`: 8GB of memory is allocated. This should be sufficient for merging operations.
    * `--cpus-per-task=1`: Merging and indexing are generally single-threaded operations for these tools, so 1 CPU is usually sufficient.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `merge_and_index_vcf.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory where you saved `merge_and_index_vcf.sh`, and submit the job to SLURM:
    ```bash
    sbatch merge_and_index_vcf.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the directory from which you submit the job:

* `merge_index_jointvcf.out`: Standard output of the merging and indexing process.
* `merge_index_jointvcf.err`: Standard error output.

### Merged and Indexed VCF File

Upon successful completion, two new files will be created in your `VCF_DIR`:

* **`joint_calls.vcf.gz`**: The final genome-wide VCF file, containing all variant calls for your entire cohort across all merged chromosomes.
* **`joint_calls.vcf.gz.tbi`**: The tabix index for `joint_calls.vcf.gz`, enabling efficient random access for downstream tools (e.g., VEP, SnpEff, GATK filtering).

---

## Important Notes

* **Order of Chromosomes**: The order of VCFs in `VCFLIST` is crucial. `bcftools concat` concatenates them in the exact order provided. Ensure it matches the genomic order of your reference sequence.
* **VCF Headers**: `bcftools concat -a` is robust to differences in INFO/FORMAT fields between VCFs from different chromosomes, which is usually not an issue when these VCFs come from the same `GenotypeGVCFs` run.
* **Resource Allocation**: While the provided resources are a good starting point, always monitor your jobs' resource usage (`sacct -j <JOBID> --format=JobID,JobName,State,Elapsed,ReqMem,MaxRSS,ReqCPUS,MaxCPU`) and adjust `--time`, `--mem`, and `--cpus-per-task` as necessary for your specific dataset size.
