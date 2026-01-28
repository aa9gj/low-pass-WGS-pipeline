# LP-WGS Pipeline Dependencies

This document lists all software dependencies required to run the LP-WGS pipeline.

## Required Software

### Core Bioinformatics Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **BWA** | ≥0.7.17 | Read alignment | `conda install -c bioconda bwa` |
| **SAMtools** | ≥1.15 | BAM manipulation | `conda install -c bioconda samtools` |
| **BCFtools** | ≥1.15 | VCF manipulation | `conda install -c bioconda bcftools` |
| **htslib/tabix** | ≥1.15 | VCF indexing | `conda install -c bioconda htslib` |
| **GATK** | ≥4.3.0 | Variant calling | See GATK installation below |
| **Picard** | ≥2.27 | BAM processing | Bundled with GATK or separate install |

### Quality Control Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **FastQC** | ≥0.11.9 | Read QC | `conda install -c bioconda fastqc` |
| **MultiQC** | ≥1.14 | Report aggregation | `conda install -c bioconda multiqc` |

### Imputation Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **BEAGLE** | ≥5.4 | Genotype imputation | Download JAR from [BEAGLE website](https://faculty.washington.edu/browning/beagle/beagle.html) |

### Runtime Requirements

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **Java** | ≥17 | Required for GATK, BEAGLE |
| **Bash** | ≥4.0 | Shell scripts |

### Optional (for visualization/analysis)

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **R** | ≥4.0 | Statistical analysis, plotting | System package manager or conda |

#### R Packages Required

```r
# Install from CRAN
install.packages(c("tidyverse", "ggplot2", "data.table", "scales", "patchwork"))
```

---

## Installation Methods

### Method 1: Conda Environment (Recommended)

Create a conda environment with all dependencies:

```bash
# Create environment
conda create -n lpwgs-pipeline python=3.10

# Activate
conda activate lpwgs-pipeline

# Install bioinformatics tools
conda install -c bioconda -c conda-forge \
    bwa \
    samtools \
    bcftools \
    htslib \
    gatk4 \
    picard \
    fastqc \
    multiqc

# For R and packages
conda install -c conda-forge r-base r-tidyverse r-data.table
```

### Method 2: HPC Module System

Most HPC clusters provide software via module system:

```bash
# Example module loads (names vary by system)
module load bwa/0.7.17
module load samtools/1.17
module load gatk/4.4.0.0
module load java/17.0.9
module load fastqc/0.11.9
module load multiqc/1.14
module load R/4.2.0
```

### Method 3: Manual Installation

#### GATK Installation

```bash
# Download GATK
wget https://github.com/broadinstitute/gatk/releases/download/4.4.0.0/gatk-4.4.0.0.zip
unzip gatk-4.4.0.0.zip
export PATH=$PATH:/path/to/gatk-4.4.0.0

# Verify
gatk --version
```

#### BEAGLE Installation

```bash
# Download BEAGLE JAR
wget https://faculty.washington.edu/browning/beagle/beagle.jar

# No installation needed - run with java
java -jar beagle.jar
```

---

## Version Compatibility Notes

### Java Version

GATK 4.x requires Java 17 or later. If you have multiple Java versions:

```bash
# Check Java version
java -version

# On HPC, load specific version
module load java/17.0.9
```

### GATK Spark Tools

Some GATK Spark tools (like `MarkDuplicatesSpark`) require additional Spark configuration on some systems. If you encounter issues, consider using the non-Spark version:

```bash
# Instead of MarkDuplicatesSpark, use:
gatk MarkDuplicates -I input.bam -O output.bam -M metrics.txt
```

### Reference Panel for Imputation

BEAGLE requires a phased reference panel specific to your species:

- **Human**: 1000 Genomes, TOPMed, gnomAD
- **Dog**: Dog10K reference panel
- **Mouse**: Sanger Mouse Genomes Project
- **Other species**: May require custom panel creation

---

## Disk Space Requirements

| Data Type | Estimated Size |
|-----------|----------------|
| Raw FASTQ (per sample, PE) | 5-20 GB |
| SAM file (per sample) | 20-100 GB |
| BAM file (per sample) | 5-20 GB |
| GVCF file (per sample) | 1-5 GB |
| GenomicsDB (all samples) | 50-500 GB |
| Final VCF | 1-50 GB |
| Temporary files | 50-200 GB per concurrent job |

**Total estimated space per sample:** 50-150 GB (including intermediates)

---

## Testing Your Installation

Run the validation script to check all dependencies:

```bash
./scripts/validate_setup.sh
```

Or manually verify each tool:

```bash
# Check tool versions
bwa 2>&1 | head -3
samtools --version | head -1
bcftools --version | head -1
gatk --version
java -version
fastqc --version
multiqc --version
```

---

## Troubleshooting Dependency Issues

### "Command not found"

1. Check if the tool is installed: `which <tool>`
2. Load the appropriate module: `module load <tool>`
3. Activate conda environment: `conda activate lpwgs-pipeline`

### Java Version Mismatch

```bash
# Error: "UnsupportedClassVersionError"
# Solution: Use Java 17+
module load java/17.0.9
export JAVA_HOME=/path/to/java17
```

### GATK Memory Errors

```bash
# Error: "OutOfMemoryError"
# Solution: Increase Java heap
gatk --java-options "-Xmx30g" HaplotypeCaller ...
```

### Missing R Packages

```r
# In R session
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("data.table")) install.packages("data.table")
```

---

## Minimum System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU cores | 4 | 8+ |
| RAM | 32 GB | 64-128 GB |
| Storage | 500 GB | 2+ TB |
| OS | Linux (CentOS/Ubuntu) | Linux HPC cluster |

## Contact

For dependency-related issues specific to your HPC environment, consult your system administrators.
