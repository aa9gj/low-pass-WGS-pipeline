VCF Quality Control and Visualization with R
This repository contains an R script designed to perform quality control and visualization of Variant Call Format (VCF) files. It leverages bcftools query output (generated as described in the previous section) to create informative plots for assessing the quality of your variant calls.

The script generates several plots, including distributions of variant quality (QUAL), mean depth per sample (DP), genotype quality (GQ), quality by depth (QD), and allele balance (AD). These visualizations are crucial for identifying potential issues in your sequencing data and variant calling pipeline.

Prerequisites
Before running this script, ensure you have:

R installed: A statistical programming language environment.

R packages installed: The script relies on tidyverse, ggplot2, scales, patchwork, and data.table. You can install them using:

install.packages(c("tidyverse", "ggplot2", "scales", "patchwork", "data.table"))

VCF metrics extracted: You must have previously extracted the necessary metrics from your VCF file into plain text files using bcftools query. The script expects the following files in the specified datapath:

joint_calls_site_qual.txt

joint_calls_sample_dp.txt

joint_calls_sample_gq.txt

joint_calls_info_metrics.txt

joint_calls_sample_ad.txt

(Refer to the previous documentation on "Extracting VCF Metrics to Text Files (using bcftools)" for details on generating these files).

Usage
Clone this repository (or copy the R script).

Adjust the datapath variable in the R script to point to the directory containing your bcftools output files.

Run the R script in your R environment (e.g., RStudio, or from the terminal using Rscript your_script_name.R).

Rscript vcf_qc_plots.R

The script will generate a PNG file named combined_qc_plots.png in the same directory where you run the script.

R Script: vcf_qc_plots.R
# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(scales)
library(patchwork) # For combining plots
library(data.table)

# --- Configuration ---
# Set the path to your VCF metrics text files
datapath <- "/old-home/shared-folder/arby/wrk/low_pass_WGS_canine_Oct2024/alignment_bwa/deduplicated/gvariants/output/genotypes/"

# --- Common Plotting Theme Variables ---
# You can adjust these values to customize the appearance of your plots
hist_fill_color <- "skyblue"
hist_border_color <- "black"
filter_line_color <- "red"
median_line_color <- "blue"
annotation_color <- "darkgrey"
line_size <- 0.8
binwidth_qual <- 10 # Bin width for QUAL histogram
binwidth_gq <- 5    # Bin width for GQ histogram
binwidth_qd <- 0.5   # Bin width for QD histogram
binwidth_ab <- 0.05  # Bin width for Allele Balance histogram

# --- Data Loading ---
# Using data.table's fread for potentially faster loading
# Ensure the file paths are correct based on your 'datapath'
df_qual <- fread(file.path(datapath, "joint_calls_site_qual.txt"), col.names = c("CHROM", "POS", "QUAL")) %>%
  filter(!is.na(QUAL)) # Filter out NA QUAL values
df_sample_dp <- fread(file.path(datapath, "joint_calls_sample_dp.txt"), col.names = c("CHROM", "POS", "SAMPLE", "DP"))
df_sample_gq <- fread(file.path(datapath, "joint_calls_sample_gq.txt"), col.names = c("CHROM", "POS", "SAMPLE", "GQ")) %>%
  filter(!is.na(GQ)) # Filter out NA GQ values
df_info <- fread(file.path(datapath, "joint_calls_info_metrics.txt"), col.names = c("CHROM", "POS", "QD", "FS", "SOR", "MQ", "ReadPosRankSum", "MQRankSum"))
df_qd <- df_info %>% filter(!is.na(QD)) # Extract QD for its specific plot and filter NA QD values
df_ad <- fread(file.path(datapath, "joint_calls_sample_ad.txt"), col.names = c("CHROM", "POS", "SAMPLE", "AD_String"))

