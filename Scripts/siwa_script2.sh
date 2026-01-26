#!/bin/bash

# Load Conda 
source ~/miniconda3/etc/profile.d/conda.sh

# Error on undefined variables
set -u 

# This script assembles metagenomic reads into contigs.
# Bins the contigs and select MAGs.
# Classifies the MAGs into taxa.
# Place MAGs within the GTDB reference genomes for phylogenomy.

# Check if at least one pair of clean reads is given
if [[ $# -lt 2 || $(($# % 2)) -ne 0 ]]; then
    echo "Usage: $0 Sample1_R1 Sample1_R2 [Sample2_R1 Sample2_R2...]"
    exit 1
fi

# Create output directories if not created
mkdir -p logs megahit_output metawrap_output

while [[ $# -gt 0 ]]; do # While there are still reads to process 
    # Define input files 
    CLEANED_R1=$1
    CLEANED_R2=$2
    SAMPLE_NAME=$(basename "$CLEANED_R1" | cut -d"_" -f1) # Extract sample name

    # Check if input files exist 
    if [[ ! -f "$CLEANED_R1" || ! -f "$CLEANED_R2" ]]; then
        echo "Error! : One or both sample files ($CLEANED_R1, $CLEANED_R2) not found"
        exit 1
    fi

    # 1. Assembly with Megahit. 
    echo "Running Megahit for ${SAMPLE_NAME} cleaned reads..."
    conda activate megahit
    megahit -v
    megahit -1 "$CLEANED_R1" -2 "$CLEANED_R2" -o megahit_output/"$SAMPLE_NAME"_output \
        > logs/"$SAMPLE_NAME"_megahit.log 2>&1

    # Check the exit status of the last command.  
    # If it failed (exit status !=0), print error message and exit.
    if [[ $? -ne 0 ]]; then
        echo "Error! Megahit failed for "$SAMPLE_NAME"_sample." 
        echo "Check logs/"$SAMPLE_NAME"_megahit.log for details"
        exit 1
    fi

    conda deactivate
    echo "Megahit completed for "$SAMPLE_NAME"_sample. Output saved to 'megahit_output'"

    # 2. Binnning with metawrap
    echo "Running Metawrap on ${SAMPLE_NAME} assembly..."
    conda activate metawrap
    metawrap -v
    
    # Initial binning with three different algorithms
    metawrap binning -o metawrap_output/"$SAMPLE_NAME"_initial_bins -t 4 \
        -a megahit_output/"$SAMPLE_NAME"_output/contigs.fa --metabat2 --maxbin2 --concoct \
        "$CLEANED_R1" "$CLEANED_R2" > logs/"$SAMPLE_NAME"_initial_bins.log 2>&1
    
    # Check the exit status of the last command. 
    # If it failed (exit status !=0), print error message and exit.
    if [[ $? -ne 0 ]]; then
        echo "Error! Metawrap binning module failed for "$SAMPLE_NAME"_sample."
        echo "Check logs/"$SAMPLE_NAME"_initial_bins.log for details"
        exit 1
    fi

    # Consolidate bin sets with the Bin_refinement module
    metawrap bin_refinement -o metawrap_output/"$SAMPLE_NAME"_refined_bins -t 4 \
        -A metawrap_output/"$SAMPLE_NAME"_initial_bins/metabat2_bins/ \
        -B metawrap_output/"$SAMPLE_NAME"_initial_bins/maxbin2_bins/ \
        -C metawrap_output/"$SAMPLE_NAME"_initial_bins/concoct_bins/ -c 50 -x 10 \
        > logs/"$SAMPLE_NAME"_refined_bins.log 2>&1

    # Check the exit status of the last command.
    # If it failed (exit status !=0), print error message and exit.
    if [[ $? -ne 0 ]]; then
        echo "Error! Metawrap refinement module failed for "$SAMPLE_NAME"_sample." 
        echo "Check logs/"$SAMPLE_NAME"_refined_bins.log for details"
        exit 1
    fi

    # Re-assemble the consolidated bin set with the Reassemble_bins module
    metawrap reassemble_bins -o metawrap_output/"$SAMPLE_NAME"_reassembled_bins \
        -1 "$CLEANED_R1" -2 "$CLEANED_R2" -t 4 -m 800 -c 50 -x 10 \
        -b metawrap_output/"$SAMPLE_NAME"_refined_bins/metawrap_50_10_bins \
        > logs/"$SAMPLE_NAME"_reassembled_bins.log 2>&1

    # Check the exit status of the last command.
    # If it failed (exit status !=0), print error message and exit.
    if [[ $? -ne 0 ]]; then
        echo "Error! Metawrap reassembly module failed for "$SAMPLE_NAME"_sample."
        echo "Check logs/"$SAMPLE_NAME"_reassembled_bins.log for details"
        exit 1
    fi

    conda deactivate
    echo "Metawrap completed for "$SAMPLE_NAME"_sample. Output saved to 'metawrap_output'"

    # 3. Taxonomic classification of MAGs with GTDB-Tk
    # GTDB-Tk assigns standardized taxonomy to MAGs based on the GTDB reference database.
    # This step produces taxonomy summaries and quality metrics for downstream interpretation.

    echo "Running GTDB-Tk classification for ${SAMPLE_NAME} MAGs..."
    conda activate gtdbtk
    gtdbtk --version

    # Define input MAG directory (reassembled, high-quality bins)
    MAG_DIR=metawrap_output/"$SAMPLE_NAME"_reassembled_bins/reassembled_bins

    # Check if MAG directory exists and is not empty
    if [[ ! -d "$MAG_DIR" || -z "$(ls -A "$MAG_DIR")" ]]; then
        echo "Error! MAG directory $MAG_DIR does not exist or is empty."
        exit 1
    fi

    # Run GTDB-Tk classification
    gtdbtk classify_wf \
        --genome_dir "$MAG_DIR" \
        --out_dir metawrap_output/"$SAMPLE_NAME"_gtdbtk \
        --cpus 4 \
        > logs/"$SAMPLE_NAME"_gtdbtk.log 2>&1

    # Check exit status
    if [[ $? -ne 0 ]]; then
        echo "Error! GTDB-Tk classification failed for "$SAMPLE_NAME"_sample."
        echo "Check logs/"$SAMPLE_NAME"_gtdbtk.log for details"
        exit 1
    fi

    conda deactivate
    echo "GTDB-Tk classification completed for "$SAMPLE_NAME"_sample."

    # 4. Phylogenomic placement of MAGs using GToTree
    # GToTree builds a concatenated marker-gene alignment and places MAGs
    # into a reference phylogeny (here using GTDB bacterial markers).

    echo "Running GToTree phylogenomic analysis for ${SAMPLE_NAME} MAGs..."
    conda activate gtotree
    GToTree --version

    # Create output directory for phylogeny
    mkdir -p gtotree_output/"$SAMPLE_NAME"

    # Run GToTree using GTDB bacterial marker set
    # Note: change the marker set if working with archaeal MAGs
    GToTree \
        -f "$MAG_DIR" \
        -H bacteria \
        -t 4 \
        -o gtotree_output/"$SAMPLE_NAME"/"$SAMPLE_NAME"_GTDB_tree \
        > logs/"$SAMPLE_NAME"_gtotree.log 2>&1

    # Check exit status
    if [[ $? -ne 0 ]]; then
        echo "Error! GToTree phylogenomic analysis failed for "$SAMPLE_NAME"_sample."
        echo "Check logs/"$SAMPLE_NAME"_gtotree.log for details"
        exit 1
    fi

    conda deactivate
    echo "GToTree phylogenomic placement completed for "$SAMPLE_NAME"_sample."

    # Shift to next pair of reads
    shift 2
done
