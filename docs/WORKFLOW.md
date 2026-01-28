# LP-WGS Pipeline Workflow

This document describes the complete workflow for the Low-Pass Whole Genome Sequencing (LP-WGS) pipeline.

## Pipeline Overview

```
Raw FASTQ → QC → Alignment → Processing → Variant Calling → Imputation
    │        │        │           │              │              │
    ↓        ↓        ↓           ↓              ↓              ↓
 Module 00  Module 00  Module 02  Module 05   Module 06    Module 09
```

## Step-by-Step Workflow

### Prerequisites

Before running the pipeline:

1. **Copy and configure** `config/pipeline.config.example` to `config/pipeline.config`
2. **Run validation** to check your setup:
   ```bash
   ./scripts/validate_setup.sh
   ```
3. **Create sample lists** as required by each module

---

### Module 00: FASTQ Quality Control

**Purpose:** Assess raw read quality before processing.

**Scripts:**
1. `fastqc.slurm` - Run FastQC on each sample
2. `multiqc.slurm` - Aggregate FastQC reports

**Input:**
- Raw FASTQ files (paired-end)
- `samples.txt` - Tab-delimited file: `R1_path<TAB>R2_path`

**Output:**
- `fastqc_results/` - Individual FastQC reports
- `multiqc_results/` - Aggregated HTML report

**Commands:**
```bash
# Create sample list
ls *_R1.fastq.gz | while read r1; do
    r2=${r1/_R1/_R2}
    echo -e "$r1\t$r2"
done > samples.txt

# Update array size in fastqc.slurm to match sample count
# Then submit
sbatch fastqc.slurm

# After FastQC completes, run MultiQC
sbatch multiqc.slurm
```

---

### Module 01: Reference Genome Indexing

**Purpose:** Create index files required for alignment and variant calling.

**Scripts:**
- `index_reference.slurm`

**Input:**
- Reference genome FASTA file

**Output:**
- `.dict` - Sequence dictionary (GATK)
- `.fai` - FASTA index (samtools)
- `.bwt`, `.pac`, `.ann`, `.amb`, `.sa` - BWA index files

**Commands:**
```bash
# Edit index_reference.slurm to set REF path
sbatch index_reference.slurm
```

**Note:** This only needs to be run once per reference genome.

---

### Module 02: Alignment

**Purpose:** Align reads to reference genome and calculate alignment statistics.

**Scripts:**
1. `bwa_align.slurm` - Align reads with BWA-MEM
2. `calculate_avg_depth.slurm` - Convert SAM→BAM, sort, and calculate coverage
3. `calculate_alignment_stats.slurm` - Generate alignment statistics
4. `extract_relevant_stats` - Extract key metrics from flagstat output

**Input:**
- Paired-end FASTQ files
- Indexed reference genome
- `fastq_file_pairs.txt` - Tab-delimited: `R1_path<TAB>R2_path`

**Output:**
- `*.sam` - SAM alignment files
- `*.sorted.bam` - Sorted BAM files
- `*.sorted.bam.bai` - BAM index files
- `coverage_summary.tsv` - Coverage statistics
- `flagstat_out/*.flagstat.txt` - Alignment statistics

**Commands:**
```bash
# Create file list
ls *_R1.fastq.gz | while read r1; do
    r2=${r1/_R1/_R2}
    echo -e "$r1\t$r2"
done > fastq_file_pairs.txt

# Submit alignment job
sbatch bwa_align.slurm

# After alignment, calculate coverage and stats
sbatch calculate_avg_depth.slurm
sbatch calculate_alignment_stats.slurm

# Extract relevant statistics
./extract_relevant_stats flagstat_out/*.flagstat.txt > alignment_summary.tsv
```

**Typical Coverage for LP-WGS:** 0.5x - 5x

---

### Module 04: Coverage Analysis

**Purpose:** Detailed coverage analysis across genomic regions.

**Scripts:**
- `calculate_depth.slurm`

---

### Module 05: BAM Processing

**Purpose:** Mark duplicates and optionally recalibrate base quality scores.

**Scripts:**
1. `dedup.slurm` - Mark duplicate reads
2. `bqsr.slurm` - Generate BQSR table (optional)
3. `apply_bqsr.slurm` - Apply BQSR (optional)
4. `collect_metrics.slurm` - Collect alignment metrics
5. `collect_insert_size.slurm` - Collect insert size metrics

