# 🧬 Siwa Spring Microbiomes as Reservoirs of Biosynthetic Gene Clusters: Unlocking Natural Product Potential

## Overview
This repository contains a **fully automated, reproducible metagenomic analysis pipeline** developed for the study:

**“Unraveling Novel Biosynthetic Gene Clusters from the Siwa Oasis Microbiome”**  
*(Manuscript currently under peer review)*

The project investigates microbial diversity and biosynthetic potential in two historically significant freshwater springs — **Cleopatra** and **Fatnas** — located in Egypt’s **Siwa Oasis**. Using genome-resolved metagenomics and advanced BGC mining approaches, this work identifies **novel microbial taxa and biosynthetic gene clusters (BGCs)** with potential pharmaceutical relevance.

The repository is structured as a **three-stage pipeline**, progressing from raw reads to phylogenomics and secondary metabolite discovery.

![Key Findings](Images/key_findings.png)

---

## 🔑 Key Contributions
- End-to-end metagenomic pipeline from **raw reads → MAGs → BGC discovery**
- Recovery and phylogenomic placement of high-quality MAGs from underexplored freshwater environments
- Systematic discovery and prioritization of **novel BGCs**, including putative antimicrobial lasso peptides
- Quantitative estimation of **BGC abundance across samples**
- Reproducible, modular pipeline design suitable for downstream natural product discovery

---

## 🧰 Pipeline Structure

### **Script 1 — Read-level Quality Control & Profiling**
**Input:** Raw paired-end reads  
**Output:** Cleaned reads + taxonomic & diversity profiles  

Main tasks:
- Adapter trimming and quality filtering (fastp)
- Sequencing depth estimation (Nonpareil)
- Read-based taxonomic profiling (Kraken2)
- Abundance correction & diversity estimation (Bracken)

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

### **Script 3 — Biosynthetic Gene Cluster Discovery**
**Input:** MAGs & unbinned contigs from Script 2 + cleaned reads from Script 1  
**Output:** Annotated BGCs, abundance matrices, novelty assessments  

Main tasks:
- BGC detection from MAGs and unbinned contigs (antiSMASH)
- BGC clustering and abundance estimation (BiG-MAP)
- Novelty assessment against MiBIG and BGC Atlas (BiG-SLICE)

All scripts **automatically detect required inputs**, allowing the full pipeline to be executed sequentially with minimal user intervention.

![Pipeline Overview](Images/Pipeline.png)

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

## 🔁 Reproducibility & Design Philosophy
- Modular, script-based architecture
- Explicit logging and defensive error handling
- Automated input discovery between pipeline stages
- Conda-managed environments for tool isolation
- Designed for scalability and future workflow migration (e.g., Snakemake / Nextflow)

---

## 📚 Citation
**Manuscript under review**

> Ajagbe M., Elbehery A.H.A., Ahmed S.F., Ouf A., Abdoullateef B.M.T., Abdallah R., Siam R. (2025).  
> *Unraveling Novel Biosynthetic Gene Clusters from the Siwa Oasis Microbiome.*

---

## 📫 Contact
For questions or collaboration:

📧 aelbehery@aucegypt.edu  
📧 d1stadeyemi@gmail.com  

🔗 LinkedIn: [Muhammad Ajagbe](https://www.linkedin.com/in/muhammad-ajagbe/)
