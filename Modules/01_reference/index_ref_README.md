# Reference Genome Indexing Script for HPC

This repository contains a Slurm batch script designed to prepare a reference genome for downstream bioinformatics analyses, such as read alignment and variant calling. It automates the creation of index files required by popular tools like Picard, Samtools, and BWA.

## Overview

The `index_ref.sh` script performs three crucial indexing steps:

1.  **Picard `CreateSequenceDictionary`**: Generates a `.dict` file, which is often required by Picard tools and other GATK-related workflows.
2.  **Samtools `faidx`**: Creates a `.fai` index file, necessary for quickly accessing regions of the reference genome, commonly used by Samtools and other alignment/variant calling tools.
3.  **BWA `index`**: Builds BWA-specific index files, which are fundamental for aligning sequencing reads to the reference genome using BWA.

## Prerequisites

* **Picard:** Ensure Picard is installed and available in your environment, or can be loaded via a module system (as shown in the script with `module load picard`).
* **Samtools:** Ensure Samtools is installed and available (via `module load samtools`).
* **BWA:** Ensure BWA is installed and available (via `module load bwa`).
* **Slurm Workload Manager:** This script is designed for systems running Slurm.
* **Reference Genome:** You must have a FASTA-formatted reference genome file (`.fa` or `.fasta`).

## Usage

1.  **Place your Reference Genome:**
    Ensure your reference genome FASTA file is accessible on your HPC system.

2.  **Update the script:**
    Open `index_ref.sh` and replace `<genome.fa>` with the **full path and filename** of your reference genome FASTA file.

    Example:
    ```bash
    REF=/path/to/your/genome/my_reference.fa
    ```

3.  **Submit the job:**
    Navigate to the directory containing `index_ref.sh` on your HPC system, then submit the job using `sbatch`:

    ```bash
    sbatch index_ref.sh
    ```

## Script Configuration

You can adjust the following SBATCH directives in `index_ref.sh` based on your resource requirements and the size of your reference genome:

* `--job-name`: Name of your Slurm job.
* `--output`: Standard output file name pattern. `%j` is replaced by the job ID.
* `--error`: Standard error file name pattern.
* `--time`: Maximum wall-clock time for the job (e.g., `01:00:00` for 1 hour). Indexing large genomes can take longer.
* `--mem`: Memory allocation for the job (e.g., `8G` for 8 Gigabytes). Picard and BWA indexing can be memory-intensive for very large genomes.
* `--cpus-per-task`: Number of CPU cores allocated to the job. BWA indexing can benefit from multiple threads.

## Output

Upon successful completion, the script will generate the following index files in the same directory as your reference genome:

* A Picard sequence dictionary file: `your_genome.dict`
* A Samtools FASTA index file: `your_genome.fa.fai`
* Several BWA index files (e.g., `your_genome.fa.amb`, `your_genome.fa.ann`, `your_genome.fa.bwt`, `your_genome.fa.pac`, `your_genome.fa.sa`)
