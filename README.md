# Trio-Based Variant Analysis Pipeline

## Overview

This pipeline implements a complete workflow for variant discovery and filtering in trio-based sequencing data (child, father, mother), focusing on chromosome 20 (GRCh38.p14 assembly).

The pipeline is written in Bash and supports processing of multiple trios iteratively.

## Project background

In this project, using a Unix-based pipeline, we analyzed trio-based exome sequencing data from a child and both parents to identify the genetic cause of the child’s condition, when present, while considering autosomal inheritance models such as recessive, dominant, or de novo. Paired-end sequencing was used to improve read alignment and increase the accuracy of variant detection.

## Pipeline Structure

The pipeline consists of the following steps:

1.  Input Acquisition
2.  Inheritance Model Selection
3.  Alignment & Quality Control
4.  Variant Calling
5.  Variant Filtering
6.  Coverage Track Generation

## Requirements

-   Bowtie2 version 2.4.4
-   samtools version 1.13
-   Qualimap version 2.3
-   FastQC version 0.11.9
-   MultiQC version 1.34
-   FreeBayes  version 1.3.6
-   BCFtools version 1.13
-   Bedtools version 2.30.0
-   bgzip (htslib) version 1.13+ds

## Input Data

### Required Reference Files

-   `chr20*` (Bowtie2 index)
-   `chr20.fa` (reference genome)
-   `chr20_bed` (target regions)
-   `samples.txt` (sample list): file containing the sequence of samples in each trio (child, father, mother)

### Raw Sequencing Data

Paired-end FASTQ files: `\*\_R1.fq.gz` , `\*\_R2.fq.gz`

## Configuration before running the pipeline

Before running the pipeline, you must update file paths to match your system. This workflow uses absolute paths (e.g. `/home/BCG2026_exam/...`) that are specific to the original server environment and will not work on other machines without modification.

## Required modifications

1.  Download chromosome 20 reference \
    You must explicitly download the reference genome (chr20) before building the index.

2.  Build Bowtie2 index for chr20 \
    The index must be created locally after downloading the reference genome.

3.  Adapt BED file \
    The BED file containing target regions for exome sequencing must be adapted according to your experimental design and sequencing targets.

4.  Update sample paths \
    Replace the original sample directory with the correct path where your FASTQ files are stored.

## Execution

In order to un the pipeline:\
change the mode of the pipeline after uploaded the script: `chmod +x nameofthepipeline.sh` \
run the pipeline from your terminal `./nameofthepipeline.sh` 

The pipeline will prompt for: 
- Case names (multiple trios separated by spaces)
- Sample IDs (corresponding to child, father, mother)
- Username (used to locate input data)

## Output Files

For each case:

-   child.bam, father.bam, mother.bam
-   BAM index files (.bai)
-   QC reports (Qualimap, FastQC, MultiQC)
-   Raw VCF (.vcf.gz)
-   Filtered VCF (.cand.vcf)
-   Coverage tracks (\*.bg)

## Notes

-   The pipeline is restricted to chromosome 20
-   Sample order must be: child father mother
-   The same sample IDs are reused across cases
-   Ensure correct file permissions and paths

## Author

This work was conducted by Vincenzo Ricciardi and Sara Likramaj
