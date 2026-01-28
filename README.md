# Low-pass Whole Genome Sequencing (LP-WGS)

## Background

Traditional whole genome sequencing (WGS) relies on deep coverage—typically 30x to 50x—to capture nearly every base pair in an individual's genome. In contrast, shallow whole genome sequencing, also known as low-pass WGS (LP-WGS), sequences the genome at a much lower depth, usually between 0.1x and 5x coverage. Although this reduced coverage can miss some rare variants, it remains highly effective for detecting common genetic variations across the genome. Importantly, LP-WGS dramatically lowers both the cost and turnaround time for sequencing while still delivering valuable genomic insights.

In addition, when compared to genotyping arrays that only assess pre-selected genetic variants, LP-WGS offers increased statistical power and a broader view of the genome. LP-WGS can achieve up to 99% accuracy in variant detection and requires minimal DNA input.

This repository offers a modular, SLURM-compatible pipeline for low-pass sequencing analysis using GATK and related tools. The workflow encompasses raw data quality control, reference indexing, alignment, per-sample BAM QC, coverage estimation, duplicate marking, base quality score recalibration (BQSR), variant calling (GVCF and joint genotyping), variant filtering (VQSR), VCF merging, compression and indexing, and genotype imputation using BEAGLE.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/aa9gj/low-pass-WGS-pipeline.git
   cd low-pass-WGS-pipeline
   ```

2. **Configure the pipeline:**
   ```bash
   cp config/pipeline.config.example config/pipeline.config
   # Edit config/pipeline.config with your paths
   ```

3. **Validate your setup:**
   ```bash
   ./scripts/validate_setup.sh
   ```

4. **Follow the workflow:** See [docs/WORKFLOW.md](docs/WORKFLOW.md) for detailed instructions.

## Documentation

- **[WORKFLOW.md](docs/WORKFLOW.md)** - Complete step-by-step pipeline workflow
- **[DEPENDENCIES.md](docs/DEPENDENCIES.md)** - Software requirements and installation
- **[config/pipeline.config.example](config/pipeline.config.example)** - Configuration template

## Project Structure

```
low-pass-WGS-pipeline/
├── README.md                    # This file
├── config/
│   └── pipeline.config.example  # Configuration template
├── docs/
│   ├── WORKFLOW.md              # Detailed workflow documentation
│   └── DEPENDENCIES.md          # Software dependencies
├── scripts/
│   ├── common.sh                # Shared utility functions
│   └── validate_setup.sh        # Setup validation script
├── Modules/
│   ├── 00_fastq_qc/             # Quality control
│   ├── 01_reference/            # Reference indexing
│   ├── 02_alignment/            # Read alignment
│   ├── 04_coverage/             # Coverage analysis
│   ├── 05_processing/           # BAM processing
│   ├── 06_variant_calling/      # Variant calling
│   └── 09_imputation/           # Genotype imputation
└── tests/                       # Test suite
```

## Core Steps & Modules

1. Raw FASTQ QC (modules/00_fastq_qc)

   - trim_galore: Run adapter trimming and FastQC to catch adapter contamination and base quality issues.
   - MultiQC: Collate all fastqc reports. 

2. Reference Indexing (modules/01_reference)
   - index_reference.sh: BWA, samtools, and GATK dictionary/fai.

3. Alignment & Read Groups (modules/02_alignment)

   - bwa_align.slurm: Align reads with BWA-MEM, output to BAM.
   - Calculate_avg_depth.slurm: produce sorted bam files and calculate average depth
   - Calculate_alignment_stats.slurm: Check basic alignment stats including the number of reads mapped and properly paired
   - Extract_relevant_stats: Extract relevant information from calculate_alignment_stats.slurm and report as a tsv files. 

4. Coverage Estimation (modules/04_coverage)
   - calculate_depth.sh: Compute average and region-specific depth using samtools or mosdepth.

5. Post-Alignment Processing (modules/05_processing)
   - dedup.sh: Mark duplicates with Picard/GATK MarkDuplicates.
   - bqsr.sh: BaseRecalibrator (requires known-sites VCFs). Beware, only works for high confidence species (e.g. human/mouse)
   - apply_bqsr.sh: ApplyBQSR to recalibrate BAM. Beware, only works for high confidence species (e.g. human/mouse)
   - collect_insert_size:
   - collect_metrics:

6. Variant Calling & Genotyping (modules/06_variant_calling)
   - haplotypecaller_gvcf.sh: GATK HaplotypeCaller in -ERC GVCF mode.
   - genomicDBImport.sh: Create a joint variant db by chr
   - genotype_gvcfs.sh: GenotypeGVCFs to produce cohort VCF.
   - merge_index_jointvcf.slurm
   - qc_plots.R: Custom functions to evaluate qc of variant calling
   - raw_variant_qc.slurm
   - snp_VQSR.slurm
   - apply_VQSR.slurm

7. Genotype Imputation (modules/09_imputation)
   - beagle_impute.sh: Run BEAGLE with reference panel, genetic maps, and compute dosage R².

## Running the Tests

The optional tests use [bats](https://github.com/bats-core/bats-core). After installing `bats` (for example with `apt-get install bats`), run:

```bash
bats tests
```

This executes the test suite under the `tests/` directory.

## Requirements

- **SLURM** workload manager (for HPC cluster execution)
- **BWA** ≥0.7.17
- **SAMtools** ≥1.15
- **GATK** ≥4.3.0
- **Java** ≥17
- **BEAGLE** ≥5.4 (for imputation)

See [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) for complete requirements and installation instructions.

## License

This project is available for academic and research use.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.
