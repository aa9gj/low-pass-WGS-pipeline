#!/bin/bash
#SBATCH --job-name=combineGVCF       # Name of the SLURM job
#SBATCH --output=logs/combine_%j.out # Redirect STDOUT to logs/combine_<jobID>.out
#SBATCH --error=logs/combine_%j.err  # Redirect STDERR to logs/combine_<jobID>.err
#SBATCH --time=04:00:00              # Maximum runtime (HH:MM:SS)
#SBATCH --cpus-per-task=4            # Number of CPU cores allocated
#SBATCH --mem=32G                    # Total memory allocated to the job

#-----------------------------------------
# Variables: Edit these paths for your setup
#-----------------------------------------
WORKDIR=/path/to/workdir          # Top‐level working directory
REF_FA=/path/to/reference.fa      # Reference FASTA (must be indexed)

# 1) Gather all your per‑sample GVCFs into an array
mapfile -t SAMPLE_GVCFS < <(ls "${WORKDIR}/gvcfs/"*.g.vcf.gz)

# 2) Build a string of “-V file1 -V file2 …”
GVCF_FLAGS=()
for g in "${SAMPLE_GVCFS[@]}"; do
  GVCF_FLAGS+=( -V "${g}" )
done

# 3) Run CombineGVCFs with that array expansion
gatk CombineGVCFs \
  -R "${REF_FA}" \
  "${GVCF_FLAGS[@]}" \
  -O "${WORKDIR}/cohort.g.vcf.gz"

# 4) Index for random access
tabix -p vcf "${WORKDIR}/cohort.g.vcf.gz"