# --- Plot 1: Distribution of Variant Quality (QUAL) ---
# Visualizes the distribution of QUAL scores, with a focus on lower values.
# A dashed red line indicates a common filter threshold (QUAL=30).
manual_qual_upper_limit_zoom <- 750 # Cap the x-axis for better visualization of lower QUAL values
variants_above_zoom_limit <- df_qual %>% filter(QUAL > manual_qual_upper_limit_zoom) %>% nrow()
total_variants <- nrow(df_qual)
percentage_above_zoom_limit <- (variants_above_zoom_limit / total_variants) * 100
median_qual <- median(df_qual$QUAL, na.rm = TRUE)

p1 <- ggplot(df_qual, aes(x = QUAL)) +
  geom_histogram(binwidth = binwidth_qual, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 30, linetype = "dashed", color = filter_line_color, linewidth = line_size) +
  geom_vline(xintercept = median_qual, linetype = "dotted", color = median_line_color, linewidth = line_size) +
  annotate("text", x = median_qual + 0.10 * manual_qual_upper_limit_zoom, y = Inf, vjust = 1.2, label = paste0("Median: ", round(median_qual, 0)), color = median_line_color, size = 3) +
  labs(title = "(1) Distribution of Variant Quality (QUAL)",
       subtitle = paste0("X-axis capped at ", manual_qual_upper_limit_zoom, " (", round(percentage_above_zoom_limit, 2), "% of variants above this)"),
       x = "QUAL Score",
       y = "Number of Variants") +
  theme_minimal() +
  scale_x_continuous(breaks = pretty_breaks(n = 10), limits = c(0, manual_qual_upper_limit_zoom))

# Add annotation if variants are clipped by the x-axis limit
if (variants_above_zoom_limit > 0) {
  p1 <- p1 + annotate("text",
                       x = manual_qual_upper_limit_zoom * 0.8,
                       y = max(ggplot_build(p1)$data[[1]]$count) * 0.9,
                       label = paste0(variants_above_zoom_limit, " variants clipped"),
                       color = annotation_color, size = 3.5)
}
rm(df_qual) # Remove df_qual to free up memory

# --- Plot 2: Mean Depth (DP) per Sample ---
# Displays the average sequencing depth for each sample.
df_sample_dp$DP <- as.numeric(df_sample_dp$DP) # Ensure DP is numeric
mean_dp_per_sample <- df_sample_dp %>%
  group_by(SAMPLE) %>%
  summarise(Mean_DP = mean(DP, na.rm = TRUE))

p2 <- ggplot(mean_dp_per_sample, aes(x = SAMPLE, y = Mean_DP)) +
  geom_col(fill = hist_fill_color, color = hist_border_color) +
  labs(title = "(2) Mean Depth (DP) per Sample",
       x = "Sample ID",
       y = "Mean DP") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Rotate and size sample labels
        legend.position = "none")
rm(df_sample_dp) # Remove df_sample_dp to free up memory

# --- Plot 3: Distribution of Genotype Quality (GQ) ---
# Shows the distribution of genotype quality scores across all samples.
# A dashed red line indicates a common filter threshold (GQ=20).
gq_upper_limit <- quantile(df_sample_gq$GQ, 0.999, na.rm = TRUE) # Set upper limit based on 99.9th percentile
if (gq_upper_limit > 99) { gq_upper_limit <- 99 } # Cap at 99 if percentile is higher

genotypes_below_20 <- df_sample_gq %>% filter(GQ < 20) %>% nrow()
total_genotypes <- nrow(df_sample_gq)
percentage_below_20 <- (genotypes_below_20 / total_genotypes) * 100

p3 <- ggplot(df_sample_gq, aes(x = GQ)) +
  geom_histogram(binwidth = binwidth_gq, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 20, linetype = "dashed", color = filter_line_color, size = line_size) +
  labs(title = "(3) Distribution of Genotype Quality (GQ)",
       subtitle = paste0(round(percentage_below_20, 2), "% of genotypes fall below GQ=20"),
       x = "GQ Score",
       y = "Number of Genotypes") +
  theme_minimal() +
  scale_x_continuous(breaks = pretty_breaks(n = 10), limits = c(0, gq_upper_limit))
rm(df_sample_gq) # Remove df_sample_gq to free up memory

