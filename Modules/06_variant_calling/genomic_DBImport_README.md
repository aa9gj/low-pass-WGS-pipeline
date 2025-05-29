# GATK GenomicsDBImport Workflow by Chromosome (SLURM Optimized)

This SLURM-enabled Bash script automates the creation of a GATK GenomicsDB workspace for joint genotyping, processing one chromosome at a time. It's designed to efficiently consolidate gVCF files from multiple samples into a highly optimized database structure, crucial for downstream variant calling with GATK's `GenotypeGVCFs`. This workflow is ideal for large cohorts on High-Performance Computing (HPC) clusters.

---

## What It Does

This script runs GATK's `GenomicsDBImport` tool for each specified chromosome, combining the gVCF data from all samples into a single GenomicsDB workspace. It performs the following steps:

1.  **Environment Setup**: Loads the necessary Java module (Java 17.0.9).
2.  **Define Paths**: Sets up paths for the reference genome, input gVCFs, temporary files, and the output GenomicsDB workspaces.
3.  **Chromosome Selection**: Based on the SLURM array task ID, it selects a specific chromosome from a predefined list (`CHROMS`).
4.  **Workspace Management**:
    * Creates a unique temporary directory for each chromosome's import process.
    * Creates the main output directory for GenomicsDB workspaces.
    * **Safely cleans up** any existing GenomicsDB workspace for the current chromosome before starting, ensuring a clean import.
5.  **GenomicsDBImport Execution**: Runs `gatk GenomicsDBImport` with optimized settings:
    * `--genomicsdb-workspace-path`: Specifies the output directory for the GenomicsDB workspace for the current chromosome.
    * `--sample-name-map`: Provides a mapping file (`sample_map.txt`) that links sample names to their gVCF files.
    * `-L`: Targets a specific chromosome, allowing parallel processing.
    * `--genomicsdb-shared-posixfs-optimizations true`: Enhances performance on POSIX file systems.
    * `--merge-input-intervals`: Merges contiguous intervals from input gVCFs for efficiency.
    * `--bypass-feature-reader`: Skips validation of input features, potentially speeding up the process.
    * `--tmp-dir`: Directs temporary files to a dedicated location.
6.  **Temporary File Cleanup**: Removes the temporary directory after successful import.

---

## How to Use It

### Prerequisites

* **GATK**: Ensure GATK is installed and available in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. Adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Reference Genome**: The FASTA file (`.fa`) used for alignment.
* **Compressed and Indexed gVCFs**: All your sample gVCFs must be compressed (`.g.vcf.gz`) and indexed (`.g.vcf.gz.tbi`). If not, use a script like the `bgzip_tabix_gvcf` one.
* **`sample_map.txt`**: A tab-separated file containing two columns: `sample_name` and `path/to/sample.g.vcf.gz`.

### Setup

1.  **Define `REF` Path**: In the script, change `REF=<reference fasta>` to the **actual full path** of your reference genome FASTA file.

2.  **Define `GVCF_DIR` Path**: Change `GVCF_DIR=<dir_for_gvariants>` to the **actual full path** where your input compressed and indexed gVCF files (`*.g.vcf.gz` and `*.g.vcf.gz.tbi`) are located.

3.  **Adjust `CHROMS` Array and SLURM Array Index**:
    * The `CHROMS` array in the script currently lists chromosomes `chr1` through `chr38` and `chrX`. **Ensure this array matches the exact names and order of chromosomes present in your reference genome and gVCFs.**
    * The `#SBATCH --array=1-39` line must be in sync with the number of chromosomes in your `CHROMS` array. If you have 38 autosomes and chrX, `1-39` is correct (39 total elements). If you have other chromosomes (e.g., `chrY`, `chrMT`), you'll need to add them to both `CHROMS` and adjust the `--array` range.

4.  **Create `sample_map.txt`**: This critical file maps sample IDs to their corresponding gVCF files. It should look like this:
    ```
    sample_A    /path/to/gvariants/sample_A.g.vcf.gz
    sample_B    /path/to/gvariants/sample_B.g.vcf.gz
    # ... and so on for all your samples
    ```
    You can generate this file automatically if your gVCFs are in `$GVCF_DIR` and named consistently:
    ```bash
    cd $GVCF_DIR
    ls *.g.vcf.gz | sed 's/.g.vcf.gz//' | awk '{print $1"\t"$1".g.vcf.gz"}' > sample_map.txt
    ```
    Make sure the paths in `sample_map.txt` are correct and accessible from the nodes running the job.

5.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time`: `24:00:00` (24 hours) is provided. GenomicsDBImport can be very time-consuming for large cohorts and dense chromosomes. Adjust this based on your expected runtime.
    * `--cpus-per-task`: `8` cores are allocated. `GenomicsDBImport` can utilize multiple threads effectively.
    * `--mem`: `40G` of memory is allocated. This tool is memory-intensive; ensure you provide enough.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `run_genomicsdb_import.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory where you saved `run_genomicsdb_import.sh`, and submit the job to SLURM:
    ```bash
    sbatch run_genomicsdb_import.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the directory from which you submit the job, named after the job ID and array task ID:

* `GDB_chr_JOBID_ARRAYINDEX.out`: Standard output for each chromosome's import process.
* `GDB_chr_JOBID_ARRAYINDEX.err`: Standard error for each chromosome's import process.

### GenomicsDB Workspaces

For each chromosome, a separate GenomicsDB workspace directory will be created under `$GVCF_DIR/output/genomicsdb/`. The directory will be named after the chromosome (e.g., `chr1`, `chrX`).

* `$GVCF_DIR/output/genomicsdb/chr1`
* `$GVCF_DIR/output/genomicsdb/chr2`
* ...
* `$GVCF_DIR/output/genomicsdb/chrX`

Each of these directories will contain the internal database files representing the combined gVCF data for that specific chromosome.

---

## Important Notes

* **File System**: `GenomicsDBImport` performs best on high-performance parallel file systems. Using `--genomicsdb-shared-posixfs-optimizations true` is helpful for standard POSIX file systems.
* **Temporary Files**: This tool generates substantial temporary files. Ensure `$GVCF_DIR/genomicsdb_chr*_tmp` has ample available disk space during job execution. The script automatically cleans up this temporary directory upon completion for each task.
* **Array Management**: It's absolutely critical that the `--array` range in your SLURM headers precisely matches the number of elements in your `CHROMS` array, and that `CHROMS` accurately reflects the chromosomes in your data and reference. Misconfiguration can lead to failed jobs or skipped chromosomes.
* **`-Xmx` and `-Xms`**: The Java options `-Xmx28g -Xms28g` explicitly set the maximum and initial heap sizes for the Java Virtual Machine. Ensure these values are less than the allocated `--mem` (`40G`) to leave room for other system processes.
