#!/bin/bash
#SBATCH --job-name=GDB_chr
#SBATCH --output=GDB_chr_%A_%a.out
#SBATCH --error=GDB_chr_%A_%a.err
#SBATCH --array=1-39                 # 1-38, X=39, Keep this in sync with CHROMS!
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=24:00:00

set -euo pipefail
set -x

ml java/17.0.9

REF=<reference fasta>
GVCF_DIR=<dir_for_gvariants>
TMP_DIR=$GVCF_DIR/genomicsdb_chr${SLURM_ARRAY_TASK_ID}_tmp
OUT_DIR=$GVCF_DIR/output/genomicsdb

CHROMS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chr23 chr24 chr25 chr26 chr27 chr28 chr29 chr30 chr31 chr32 chr33 chr34 chr35 chr36 chr37 chr38 chrX)
CHR=${CHROMS[$((SLURM_ARRAY_TASK_ID-1))]}

WORKSPACE=$OUT_DIR/${CHR}
SAMPLE_MAP=$GVCF_DIR/sample_map.txt ###generate sample_map.txt using ls *.g.vcf.gz | sed 's/.g.vcf.gz//' | awk '{print $1"\t"$1".g.vcf.gz"}' > sample_map.txt###

echo "Processing workspace: $WORKSPACE"
echo "Temporary dir: $TMP_DIR"
echo "Sample map: $SAMPLE_MAP"
echo "Processing chromosome: $CHR"

# Cleanup workspace as a precaution
if [ -d "$WORKSPACE" ]; then
  echo "$WORKSPACE already exists, removing..."
  rm -rf "$WORKSPACE"
fi

mkdir -p "$TMP_DIR"
mkdir -p "$OUT_DIR"

gatk --java-options "-Xmx28g -Xms28g" GenomicsDBImport \
    --genomicsdb-workspace-path "$WORKSPACE" \
    --sample-name-map "$SAMPLE_MAP" \
    -L "$CHR" \
    --genomicsdb-shared-posixfs-optimizations true \
    --merge-input-intervals \
    --bypass-feature-reader \
    --tmp-dir "$TMP_DIR"

rm -rf "$TMP_DIR"

