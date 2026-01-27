#!/bin/bash

###############################################################################
# Biosynthetic Gene Cluster (BGC) discovery and abundance analysis pipeline
#
# Steps:
# 1. Detect BGCs from MAGs and unbinned contigs using antiSMASH
# 2. Rename and consolidate BGC GenBank files
# 3. Estimate BGC abundance using BiG-MAP
# 4. Assess BGC novelty by comparison with MiBIG using BiG-SLICE
#
# This script automatically consumes outputs from:
#   - Script 1: fastp_output (cleaned reads)
#   - Script 2: metawrap_output and megahit_output
#
# Author: Muhammad Ajagbe
# Year: 2024
###############################################################################

set -euo pipefail

# Load Conda
source ~/miniconda3/etc/profile.d/conda.sh

############################
# Create output directories
############################
mkdir -p logs antismash_output BGCs bigmap_output bigslice_output

############################
# Auto-detect inputs
############################

# MAGs from Script 2
MAG_DIRS=(metawrap_output/*_reassembled_bins/reassembled_bins)

# Unbinned contigs from Script 2
CONTIGS=(megahit_output/*_output/contigs.fa)

# Cleaned reads from Script 1
READS_R1=(fastp_output/*_cleaned_R1.fastq)
READS_R2=(fastp_output/*_cleaned_R2.fastq)

if [[ ${#MAG_DIRS[@]} -eq 0 && ${#CONTIGS[@]} -eq 0 ]]; then
    echo "Error: No MAGs or contigs detected from Script 2 outputs."
    exit 1
fi

if [[ ${#READS_R1[@]} -eq 0 || ${#READS_R2[@]} -eq 0 ]]; then
    echo "Error: Cleaned reads from Script 1 not found."
    exit 1
fi

###############################################################################
# 1. Detect BGCs with antiSMASH
###############################################################################
conda activate antismash

echo "Running antiSMASH on MAGs and unbinned contigs..."

for INPUT_DIR in "${MAG_DIRS[@]}"; do

    SAMPLE_NAME=$(basename "$(dirname "$INPUT_DIR")" | cut -d"_" -f1)

    for fasta_file in "$INPUT_DIR"/*.fa; do
        OUTPUT_DIR=antismash_output/${SAMPLE_NAME}_$(basename "$fasta_file" .fa)

        antismash \
            --output-dir "$OUTPUT_DIR" \
            --tigrfam --asf --cc-mibig --cb-general \
            --cb-subclusters --cb-knownclusters --pfam2go \
            --rre --smcog-trees --tfbs \
            --genefinding-tool prodigal-m \
            "$fasta_file" \
            > logs/"$(basename "$OUTPUT_DIR")".log 2>&1
    done
done

# Run antiSMASH on unbinned contigs
for contig in "${CONTIGS[@]}"; do
    SAMPLE_NAME=$(basename "$(dirname "$contig")" | cut -d"_" -f1)
    OUTPUT_DIR=antismash_output/${SAMPLE_NAME}_unbinned_contigs

    antismash \
        --output-dir "$OUTPUT_DIR" \
        --tigrfam --asf --cc-mibig --cb-general \
        --cb-subclusters --cb-knownclusters --pfam2go \
        --rre --smcog-trees --tfbs \
        --genefinding-tool prodigal-m \
        "$contig" \
        > logs/"${SAMPLE_NAME}_unbinned_antismash.log" 2>&1
done

conda deactivate
echo "antiSMASH completed."

###############################################################################
# 2. Rename and collect BGC GenBank files
###############################################################################
echo "Renaming and collecting BGC files..."

find antismash_output -name "*.region*.gbk" | while read -r file; do
    SAMPLE=$(basename "$(dirname "$file")" | cut -d"_" -f1)
    mv "$file" "$(dirname "$file")/${SAMPLE}_$(basename "$file")"
done

find antismash_output -name "*.region*.gbk" -exec mv {} BGCs/ \;

###############################################################################
# 3. BGC abundance estimation with BiG-MAP
###############################################################################
conda activate BiG-MAP_process

python3 ~/BiG-MAP/src/BiG-MAP.family.py \
    -D BGCs \
    -b ~/BiG-SCAPE-1.1.9 \
    -pf ~/BiG-SCAPE-1.1.9 \
    -O bigmap_output/BiG-MAP.family_output \
    > logs/BiG-MAP.family.log 2>&1

python3 ~/BiG-MAP/src/BiG-MAP.map.py \
    -I1 fastp_output/*_cleaned_R1.fastq \
    -I2 fastp_output/*_cleaned_R2.fastq \
    -O bigmap_output/BiG-MAP.map_output \
    -F bigmap_output/BiG-MAP.family_output \
    > logs/BiG-MAP.map.log 2>&1

conda deactivate
echo "BiG-MAP completed."

###############################################################################
# 4. BGC novelty assessment with BiG-SLICE
###############################################################################
conda activate bigslice

bigslice \
    -i bigslice_mibig_input \
    bigslice_output/mibig_gcf

bigslice \
    --query BGCs \
    --n_ranks 2 \
    bigslice_output/mibig_gcf

conda deactivate
echo "BiG-SLICE completed."

###############################################################################
# Pipeline finished
###############################################################################
echo "Script 3: BGC discovery and analysis pipeline completed successfully."
