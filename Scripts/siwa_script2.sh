#!/bin/bash

###############################################################################
# Metagenomic assembly, binning, MAG classification, and phylogenomics pipeline
#
# Steps:
# 1. Assemble reads using MEGAHIT
# 2. Bin contigs and refine MAGs using MetaWRAP
# 3. Assign taxonomy to MAGs using GTDB-Tk
# 4. Place MAGs in a GTDB-based phylogenomic tree using GToTree
#
# Author: <Your Name>
# Year: 2025
###############################################################################

# Exit immediately on error, undefined variable, or pipe failure
set -euo pipefail

# Load Conda
source ~/miniconda3/etc/profile.d/conda.sh

############################
# User-configurable params
############################
THREADS=4
MEMORY=800          # MB for MetaWRAP reassembly
BIN_COMPLETENESS=50
BIN_CONTAMINATION=10

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
mkdir -p logs megahit_output metawrap_output gtotree_output

###############################################################################
# Main loop over read pairs
###############################################################################
while [[ $# -gt 0 ]]; do

    CLEANED_R1=$1
    CLEANED_R2=$2

    # Extract sample name more robustly
    SAMPLE_NAME=$(basename "$CLEANED_R1")
    SAMPLE_NAME=${SAMPLE_NAME%%_*}

    ####################################
    # Input validation
    ####################################
    if [[ ! -f "$CLEANED_R1" || ! -f "$CLEANED_R2" ]]; then
        echo "Error: Input files not found:"
        echo "  $CLEANED_R1"
        echo "  $CLEANED_R2"
        exit 1
    fi

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
    echo "[$SAMPLE_NAME] MEGAHIT completed."

    ####################################
    # 2. Binning and refinement with MetaWRAP
    ####################################
    echo "[$SAMPLE_NAME] Running MetaWRAP binning..."
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
    echo "[$SAMPLE_NAME] MetaWRAP completed."

    ####################################
    # 3. Taxonomic classification with GTDB-Tk
    ####################################
    echo "[$SAMPLE_NAME] Running GTDB-Tk..."
    conda activate gtdbtk

    MAG_DIR=metawrap_output/"${SAMPLE_NAME}_reassembled_bins"/reassembled_bins

    if [[ ! -d "$MAG_DIR" || -z "$(ls -A "$MAG_DIR")" ]]; then
        echo "Error: MAG directory missing or empty: $MAG_DIR"
        exit 1
    fi

    # Remove old output if rerunning
    rm -rf metawrap_output/"${SAMPLE_NAME}_gtdbtk"

    gtdbtk classify_wf \
        --genome_dir "$MAG_DIR" \
        --out_dir metawrap_output/"${SAMPLE_NAME}_gtdbtk" \
        --cpus "$THREADS" \
        > logs/"${SAMPLE_NAME}_gtdbtk.log" 2>&1

    conda deactivate
    echo "[$SAMPLE_NAME] GTDB-Tk completed."

    ####################################
    # 4. Phylogenomics with GToTree
    ####################################
    echo "[$SAMPLE_NAME] Running GToTree..."
    conda activate gtotree

    mkdir -p gtotree_output/"$SAMPLE_NAME"

    # GToTree expects a directory of genomes using -d
    GToTree \
        -d "$MAG_DIR" \
        -H bacteria \
        -t "$THREADS" \
        -o gtotree_output/"$SAMPLE_NAME"/"${SAMPLE_NAME}_GTDB_tree" \
        > logs/"${SAMPLE_NAME}_gtotree.log" 2>&1

    conda deactivate
    echo "[$SAMPLE_NAME] GToTree completed."

    ####################################
    # Move to next sample
    ####################################
    shift 2
done

echo "Pipeline completed successfully for all samples."
