.libPaths("/software/R/4.4.0/lib64/R/library")
library(ggplot2)
library(dplyr)
library(readr)

# --- Define the path to your extracted R-squared file ---
rsq_file_path <- "PATH/TO/imputation_rsq_values.txt"

# Read the data
# Use read_tsv for tab-separated values, specifying column names
rsq_data <- read_tsv(rsq_file_path, col_names = c("CHROM", "POS", "ID", "RSQ"))

# --- 1. Calculate Summary Statistics ---
# Imputation R-squared values range from 0 to 1.
summary_stats <- rsq_data %>%
  summarise(
    N_Variants = n(),
    Min_RSQ = min(RSQ, na.rm = TRUE),
    Max_RSQ = max(RSQ, na.rm = TRUE),
    Mean_RSQ = mean(RSQ, na.rm = TRUE),
    Median_RSQ = median(RSQ, na.rm = TRUE),
    Q1_RSQ = quantile(RSQ, 0.25, na.rm = TRUE),
    Q3_RSQ = quantile(RSQ, 0.75, na.rm = TRUE),
    # Percentage of variants above common quality thresholds
    Pct_RSQ_ge_0.3 = mean(RSQ >= 0.3, na.rm = TRUE) * 100,
    Pct_RSQ_ge_0.5 = mean(RSQ >= 0.5, na.rm = TRUE) * 100,
    Pct_RSQ_ge_0.8 = mean(RSQ >= 0.8, na.rm = TRUE) * 100,
    Pct_RSQ_ge_0.9 = mean(RSQ >= 0.9, na.rm = TRUE) * 100
  )

print("--- Imputation Quality (R-squared) Summary Statistics ---")
print(summary_stats)

# --- 2. Create a Histogram/Density Plot ---

# Histogram
p1 <- ggplot(rsq_data, aes(x = RSQ)) +
  geom_histogram(binwidth = 0.02, fill = "steelblue", color = "black", alpha = 0.7) +
  labs(
    title = "Distribution of Imputation Quality R-squared (DR2/R2)",
    x = "Imputation Quality R-squared (DR2/R2)",
    y = "Number of Variants"
  ) +
  theme_minimal() +
  xlim(0, 1) # Ensure x-axis from 0 to 1

print(p1)

# Density plot (often preferred for smoother visualization)
p2 <- ggplot(rsq_data, aes(x = RSQ)) +
  geom_density(fill = "darkgreen", color = "black", alpha = 0.7) +
  labs(
    title = "Density of Imputation Quality R-squared (DR2/R2)",
    x = "Imputation Quality R-squared (DR2/R2)",
    y = "Density"
  ) +
  theme_minimal() +
  xlim(0, 1) # Ensure x-axis from 0 to 1

print(p2)

# Optional: Save plots to files
# ggsave("imputation_rsq_histogram.png", plot = p1, width = 8, height = 6, dpi = 300)
# ggsave("imputation_rsq_density.png", plot = p2, width = 8, height = 6, dpi = 300)
