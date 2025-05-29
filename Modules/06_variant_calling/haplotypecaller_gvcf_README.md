# GATK HaplotypeCaller (gVCF Mode) Workflow (SLURM Optimized)

This SLURM-enabled Bash script automates individual sample variant calling using GATK's `HaplotypeCaller` in gVCF mode. It's designed for efficient parallel processing of multiple BAM files on High-Performance Computing (HPC) clusters, generating an intermediate gVCF file for each sample, which is crucial for subsequent joint genotyping.

---

## What It Does

For each BAM file listed in `bam.list.txt`, the script performs the following:

1.  **Loads Java Module**: Ensures the correct Java environment (Java 17.0.9 in this example) is loaded, a core dependency for GATK.
2.  **Defines Paths**: Sets up paths for the reference genome, input BAM files, and the output gVCF files.
3.  **Extracts Sample Name**: Automatically derives the sample name from the input BAM file path.
4.  **Runs HaplotypeCaller**: Executes `gatk HaplotypeCaller` with the following key settings:
    * `-ERC GVCF`: Specifies the output format as gVCF (Genomic Variant Call Format), which includes variant calls and genotype likelihoods even at non-variant sites. This is essential for accurate joint genotyping of multiple samples later.
    * `-R`: Provides the reference genome.
    * `-I`: Specifies the input BAM file.
    * `-O`: Defines the path for the output gVCF file.

This workflow is optimized for parallel execution across numerous samples using SLURM's array job functionality.

---

## How to Use It

### Prerequisites

* **GATK**: Make sure GATK is installed and available in your environment's `PATH`.
* **Java 17.0.9**: The script specifically loads this version. Adjust `ml java/17.0.9` if your cluster uses a different module name or GATK requires a different Java version.
* **SLURM Workload Manager**: This script is designed for SLURM-managed clusters.
* **Reference Genome**: A FASTA file of the reference genome used for alignment (e.g., `canFam4.fa`).
* **Input BAM files**: You should have sorted and deduplicated BAM files ready. These are typically the output of alignment and duplicate marking steps.

### Setup

1.  **Define `bam.list.txt`**: This file should contain the **full path** to each input BAM file, with one path per line. For example:
    ```
    /home/user/project/sample_01_sorted_dedup_bqsr_reads.bam
    /home/user/project/sample_02_sorted_dedup_bqsr_reads.bam
    # ... and so on for all your samples
    ```
    Place this `bam.list.txt` file in the directory from which you will submit the SLURM job.

2.  **Update SLURM Array Index**:
    * `#SBATCH --array=1-40`: This example runs 40 tasks.
    * **Modify `40`**: Replace `40` with the **total number of BAM files** listed in your `bam.list.txt`.

3.  **Verify Paths in Script**:
    * `ref="/home/arbya/shared-folder/arby/wrk/low_pass_WGS_canine_Oct2024/canFam4.fa"`: **Ensure this path is correct** and points to your reference genome FASTA file.
    * `output_dir=/home/arbya/shared-folder/arby/wrk/low_pass_WGS_canine_Oct2024/alignment_bwa/deduplicated`: **Ensure this path is correct** and is the desired location for your output gVCF files. The script will write the gVCFs to this directory.

4.  **Adjust SLURM Resources (Optional but Recommended)**:
    * `--time=24:00:00`: This sets the time limit to 24 hours. `HaplotypeCaller` can be computationally intensive, especially for high-coverage data or complex genomic regions. Adjust this based on your expected runtime per sample.
    * `--cpus-per-task=8`: 8 CPU cores are allocated per task. `HaplotypeCaller` can utilize multiple threads effectively.
    * `--mem=32G`: 32GB of memory is allocated per task. This tool can be memory-intensive; ensure you provide enough.

### Running the Script

1.  **Save the script**: Save the provided Bash script content to a file, for example, `run_haplotype_caller.sh`.
2.  **Submit the job**: From your cluster's login node, navigate to the directory containing your `run_haplotype_caller.sh` script and `bam.list.txt`, then submit the job to SLURM:
    ```bash
    sbatch run_haplotype_caller.sh
    ```

---

## Output

### Log Files

SLURM will create log files in the current directory (or a specified `logs/` subdirectory if configured in `output` and `error` paths) for each array task. These logs are crucial for monitoring and debugging:

* `out`: Standard output for each task.
* `err`: Standard error for each task.

### gVCF Output Files

For each input BAM file, a new gVCF file will be generated in the specified `output_dir`:

* `sample_name_raw_variants.g.vcf`: The gVCF file for the individual sample, containing variant calls and genotype likelihoods.

These gVCF files are then typically used as input for the `GenomicsDBImport` step, followed by `GenotypeGVCFs` for joint genotyping across the entire cohort.

---

## Important Notes

* **Sample Naming**: The script extracts the `sample_name` by taking the part of the BAM file name before the first underscore (`cut -d '_' -f 1`). If your BAM files have a different naming convention, you'll need to modify this line to correctly extract the sample name.
* **Output Directory**: Ensure the specified `output_dir` exists and has appropriate write permissions before running the script.
* **Java Memory**: The script does not explicitly set Java Xmx/Xms options for `HaplotypeCaller`. GATK will use default values or infer from the `--mem` SLURM allocation. If you encounter memory issues, you might add `-Xmx` options to the `gatk` command directly (e.g., `gatk --java-options "-Xmx28g"`).
* **Intermediate Files**: The gVCF files generated by this step are crucial intermediate files for a standard GATK Best Practices workflow. Do not delete them until joint genotyping is complete.
