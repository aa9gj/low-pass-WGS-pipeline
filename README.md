# Low-pass Whole Genome Sequencing (LP-WGS)

## Background 

Traditional whole genome sequencing (WGS) relies on deep coverage—typically 30x to 50x—to capture nearly every base pair in an individual's genome. In contrast, shallow whole genome sequencing, also known as low-pass WGS (LP-WGS), sequences the genome at a much lower depth, usually between 0.1x and 5x coverage. Although this reduced coverage can miss some rare variants, it remains highly effective for detecting common genetic variations across the genome. Importantly, LP-WGS dramatically lowers both the cost and turnaround time for sequencing while still delivering valuable genomic insights.

In addition, when compared to genotyping arrays that only assess pre-selected genetic variants, LP-WGS offers increased statistical power and a broader view of the genome. LP-WGS can achieve up to 99% accuracy in variant detection and requires minimal DNA input.

This repository offers a modular, SLURM-compatible pipeline for low-pass sequencing analysis using GATK and related tools. The workflow encompasses raw data quality control, reference indexing, alignment, per-sample BAM QC, coverage estimation, duplicate marking, base quality score recalibration (BQSR), variant calling (GVCF and joint genotyping), variant filtering (VQSR), VCF merging, compression and indexing, and genotype imputation using BEAGLE.

## Core Steps & Modules

1. Raw FASTQ QC (modules/00_fastq_qc)

   - fastqc.sh: Run FastQC and collate with MultiQC.
   - Catch adapter contamination and base quality issues.

2. Reference Indexing (modules/01_reference)
   - index_reference.sh: BWA, samtools, and GATK dictionary/fai.

3. Alignment & Read Groups (modules/02_alignment)

   - add_read_groups.sh: Assign unique RG tags per sample.
   - bwa_align.sh: Align reads with BWA-MEM, output to BAM.

4. BAM QC Metrics (modules/03_bam_qc)
   - collect_metrics.sh: Picard/GATK CollectMultipleMetrics (insert size, duplication metrics).

5. Coverage Estimation (modules/04_coverage)
   - calculate_depth.sh: Compute average and region-specific depth using samtools or mosdepth.

6. Post-Alignment Processing (modules/05_processing)
   - dedup.sh: Mark duplicates with Picard/GATK MarkDuplicates.
   - bqsr.sh: BaseRecalibrator (requires known-sites VCFs). Beware, only works for high confidence species (e.g. human/mouse)
   - apply_bqsr.sh: ApplyBQSR to recalibrate BAM. Beware, only works for high confidence species (e.g. human/mouse)

7. Variant Calling & Genotyping (modules/06_variant_calling)

   - haplotypecaller_gvcf.sh: GATK HaplotypeCaller in -ERC GVCF mode.
   - genomicDBImport.sh: Create a joint variant db by chr
   - genotype_gvcfs.sh: GenotypeGVCFs to produce cohort VCF.
   - variant_filtering.sh: Apply VQSR or hard filters to SNPs/INDELs. Beware, only works for high confidence species (e.g. human/mouse)

8. Genotype Imputation (modules/09_imputation)
   - beagle_impute.sh: Run BEAGLE with reference panel, genetic maps, and compute dosage R².
