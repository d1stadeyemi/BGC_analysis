#!/bin/bash

###############################################################################
# Assembly, binning, MAG classification, and phylogenomic pipeline
#
# This script automatically consumes cleaned paired-end reads produced by
# Script 1 (fastp_output/*_cleaned_R1.fastq).
#
# Steps:
# 1. Assembly with MEGAHIT
# 2. Binning and refinement with MetaWRAP
# 3. Taxonomic classification with GTDB-Tk
# 4. Phylogenomic placement with GToTree
#
# Author: Muhammad Ajagbe
# Year: 2024
###############################################################################

set -euo pipefail

# Load Conda
source ~/miniconda3/etc/profile.d/conda.sh

############################
# User-configurable params
############################
THREADS=4
MEMORY=800
BIN_COMPLETENESS=50
BIN_CONTAMINATION=10

############################
# Check Script 1 outputs
############################
if [[ ! -d fastp_output ]]; then
    echo "Error: fastp_output/ directory not found."
    echo "Run Script 1 before running this pipeline."
    exit 1
fi

READS_R1=(fastp_output/*_cleaned_R1.fastq)

if [[ ${#READS_R1[@]} -eq 0 ]]; then
    echo "Error: No cleaned reads found in fastp_output/"
    exit 1
fi

############################
# Create output directories
############################
mkdir -p logs megahit_output metawrap_output gtotree_output

###############################################################################
# Main loop over samples
###############################################################################
for CLEANED_R1 in "${READS_R1[@]}"; do

    CLEANED_R2=${CLEANED_R1/_cleaned_R1.fastq/_cleaned_R2.fastq}

    if [[ ! -f "$CLEANED_R2" ]]; then
        echo "Error: Missing R2 pair for $CLEANED_R1"
        exit 1
    fi

    SAMPLE_NAME=$(basename "$CLEANED_R1")
    SAMPLE_NAME=${SAMPLE_NAME%%_cleaned_R1.fastq}

    echo "=============================="
    echo "Processing sample: $SAMPLE_NAME"
    echo "=============================="

    ####################################
    # 1. Assembly with MEGAHIT
    ####################################
    echo "[$SAMPLE_NAME] Running MEGAHIT..."
    conda activate megahit

    megahit \
        -1 "$CLEANED_R1" \
        -2 "$CLEANED_R2" \
        -t "$THREADS" \
        -o megahit_output/"${SAMPLE_NAME}_output" \
        > logs/"${SAMPLE_NAME}_megahit.log" 2>&1

    conda deactivate

    ####################################
    # 2. Binning and refinement with MetaWRAP
    ####################################
    echo "[$SAMPLE_NAME] Running MetaWRAP..."
    conda activate metawrap

    metawrap binning \
        -o metawrap_output/"${SAMPLE_NAME}_initial_bins" \
        -t "$THREADS" \
        -a megahit_output/"${SAMPLE_NAME}_output"/contigs.fa \
        --metabat2 --maxbin2 --concoct \
        "$CLEANED_R1" "$CLEANED_R2" \
        > logs/"${SAMPLE_NAME}_initial_bins.log" 2>&1

    metawrap bin_refinement \
        -o metawrap_output/"${SAMPLE_NAME}_refined_bins" \
        -t "$THREADS" \
        -A metawrap_output/"${SAMPLE_NAME}_initial_bins"/metabat2_bins \
        -B metawrap_output/"${SAMPLE_NAME}_initial_bins"/maxbin2_bins \
        -C metawrap_output/"${SAMPLE_NAME}_initial_bins"/concoct_bins \
        -c "$BIN_COMPLETENESS" -x "$BIN_CONTAMINATION" \
        > logs/"${SAMPLE_NAME}_refined_bins.log" 2>&1

    metawrap reassemble_bins \
        -o metawrap_output/"${SAMPLE_NAME}_reassembled_bins" \
        -1 "$CLEANED_R1" -2 "$CLEANED_R2" \
        -t "$THREADS" -m "$MEMORY" \
        -c "$BIN_COMPLETENESS" -x "$BIN_CONTAMINATION" \
        -b metawrap_output/"${SAMPLE_NAME}_refined_bins"/metawrap_"${BIN_COMPLETENESS}"_"${BIN_CONTAMINATION}"_bins \
        > logs/"${SAMPLE_NAME}_reassembled_bins.log" 2>&1

    conda deactivate

    ####################################
    # 3. GTDB-Tk classification
    ####################################
    echo "[$SAMPLE_NAME] Running GTDB-Tk..."
    conda activate gtdbtk

    MAG_DIR=metawrap_output/"${SAMPLE_NAME}_reassembled_bins"/reassembled_bins

    if [[ ! -d "$MAG_DIR" || -z "$(ls -A "$MAG_DIR")" ]]; then
        echo "Error: No MAGs found for $SAMPLE_NAME"
        exit 1
    fi

    rm -rf metawrap_output/"${SAMPLE_NAME}_gtdbtk"

    gtdbtk classify_wf \
        --genome_dir "$MAG_DIR" \
        --out_dir metawrap_output/"${SAMPLE_NAME}_gtdbtk" \
        --cpus "$THREADS" \
        > logs/"${SAMPLE_NAME}_gtdbtk.log" 2>&1

    conda deactivate

    ####################################
    # 4. Phylogenomics with GToTree
    ####################################
    echo "[$SAMPLE_NAME] Running GToTree..."
    conda activate gtotree

    mkdir -p gtotree_output/"$SAMPLE_NAME"

    GToTree \
        -d "$MAG_DIR" \
        -H bacteria \
        -t "$THREADS" \
        -o gtotree_output/"$SAMPLE_NAME"/"${SAMPLE_NAME}_GTDB_tree" \
        > logs/"${SAMPLE_NAME}_gtotree.log" 2>&1

    conda deactivate

done

echo "Script 2: Pipeline completed successfully for all samples."
