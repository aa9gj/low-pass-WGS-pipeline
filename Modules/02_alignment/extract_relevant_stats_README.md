# Flagstat Report Generator

This simple Bash script helps you quickly summarize key mapping statistics from multiple `samtools flagstat` output files. It's designed to give you a clear, tab-separated overview of your sequencing samples.

---

## What It Does

The script scans the current directory for files ending in `.flagstat.txt`. For each file, it extracts the following information:

* **Total Reads**: The total number of reads in the sample.
* **Percent Mapped**: The percentage of reads that successfully mapped to the reference genome.
* **Percent Properly Paired**: For paired-end reads, the percentage that mapped as proper pairs.
* **Percent Singletons**: The percentage of reads that are singletons (reads whose mate did not map).

It then prints these statistics to your terminal in a neat, table-like format with a header.

---

## How to Use It

1.  **Prepare your `flagstat` files**: Make sure all your `samtools flagstat` output files (e.g., `sample1.flagstat.txt`, `project_X.flagstat.txt`) are in the same directory where you plan to run this script. If you don't have them yet, you can generate them like this:
    ```bash
    samtools flagstat your_aligned_reads.bam > your_sample_name.flagstat.txt