**Input:**
- Sorted BAM files (or SAM files for dedup)
- Known sites VCF (for BQSR)

**Output:**
- `*_sorted_dedup_reads.bam` - Deduplicated BAM files
- `*_recal_data.table` - BQSR tables
- `*_sorted_dedup_bqsr_reads.bam` - Recalibrated BAM files (if BQSR applied)

**Commands:**
```bash
# Create file list
ls *.sam > sam_file_list.txt

# Mark duplicates
sbatch dedup.slurm

# OPTIONAL: BQSR (only for species with known variant sites)
# Create BAM list after dedup
ls deduplicated/*_sorted_dedup_reads.bam > bam_list.txt
sbatch bqsr.slurm
sbatch apply_bqsr.slurm
```

**Note on BQSR:** Base Quality Score Recalibration requires known variant sites and works best for well-annotated species (human, mouse). For other species, consider skipping BQSR.

---

### Module 06: Variant Calling

**Purpose:** Call variants and perform quality score recalibration.

**Scripts:**
1. `haplotypecaller_gvcf.slurm` - Call variants per sample (GVCF mode)
2. `genomic_DBImport.slurm` - Import GVCFs to GenomicsDB (per chromosome)
3. `genotype_gvcfs.slurm` - Joint genotyping (per chromosome)
4. `merge_index_jointvcf.slurm` - Merge and index joint VCF
5. `snp_VQSR.slurm` - Variant quality score recalibration (SNPs)
6. `apply_VQSR.slurm` - Apply VQSR filtering
7. `compressnblock.slurm` - Compress and index final VCF
8. `raw_variant_qc` - QC metrics extraction
9. `qc_plots.R` - Generate QC plots

**Input:**
- Deduplicated (and optionally recalibrated) BAM files
- Reference genome
- Known variants VCF (for VQSR)

**Output:**
- `*_raw_variants.g.vcf` - Per-sample GVCFs
- `genomicsdb/chr*` - GenomicsDB workspaces
- `chr*.vcf.gz` - Per-chromosome joint VCFs
- `joint_calls.vcf.gz` - Merged joint VCF
- `joint_calls.snps.recalibrated.vcf.gz` - VQSR-filtered VCF

**Commands:**
```bash
# Create BAM list
ls *_sorted_dedup_reads.bam > bam.list.txt

# Step 1: HaplotypeCaller
sbatch haplotypecaller_gvcf.slurm

# Step 2: Create sample map for GenomicsDBImport
ls *.g.vcf.gz | sed 's/.g.vcf.gz//' | awk '{print $1"\t"$1".g.vcf.gz"}' > sample_map.txt

# Step 3: GenomicsDBImport (per chromosome)
sbatch genomic_DBImport.slurm

# Step 4: Joint genotyping
sbatch genotype_gvcfs.slurm

# Step 5: Merge chromosome VCFs
sbatch merge_index_jointvcf.slurm

# Step 6: VQSR
sbatch snp_VQSR.slurm
sbatch apply_VQSR.slurm

# Step 7: Compress and index
sbatch compressnblock.slurm
```

---

### Module 09: Genotype Imputation

**Purpose:** Impute missing genotypes using a reference panel.

**Scripts:**
1. `beagle_impute.slurm` - Run BEAGLE imputation
2. `imputation_qual_extract.slurm` - Extract imputation quality metrics
3. `imputation_quality.R` - Analyze imputation quality

**Input:**
- VQSR-filtered VCF
- Reference panel (phased VCF)

**Output:**
- `imputed_genotypes.vcf.gz` - Imputed genotypes
- Imputation quality metrics (DR2)