# --- Plot 4: Distribution of Quality by Depth (QD) ---
# Illustrates the distribution of Quality by Depth scores.
# A dashed red line indicates a common filter threshold (QD=2.0).
qd_upper_limit <- quantile(df_qd$QD, 0.995, na.rm = TRUE) # Set upper limit based on 99.5th percentile

p4 <- ggplot(df_qd, aes(x = QD)) +
  geom_histogram(binwidth = binwidth_qd, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 2.0, linetype = "dashed", color = filter_line_color, size = line_size) +
  labs(title = "(4) Distribution of Quality by Depth (QD)",
       x = "QD Score",
       y = "Number of Variants") +
  theme_minimal() +
  scale_x_continuous(limits = c(0, qd_upper_limit), breaks = pretty_breaks(n = 10))
rm(df_qd) # Remove df_qd to free up memory
rm(df_info) # Remove df_info as QD has been extracted

# --- Plot 5: Distribution of Allele Balance (AD - for heterozygotes) ---
# Shows the distribution of allele balance for heterozygous genotypes with sufficient read depth.
# A dashed red line at 0.5 indicates ideal balance.
df_ad_parsed <- df_ad %>%
  separate(AD_String, into = c("AD_REF", "AD_ALT"), sep = ",", convert = TRUE) %>%
  filter(!is.na(AD_REF) & !is.na(AD_ALT) & (AD_REF + AD_ALT) > 0) %>% # Filter out NA and zero total depth
  mutate(Total_AD = AD_REF + AD_ALT,
         Allele_Balance = AD_ALT / Total_AD)

df_het_ab <- df_ad_parsed %>% filter(Total_AD >= 5) # Filter for sites with at least 5 total reads for AD calculation

p5 <- ggplot(df_het_ab, aes(x = Allele_Balance)) +
  geom_histogram(binwidth = binwidth_ab, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = filter_line_color, size = line_size) +
  labs(title = "(5) Distribution of Allele Balance (AD)",
       x = "Allele Balance (ALT / Total Reads)",
       y = "Number of Genotypes") +
  theme_minimal() +
  scale_x_continuous(breaks = seq(0, 1, by = 0.1), limits = c(0, 1))
rm(df_ad) # Remove df_ad to free up memory
rm(df_ad_parsed) # Remove df_ad_parsed to free up memory
rm(df_het_ab) # Remove df_het_ab to free up memory

# --- Combine Plots using patchwork ---
# Arranges the individual plots into a multi-panel layout for a comprehensive overview.
# The layout is designed for 5 plots in a 3-row, 2-column structure, with the last plot spanning the bottom row.
combined_plot <- (p1 + p2) / (p3 + p4) / p5 +
  plot_layout(guides = 'collect') & # Collects any shared legends
  theme(plot.title = element_text(size = 12, face = "bold"), # Adjust title font size and style
        plot.subtitle = element_text(size = 9)) # Adjust subtitle font size

# Print the combined plot to the RStudio plot viewer (if running interactively)
print(combined_plot)

# --- Save the combined plot to a file ---
# Saves the generated plot as a high-resolution PNG image.
# Adjust 'width' and 'height' as needed based on the number of samples and desired output size.
ggsave("combined_qc_plots.png", combined_plot, width = 12, height = 15, dpi = 300)

message("Combined QC plots saved as combined_qc_plots.png")

Expected Output
Upon successful execution, the script will generate a PNG image file named combined_qc_plots.png in the same directory. This image will contain five sub-plots:

Distribution of Variant Quality (QUAL): A histogram showing the frequency of different QUAL scores.

Mean Depth (DP) per Sample: A bar chart displaying the average sequencing depth for each individual sample.

Distribution of Genotype Quality (GQ): A histogram illustrating the frequency of various GQ scores.

Distribution of Quality by Depth (QD): A histogram showing the distribution of QD scores.

Distribution of Allele Balance (AD): A histogram depicting the allele balance for heterozygous genotypes.

These plots provide a quick and effective way to assess the overall quality of your VCF data and identify any samples or variants that may require further investigation or filtering.
