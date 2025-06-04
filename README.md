# Low-pass Whole Genome Sequencing (LP-WGS)

## Background 

Traditional whole genome sequencing (WGS) relies on deep coverage—typically 30x to 50x—to capture nearly every base pair in an individual's genome. In contrast, shallow whole genome sequencing, also known as low-pass WGS (LP-WGS), sequences the genome at a much lower depth, usually between 0.1x and 5x coverage. Although this reduced coverage can miss some rare variants, it remains highly effective for detecting common genetic variations across the genome. Importantly, LP-WGS dramatically lowers both the cost and turnaround time for sequencing while still delivering valuable genomic insights.

In addition, when compared to genotyping arrays that only assess pre-selected genetic variants, LP-WGS offers increased statistical power and a broader view of the genome. LP-WGS can achieve up to 99% accuracy in variant detection and requires minimal DNA input.

This repository offers a modular, SLURM-compatible pipeline for low-pass sequencing analysis using GATK and related tools. The workflow encompasses raw data quality control, reference indexing, alignment, per-sample BAM QC, coverage estimation, duplicate marking, base quality score recalibration (BQSR), variant calling (GVCF and joint genotyping), variant filtering (VQSR), VCF merging, compression and indexing, and genotype imputation using BEAGLE.

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
