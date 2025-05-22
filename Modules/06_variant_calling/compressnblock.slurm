#!/bin/bash
#SBATCH --job-name=bgzip_tabix_gvcf
#SBATCH --output=bgzip_tabix_gvcf_%A_%a.out
#SBATCH --error=bgzip_tabix_gvcf_%A_%a.err
#SBATCH --array=1-40             # Set this to the number of gvcf files you have!
#SBATCH --time=99:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1

# Load htslib if needed
# module load htslib

GVCF_DIR=/path/to/gvariants

cd $GVCF_DIR

# Make an array of all *.g.vcf files
GVCFS=(*.g.vcf)

# Select the specific file for this array job
FILE="${GVCFS[$SLURM_ARRAY_TASK_ID-1]}"

if [ -z "$FILE" ]; then
    echo "No file for array index $SLURM_ARRAY_TASK_ID"
    exit 1
fi

echo "Working on $FILE"

if [ ! -f "$FILE.gz" ]; then
    echo "Compressing $FILE..."
    bgzip -c "$FILE" > "$FILE.gz"
else
    echo "$FILE.gz already exists; skipping compression"
fi

if [ ! -f "$FILE.gz.tbi" ]; then
    echo "Indexing $FILE.gz..."
    tabix -p vcf "$FILE.gz"
else
    echo "$FILE.gz.tbi already exists; skipping indexing"
fi
