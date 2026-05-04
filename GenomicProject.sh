#!/bin/bash

#1.INPUT ACQUISITION

echo "The pipeline execution is starting...    "
# Copy the index once and the reuse it for all the cases
cp /home/BCG2026_exam/chr20* .
cp /home/BCG2022_genomics_exam/worked/536/samples.txt .

# Asking the user for the case name, the samples IDs and their username
read -p "Enter case names separated by space (e.g., trio_1 trio_2): " -a case_number
read -p "Enter sample IDs (e.g., HG00451 HG00452 HG00453): " -a samples
read -p "Enter your username (e.g., BCG2026_Likramaj_S) " username

# Array to store the roles in the trio
person=(child father mother)
 
# Array to store patterns for each case
declare -a patterns

# Ask inheritance model for each case
for i in "${!case_number[@]}"; do
    current_case="${case_number[$i]}"

    # Pattern selection
    echo "Select the Inheritance Model:"
    echo " AR  -> Autosomal Recessive "
    echo " AD  -> Autosomal Dominant "
    echo " ADN -> Autosomal De Novo "
    read -p "Enter model code (AR, AD, or ADN): " model_choice

    # Convert input to uppercase for compatibility
    model_choice=$(echo "$model_choice" | tr '[:lower:]' '[:upper:]')
    # Use a case statement to match the correct pattern 
    case $model_choice in
        "AR")
            patterns[$i]='GT[0]="AA" && GT[1]="RA" && GT[2]="RA"'
            echo "Selected: Autosomal Recessive"
            ;;
        "AD")
            echo "Who is the affected parent?"
            echo "  1) Father "
            echo "  2) Mother " 
            read -p "Selection [1-2]: " parent_choice
        
            if [ "$parent_choice" == "1" ]; then
                patterns[$i]='GT[0]="RA" && GT[1]="RA" && GT[2]="RR"'
                echo "Selected: Autosomal Dominant (Father affected)"
            else
                patterns[$i]='GT[0]="RA" && GT[1]="RR" && GT[2]="RA"'
                echo "Selected: Autosomal Dominant (Mother affected)"
            fi
            ;;
        "ADN")
            patterns[$i]='GT[0]="RA" && GT[1]="RR" && GT[2]="RR"'
            echo "Selected: Autosomal De Novo"
            ;;
        *)
            echo "Invalid selection. Exiting script."
            exit 1
            ;;
    esac
done


# 2. MAIN BODY OF THE ALGORITHM

for i in "${!case_number[@]}"; do
    current_case="${case_number[$i]}"
    current_pattern="${patterns[$i]}"
    echo "Starting processing for: $current_case"
    
    # Create a subdirectory for each case and move into it
    mkdir -p "$current_case"
    cd "$current_case" || exit

    # Copy raw data (FASTQ files) for the current case
    cp /home/BCG2026_exam/"$username"/"$current_case"/* .

    # Alignment step
    for j in {0..2}; do
        role="${person[$j]}"
        ID="${samples[$j]}"
        
        echo "Processing $role (Sample ID: $ID)..."
        
        # Alignment using paired-end reads --> tool used: bowtie2
        bowtie2 -p 4 --fr -1 "${ID}.targets_R1.fq.gz" -2 "${ID}.targets_R2.fq.gz" \
        -x ../chr20 --rg-id "$role" --rg "SM:$role" | samtools view -Sb | \
        samtools sort -o "${role}.bam"
        
        # Indexing the BAM file --> tool used: samtools
        samtools index "${role}.bam"
        
        # QC1: Quality control using Qualimap on target regions
        qualimap bamqc -bam "${role}.bam" \
        --feature-file ../chr20_ILMN_Exome_2.0_Plus_Panel.hg38_padded.bed \
        --outdir "${role}"
    done

    # QC2: quality control
    echo "Running FastQC and MultiQC..."
    fastqc *.bam  #checking all the bam files
    multiqc . #collecting all the reports in a multiqc file (just 1 file that can be analyzed)
    mv multiqc_report.html "${current_case}_multiqc_report.html" #renaming the MultiQC report to keep data organized

    # Variant Calling --> tool used: freebayes
    echo "Starting Variant Calling (.vcf creation) for $current_case..."
    freebayes -f ../chr20.fa -m 20 -C 5 -Q 10 --min-coverage 10 \
    child.bam father.bam mother.bam > "${current_case}.vcf"
    echo "Variant Calling completed."

    # Filtering --> tool used: bcftools
    echo "Filtering variants with bcftools using pattern: $current_pattern"
    bgzip "${current_case}.vcf" #zipping the file
    bcftools index "${current_case}.vcf.gz" #indexing
    # Actual filtering 
    bcftools view -R ../chr20_ILMN_Exome_2.0_Plus_Panel.hg38_padded.bed "${current_case}.vcf.gz" | \
    bcftools view -S ../samples.txt | bcftools view -i "$current_pattern" | \
    bcftools filter -i 'QUAL>20' -Ov -o "${current_case}.cand.vcf"
    echo "Produced: ${current_case}.cand.vcf"

    # Coverage track 
    echo "Generating coverage tracks for visualization..."
    for role in child father mother; do
        bedtools genomecov -ibam "${role}.bam" -bg -trackline \
        -trackopts "name=${role}" -max 100 > "${role}Cov.bg"
    done

    #return to the parent directory to start the next case
    cd ..
    echo "Analysis for $current_case finished."
done

echo " Pipeline execution ended "
