# WGS-low-pass-sequencing-analysis

This repository provides a modular, SLURM-friendly pipeline for low-pass sequencing analysis using GATK and related tools. It covers raw data QC, reference indexing, alignment, per-sample BAM QC, coverage estimation, duplicate marking, base quality score recalibration (BQSR), variant calling (GVCF+joint genotyping), variant filtering, VCF merging, compression/indexing, and genotype imputation with BEAGLE.

## Core Steps & Modules

1. Raw FASTQ QC (modules/00_fastq_qc)

    *fastqc.sh: Run FastQC and collate with MultiQC.

    *Catch adapter contamination and base quality issues.

Reference Indexing (modules/01_reference)

index_reference.sh: BWA, samtools, and GATK dictionary/fai.

Alignment & Read Groups (modules/02_alignment)

add_read_groups.sh: Assign unique RG tags per sample.

bwa_align.sh: Align reads with BWA-MEM, output to BAM.

BAM QC Metrics (modules/03_bam_qc)

collect_metrics.sh: Picard/GATK CollectMultipleMetrics (insert size, duplication metrics).

Coverage Estimation (modules/04_coverage)

calculate_depth.sh: Compute average and region-specific depth using samtools or mosdepth.

Post-Alignment Processing (modules/05_processing)

dedup.sh: Mark duplicates with Picard/GATK MarkDuplicates.

bqsr.sh: BaseRecalibrator (requires known-sites VCFs).

apply_bqsr.sh: ApplyBQSR to recalibrate BAM.

Variant Calling & Genotyping (modules/06_variant_calling)

haplotypecaller_gvcf.sh: GATK HaplotypeCaller in -ERC GVCF mode.

combine_gvcfs.sh: CombineGVCFs for joint analysis.

genotype_gvcfs.sh: GenotypeGVCFs to produce cohort VCF.

variant_filtering.sh: Apply VQSR or hard filters to SNPs/INDELs.

VCF Merging & Indexing (modules/07_vcf_merge & 08_compress_index)

Merge per-sample or per-chromosome VCFs via bcftools merge (-m all).

Compress (bgzip) and index (tabix) final VCFs.

Genotype Imputation (modules/09_imputation)

beagle_impute.sh: Run BEAGLE with reference panel, genetic maps, and compute dosage R².
