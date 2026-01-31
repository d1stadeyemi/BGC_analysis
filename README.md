# 🧬 Siwa Spring Microbiomes as Reservoirs of Biosynthetic Gene Clusters: Unlocking Natural Product Potential

## Overview
This repository contains a **fully automated, reproducible metagenomic analysis pipeline** developed for the study:

**“Siwa Spring Microbiomes as Reservoirs of Biosynthetic Gene Clusters: Unlocking Natural Product Potential”**  
*(Manuscript currently under peer review)*

The project investigates microbial diversity and biosynthetic potential in two historically significant freshwater springs — **Cleopatra** and **Fatnas** — located in Egypt’s **Siwa Oasis**. Using genome-resolved metagenomics and state-of-the-art biosynthetic gene cluster (BGC) mining approaches, this work identifies **novel microbial taxa and biosynthetic gene clusters** with predicted pharmaceutical relevance.

The repository is structured as a **three-stage pipeline**, progressing from raw reads to phylogenomics and secondary metabolite discovery.

<p align="center">
  <img src="Images/key_findings.png" width="500">
</p>

---

## 🔑 Key Contributions
- End-to-end metagenomic pipeline from **raw reads → MAGs → BGC discovery**
- Recovery and phylogenomic placement of high-quality MAGs from underexplored freshwater environments
- Systematic discovery, quantification, and prioritization of **novel BGCs**
- Functional prediction of BGC products, including **putative antimicrobial RiPPs and lasso peptides**
- Quantitative estimation of **BGC abundance across samples**
- Reproducible, modular pipeline design suitable for **natural product discovery workflows**

---

## 🧰 Pipeline Structure

### **Script 1 — Read-level Quality Control & Profiling**
**Input:** Raw paired-end reads  
**Output:** Cleaned reads + taxonomic & diversity profiles  

Main tasks:
- Adapter trimming and quality filtering (fastp)
- Sequencing depth and coverage estimation (Nonpareil)
- Read-based taxonomic profiling (Kraken2)
- Abundance correction and diversity estimation (Bracken)

---

### **Script 2 — Assembly, Binning & Phylogenomics**
**Input:** Cleaned reads from Script 1 (auto-detected)  
**Output:** Assembled contigs, refined MAGs, phylogenomic trees  

Main tasks:
- Metagenomic assembly (MEGAHIT)
- Genome binning and refinement (MetaWRAP)
- Taxonomic classification of MAGs (GTDB-Tk)
- Phylogenomic placement within GTDB references (GToTree)

---

### **Script 3 — Biosynthetic Gene Cluster Discovery & Functional Prediction**
**Input:** MAGs and unbinned contigs from Script 2 + cleaned reads from Script 1  
**Output:** Annotated BGCs, abundance matrices, novelty and bioactivity predictions  

Main tasks:
- BGC detection from MAGs and unbinned contigs (antiSMASH)
- BGC clustering and abundance estimation (BiG-MAP)
- Novelty assessment against MiBIG and BGC Atlas (BiG-SLICE)
- **Functional and bioactivity prediction of BGC products (DeepBGC)**

DeepBGC is applied in **meta-gene prediction mode**, and only predictions with  
**DeepBGC scores > 0.6** are retained, enabling prioritization of **high-confidence novel BGCs**, including antimicrobial RiPPs and RiPP–NRPS hybrids.

All scripts **automatically detect required inputs**, allowing the full pipeline to be executed sequentially with minimal user intervention.

<p align="center">
  <img src="Images/Pipeline.png" width="500">
</p>

---

## 🔁 Reproducibility & Execution

This pipeline was designed with **full reproducibility** in mind:

- All major steps are implemented as **version-controlled shell scripts**
- Inputs are **auto-detected** from previous pipeline stages
- Tool versions used in the manuscript are explicitly documented
- Output directories are deterministic and consistent across runs

Each script can be run independently, but they are intended to be executed **sequentially**.

---

## ▶️ One-Command Pipeline Execution

Assuming raw paired-end reads are available and Conda environments are properly configured, the **entire pipeline can be executed with the following commands**:

```bash
# Step 1: Read QC and profiling
bash script1_read_qc_and_taxonomy.sh raw_reads/*_R1.fastq raw_reads/*_R2.fastq

# Step 2: Assembly, binning, and phylogenomics
bash script2_assembly_binning_phylogenomics.sh fastp_output/*_cleaned_R1.fastq fastp_output/*_cleaned_R2.fastq

# Step 3: BGC discovery, abundance, novelty, and functional prediction
bash script3_bgc_discovery_and_analysis.sh
```

---

## 📊 Downstream Analysis & Visualization
The `scripts/` directory also includes Jupyter and R notebooks for:
- BGC abundance heatmaps
- Circular bar plots of BGC counts per MAG and taxonomic group
- Nonpareil diversity curves
- Geographic visualization of sampling locations
- Comparative novelty analysis against reference BGC databases

These notebooks reproduce figures used in the manuscript and support exploratory analysis.

---

## 🔬 Tools & Dependencies

### Core Software
- Python 3.9  
- R 4.2  
- fastp v0.23.2  
- Nonpareil v3.5.5  
- MEGAHIT v1.2.9  
- MetaWRAP v1.3.2  
- Kraken2 v2.1.2  
- GTDB-Tk v2.3.2  
- GToTree v1.8.6  
- antiSMASH v7.1.0  
- BiG-MAP v1.0.0  
- BiG-SCAPE  
- BiG-SLICE v2  

### Databases
- CheckM database  
- Kraken2 PlusPF (Jan 2024)  
- GTDB release r214  
- MiBIG v4  
- BGC Atlas  

---

## 📚 Citation
**Manuscript under review**

> Ajagbe M., Ahmed S.F., Ouf A., Abdoullateef B.M.T., Abdallah R., Siam R., Elbehery A.H.A. (2025).  
> *Siwa Spring Microbiomes as Reservoirs of Biosynthetic Gene Clusters: Unlocking Natural Product Potential.*

---

## 📫 Contact
For questions or collaboration:

📧 aelbehery@aucegypt.edu  
📧 d1stadeyemi@gmail.com  

🔗 LinkedIn: [Muhammad Ajagbe](https://www.linkedin.com/in/muhammad-ajagbe/)
