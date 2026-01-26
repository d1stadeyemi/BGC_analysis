#!/bin/bash

###############################################################################
# Read-level metagenomic analysis pipeline
#
# Steps:
# 1. Quality control and adapter trimming using fastp
# 2. Sequencing depth and coverage estimation using Nonpareil
# 3. Taxonomic classification of reads using Kraken2
# 4. Estimation of microbial diversity using Bracken
#
# This script processes paired-end Illumina reads and produces
# cleaned reads, sequencing quality metrics, taxonomic profiles,
# and diversity estimates suitable for downstream analysis.
#
# Author: <Your Name>
# Year: 2025
###############################################################################

# Exit on error, undefined variable, or failed pipeline
set -euo pipefail

# Load Conda
source ~/miniconda3/etc/profile.d/conda.sh

############################
# User-configurable params
############################
THREADS=4
KRAKEN_DB=/path/to/kraken2_db   # <-- CHANGE THIS
BRACKEN_DB=/path/to/kraken2_db # usually same as Kraken DB
READ_LEN=150                   # average read length for Bracken

############################
# Argument checking
############################
if [[ $# -lt 2 || $(($# % 2)) -ne 0 ]]; then
    echo "Usage: $0 Sample1_R1 Sample1_R2 [Sample2_R1 Sample2_R2 ...]"
    exit 1
fi

############################
# Create output directories
############################
mkdir -p logs fastp_output nonpareil_output kraken2_output bracken_output

############################
# Store samples
############################
SAMPLES=()

while [[ $# -gt 0 ]]; do
    RAW_READS_R1=$1
    RAW_READS_R2=$2

    SAMPLE_NAME=$(basename "$RAW_READS_R1")
    SAMPLE_NAME=${SAMPLE_NAME%%_*}

    if [[ ! -f "$RAW_READS_R1" || ! -f "$RAW_READS_R2" ]]; then
        echo "Error: Input files not found:"
        echo "  $RAW_READS_R1"
        echo "  $RAW_READS_R2"
        exit 1
    fi

    SAMPLES+=("$SAMPLE_NAME" "$RAW_READS_R1" "$RAW_READS_R2")
    shift 2
done

###############################################################################
# 1. Quality control with fastp
###############################################################################
echo "Running fastp on all samples..."
conda activate fastp

for ((i=0; i<${#SAMPLES[@]}; i+=3)); do
    SAMPLE_NAME=${SAMPLES[i]}
    RAW_READS_R1=${SAMPLES[i+1]}
    RAW_READS_R2=${SAMPLES[i+2]}

    echo "[$SAMPLE_NAME] Running fastp..."

    fastp \
        -i "$RAW_READS_R1" \
        -I "$RAW_READS_R2" \
        -o fastp_output/"${SAMPLE_NAME}_cleaned_R1.fastq" \
        -O fastp_output/"${SAMPLE_NAME}_cleaned_R2.fastq" \
        -h fastp_output/"${SAMPLE_NAME}_fastp.html" \
        -j fastp_output/"${SAMPLE_NAME}_fastp.json" \
        -w "$THREADS" \
        > logs/"${SAMPLE_NAME}_fastp.log" 2>&1
done

conda deactivate
echo "fastp completed for all samples."

###############################################################################
# 2. Sequencing depth estimation with Nonpareil
###############################################################################
echo "Running Nonpareil on all samples..."
conda activate nonpareil

for ((i=0; i<${#SAMPLES[@]}; i+=3)); do
    SAMPLE_NAME=${SAMPLES[i]}

    echo "[$SAMPLE_NAME] Running Nonpareil..."

    nonpareil \
        -s fastp_output/"${SAMPLE_NAME}_cleaned_R1.fastq" \
        -T kmer \
        -k 15 \
        -f fastq \
        -b nonpareil_output/"${SAMPLE_NAME}" \
        > logs/"${SAMPLE_NAME}_nonpareil.log" 2>&1
done

conda deactivate
echo "Nonpareil analysis completed."

###############################################################################
# 3. Taxonomic classification with Kraken2
###############################################################################
echo "Running Kraken2 on all samples..."
conda activate kraken2

for ((i=0; i<${#SAMPLES[@]}; i+=3)); do
    SAMPLE_NAME=${SAMPLES[i]}

    echo "[$SAMPLE_NAME] Running Kraken2..."

    kraken2 \
        --db "$KRAKEN_DB" \
        --paired \
        --threads "$THREADS" \
        --report kraken2_output/"${SAMPLE_NAME}_report.txt" \
        --output kraken2_output/"${SAMPLE_NAME}_kraken.out" \
        fastp_output/"${SAMPLE_NAME}_cleaned_R1.fastq" \
        fastp_output/"${SAMPLE_NAME}_cleaned_R2.fastq" \
        > logs/"${SAMPLE_NAME}_kraken2.log" 2>&1
done

conda deactivate
echo "Kraken2 classification completed."

###############################################################################
# 4. Microbial diversity estimation with Bracken
###############################################################################
echo "Running Bracken on all samples..."
conda activate bracken

for ((i=0; i<${#SAMPLES[@]}; i+=3)); do
    SAMPLE_NAME=${SAMPLES[i]}

    echo "[$SAMPLE_NAME] Running Bracken..."

    bracken \
        -d "$BRACKEN_DB" \
        -i kraken2_output/"${SAMPLE_NAME}_report.txt" \
        -o bracken_output/"${SAMPLE_NAME}_bracken_species.txt" \
        -r "$READ_LEN" \
        -l S \
        > logs/"${SAMPLE_NAME}_bracken.log" 2>&1
done

conda deactivate
echo "Bracken diversity estimation completed."

###############################################################################
# Pipeline finished
###############################################################################
echo "Script 1: Read-level metagenomic pipeline completed successfully."
