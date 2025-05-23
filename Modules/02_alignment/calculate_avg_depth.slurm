#!/bin/bash

#SBATCH --job-name=coverage_calc        # job name
#SBATCH --output=logs/coverage_%A_%a.out  # stdout (%A = jobID, %a = array index)
#SBATCH --error=logs/coverage_%A_%a.err   # stderr
#SBATCH --time=06:00:00                 # max run time (HH:MM:SS)
#SBATCH --cpus-per-task=4               # threads per task (for samtools)
#SBATCH --mem=32G                       # memory per task
#SBATCH --array=1-40                     # replace N with number of samples


# created samples.txt using ls *.sam | sed 's/\.sam$//' > samples.txt
SAMPLES=( $(cat samples.txt) )
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID-1]}

echo "[$(date)] Processing $SAMPLE"

# 1) Convert SAM → BAM
samtools view -@ $SLURM_CPUS_PER_TASK -bS ${SAMPLE}.sam \
  > ${SAMPLE}.bam

# 2) Sort BAM
samtools sort -@ $SLURM_CPUS_PER_TASK -o ${SAMPLE}.sorted.bam \
  ${SAMPLE}.bam

# 3) Index sorted BAM
samtools index ${SAMPLE}.sorted.bam

# 4) Compute average genome‑wide coverage
#    Include zero‑coverage positions (-a), then awk to average.
AVG=$(samtools depth -a ${SAMPLE}.sorted.bam \
      | awk '{sum+=$3; cnt++} END {if(cnt>0) printf "%.3f\n", sum/cnt; else print "NA"}')

# Append result to a shared summary file
echo -e "${SAMPLE}\t${AVG}" >> coverage_summary.tsv

echo "[$(date)] Done $SAMPLE: Avg coverage = ${AVG}×"