**Commands:**
```bash
# Ensure you have a reference panel for your species
# Edit beagle_impute.slurm with correct paths
sbatch beagle_impute.slurm

# Extract quality metrics
sbatch imputation_qual_extract.slurm
```

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         LP-WGS ANALYSIS PIPELINE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  FASTQ   │───▶│  FastQC  │───▶│ MultiQC  │    │ Reference│              │
│  │  Files   │    │  (QC)    │    │ (Report) │    │ Indexing │              │
│  └──────────┘    └──────────┘    └──────────┘    └────┬─────┘              │
│       │                                               │                     │
│       │              ┌────────────────────────────────┘                     │
│       ▼              ▼                                                      │
│  ┌──────────────────────┐                                                   │
│  │   BWA Alignment      │                                                   │
│  │   (bwa_align.slurm)  │                                                   │
│  └──────────┬───────────┘                                                   │
│             │                                                               │
│             ▼                                                               │
│  ┌──────────────────────┐    ┌──────────────────────┐                      │
│  │  SAM → BAM → Sort    │───▶│  Coverage & Stats    │                      │
│  │  (calculate_avg_depth)│    │  (flagstat)          │                      │
│  └──────────┬───────────┘    └──────────────────────┘                      │
│             │                                                               │
│             ▼                                                               │
│  ┌──────────────────────┐                                                   │
│  │   Mark Duplicates    │                                                   │
│  │   (dedup.slurm)      │                                                   │
│  └──────────┬───────────┘                                                   │
│             │                                                               │
│             ├──────────────────────┐                                        │
│             │                      │ (Optional, for well-annotated species) │
│             ▼                      ▼                                        │
│  ┌──────────────────┐    ┌──────────────────┐                              │
│  │   Skip BQSR      │    │   BQSR + Apply   │                              │
│  └────────┬─────────┘    └────────┬─────────┘                              │
│           │                       │                                         │
│           └───────────┬───────────┘                                         │
│                       ▼                                                     │
│  ┌──────────────────────────────────────────┐                              │
│  │        HaplotypeCaller (GVCF mode)       │                              │
│  │        (haplotypecaller_gvcf.slurm)      │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│  ┌──────────────────────────────────────────┐                              │
│  │         GenomicsDBImport (per chr)       │                              │
│  │         (genomic_DBImport.slurm)         │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│  ┌──────────────────────────────────────────┐                              │
│  │         GenotypeGVCFs (per chr)          │                              │
│  │         (genotype_gvcfs.slurm)           │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│  ┌──────────────────────────────────────────┐                              │
│  │            Merge VCFs                     │                              │
│  │         (merge_index_jointvcf.slurm)      │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│  ┌──────────────────────────────────────────┐                              │
│  │         SNP VQSR + Apply                  │                              │
│  │    (snp_VQSR.slurm, apply_VQSR.slurm)    │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│  ┌──────────────────────────────────────────┐                              │
│  │         BEAGLE Imputation                 │                              │
│  │         (beagle_impute.slurm)             │                              │
│  └──────────────────┬───────────────────────┘                              │
│                     │                                                       │
│                     ▼                                                       │
│              FINAL VCF OUTPUT                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Resource Requirements

| Step | CPUs | Memory | Time (per sample) | Notes |
|------|------|--------|-------------------|-------|
| FastQC | 2 | 4G | 30-60 min | |
| BWA Alignment | 8 | 32G | 2-10 hrs | Depends on read count |
| Mark Duplicates | 8 | 64G | 4-24 hrs | Creates large temp files |
| BQSR | 8 | 64G | 4-24 hrs | Species-dependent |
| HaplotypeCaller | 8 | 32G | 4-24 hrs | |
| GenomicsDBImport | 8 | 40G | 1-24 hrs | Per chromosome |
| GenotypeGVCFs | 4 | 64G | 1-4 hrs | Per chromosome |
| VQSR | 4 | 32G | 1-12 hrs | Requires many samples |
| BEAGLE | 8 | 128G | 24-99 hrs | Depends on panel size |

## Troubleshooting

### Common Issues

1. **Array job index out of bounds**
   - Ensure array range matches sample count
   - Use 1-based indexing for SLURM arrays

2. **Out of memory errors**
   - Increase `--mem` in SLURM directives
   - For GATK tools, also adjust Java heap: `-Xmx`

3. **Temp file space issues**
   - Set `--tmp-dir` to a location with sufficient space
   - Limit concurrent array jobs with `%N` notation

4. **BQSR failing**
   - Ensure known sites VCF matches your reference
   - Consider skipping for non-model organisms

5. **VQSR failing**
   - Requires sufficient variant count (>30 samples recommended)
   - Ensure resource VCF is appropriate for your species

### Checking Job Status

```bash
# Check running jobs
squeue -u $USER

# Check job history
sacct -j <job_id>

# View job output
cat logs/<script>_<job_id>_<array_id>.out
```
