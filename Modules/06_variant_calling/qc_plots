# Load necessary libraries
library(tidyverse)
library(ggplot2)
library(scales)
library(patchwork) # For combining plots
library(data.table)

# Load sample DP data
datapath <- "/PATH/TO/DATA"
# --- Data Loading (using datapath and file.path()) ---
# Using data.table's fread for potentially faster loading given that it uses 32 threads. 
df_qual <- fread(file.path(datapath, "joint_calls_site_qual.txt"), col.names = c("CHROM", "POS", "QUAL")) %>% filter(!is.na(QUAL))
df_sample_dp <- fread(file.path(datapath, "joint_calls_sample_dp.txt"), col.names = c("CHROM", "POS", "SAMPLE", "DP"))
df_sample_gq <- fread(file.path(datapath, "joint_calls_sample_gq.txt"), col.names = c("CHROM", "POS", "SAMPLE", "GQ")) %>% filter(!is.na(GQ))
df_info <- fread(file.path(datapath, "joint_calls_info_metrics.txt"), col.names = c("CHROM", "POS", "QD", "FS", "SOR", "MQ", "ReadPosRankSum", "MQRankSum"))
df_qd <- df_info %>% filter(!is.na(QD)) # Extract QD for its plot
df_ad <- fread(file.path(datapath, "joint_calls_sample_ad.txt"), col.names = c("CHROM", "POS", "SAMPLE", "AD_String"))

# --- Common Plotting Theme Variables ---
# You can adjust these if you like
hist_fill_color <- "skyblue"
hist_border_color <- "black"
filter_line_color <- "red"
median_line_color <- "blue"
annotation_color <- "darkgrey"
line_size <- 0.8
binwidth_qual <- 10 # Adjusted for zoomed-in QUAL
binwidth_gq <- 5
binwidth_qd <- 0.5
binwidth_ab <- 0.05


# --- Plot 1: Distribution of Variant Quality (QUAL) ---
manual_qual_upper_limit_zoom <- 750 # Adjust as needed based on your data observations
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

if (variants_above_zoom_limit > 0) {
  p1 <- p1 + annotate("text",
                      x = manual_qual_upper_limit_zoom * 0.8,
                      y = max(ggplot_build(p1)$data[[1]]$count) * 0.9,
                      label = paste0(variants_above_zoom_limit, " variants clipped"),
                      color = annotation_color, size = 3.5)
}

rm(df_qual)
# --- Plot 2: Mean Depth (DP) per Sample ---
df_sample_dp$DP <- as.numeric(df_sample_dp$DP)
mean_dp_per_sample <- df_sample_dp %>%
  group_by(SAMPLE) %>%
  summarise(Mean_DP = mean(DP, na.rm = TRUE))

p2 <- ggplot(mean_dp_per_sample, aes(x = SAMPLE, y = Mean_DP)) +
  geom_col(fill = hist_fill_color, color = hist_border_color) +
  labs(title = "(2) Mean Depth (DP) per Sample",
       x = "Sample ID",
       y = "Mean DP") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), # Adjusted font size for sample names
        legend.position = "none")

rm(df_sample_dp)
# --- Plot 3: Distribution of Genotype Quality (GQ) ---
gq_upper_limit <- quantile(df_sample_gq$GQ, 0.999, na.rm = TRUE)
if (gq_upper_limit > 99) { gq_upper_limit <- 99 } # Cap at 99

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


# --- Plot 4: Distribution of Quality by Depth (QD) ---
qd_upper_limit <- quantile(df_qd$QD, 0.995, na.rm = TRUE) # 99.5th percentile for QD

p4 <- ggplot(df_qd, aes(x = QD)) +
  geom_histogram(binwidth = binwidth_qd, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 2.0, linetype = "dashed", color = filter_line_color, size = line_size) +
  labs(title = "(4) Distribution of Quality by Depth (QD)",
       x = "QD Score",
       y = "Number of Variants") +
  theme_minimal() +
  scale_x_continuous(limits = c(0, qd_upper_limit), breaks = pretty_breaks(n = 10))


# --- Plot 5: Distribution of Allele Balance (AD - for heterozygotes) ---
df_ad_parsed <- df_ad %>%
  separate(AD_String, into = c("AD_REF", "AD_ALT"), sep = ",", convert = TRUE) %>%
  filter(!is.na(AD_REF) & !is.na(AD_ALT) & (AD_REF + AD_ALT) > 0) %>%
  mutate(Total_AD = AD_REF + AD_ALT,
         Allele_Balance = AD_ALT / Total_AD)

df_het_ab <- df_ad_parsed %>% filter(Total_AD >= 5) # Filter for sites with enough reads

p5 <- ggplot(df_het_ab, aes(x = Allele_Balance)) +
  geom_histogram(binwidth = binwidth_ab, fill = hist_fill_color, color = hist_border_color) +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = filter_line_color, size = line_size) +
  labs(title = "(5) Distribution of Allele Balance (AD)",
       x = "Allele Balance (ALT / Total Reads)",
       y = "Number of Genotypes") +
  theme_minimal() +
  scale_x_continuous(breaks = seq(0, 1, by = 0.1), limits = c(0, 1))


# --- Combine Plots using patchwork ---
# Arrange in two columns. The layout depends on how many samples you have for p2.
# If you have many samples, p2 might be wide, so it's good to give it more space or put it on its own row.
# Let's try 3 rows, 2 columns.
# (p1 | p2) / (p3 | p4) / p5 # This would put p5 spanning both columns on the last row

# A more flexible layout for 5 plots in 2 columns.
# We'll stack the first 4 in two columns, and the 5th can go below.
# Or, arrange them 3 on top, 2 on bottom to fill better.
# Let's try:
# P1 P2
# P3 P4
# P5 . (P5 takes full width on the last row)

combined_plot <- (p1 + p2) / (p3 + p4) / p5 +
  plot_layout(guides = 'collect') & # Collect legends if any (though we removed them)
  theme(plot.title = element_text(size = 12, face = "bold"),
        plot.subtitle = element_text(size = 9)) # Adjust overall title/subtitle size

# Print to RStudio plot viewer
print(combined_plot)

# --- Save the combined plot to a file ---
# Adjust width and height as needed to make labels readable for your number of samples.
# For Google Docs, PNG is generally good, PDF for higher quality.
ggsave("combined_qc_plots.png", combined_plot, width = 12, height = 15, dpi = 300)
# ggsave("combined_qc_plots.pdf", combined_plot, width = 12, height = 15)

message("Combined QC plots saved as combined_qc_plots.png")
