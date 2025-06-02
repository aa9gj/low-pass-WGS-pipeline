Extracting VCF Metrics to Text Files (using bcftools)
These commands use bcftools query to extract specific metrics from your VCF file and save them into plain text files. These text files can then be easily read and processed by other tools, such as R for quality control and visualization.

Important: Ensure you are using your raw.vcf.gz file for initial quality control. Run these commands in your terminal (not within an R environment).

Commands for Extraction:
a. Extract DP (Depth) per site (from INFO field)
This command extracts the DP (Depth) information, which typically represents the total depth at a site, from the INFO field of your VCF file.

bcftools query -f '%CHROM\t%POS\t%INFO/DP\n' raw.vcf.gz > raw_site_dp.txt

b. Extract DP (Depth) per sample (from FORMAT field)
This command extracts the DP (Depth) for each individual sample at each site from the FORMAT field.

bcftools query -f '[%CHROM\t%POS\t%SAMPLE\t%DP\n]' raw.vcf.gz > raw_sample_dp.txt

c. Extract GQ (Genotype Quality) per sample
This command extracts the GQ (Genotype Quality) for each sample, indicating the confidence of the genotype call.

bcftools query -f '[%CHROM\t%POS\t%SAMPLE\t%GQ\n]' raw.vcf.gz > raw_sample_gq.txt

d. Extract QUAL (Variant Quality)
This command extracts the overall QUAL (Variant Quality) score for each variant site.

bcftools query -f '%CHROM\t%POS\t%QUAL\n' raw.vcf.gz > raw_site_qual.txt

e. Extract AD (Allelic Depths) for each sample
This command extracts the AD (Allelic Depths) for each sample, which provides the depth of reads supporting each allele (reference and alternate).

bcftools query -f '[%CHROM\t%POS\t%SAMPLE\t%AD\n]' raw.vcf.gz > raw_sample_ad.txt

f. Extract QD, FS, SOR, MQ, ReadPosRankSum, MQRankSum (from INFO field)
This command extracts several common variant quality metrics from the INFO field into a single file for convenience. These metrics are often used to filter variants:

QD: Quality by Depth

FS: Fisher Strand

SOR: Symmetric Odds Ratio

MQ: Mapping Quality

ReadPosRankSum: Z-score from Wilcoxon rank sum test of the position of the first base of reads supporting the reference allele and reads supporting the alternate allele

MQRankSum: Z-score from Wilcoxon rank sum test of the mapping qualities of reads supporting the reference allele and reads supporting the alternate allele

bcftools query -f '%CHROM\t%POS\t%INFO/QD\t%INFO/FS\t%INFO/SOR\t%INFO/MQ\t%INFO/ReadPosRankSum\t%INFO/MQRankSum\n' raw.vcf.gz > raw_site_info_metrics.txt
