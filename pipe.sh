#!/bin/bash

### Pipeline to process raw fastq files (produced by target mtDNA sequencing) and align them to rCRS. 
### Final output is a filtered BAM file to be used as input for mtDNA-server 2.

### before starting, have all fastq in the working directory and run this command: for i in *_R1_*; do echo ${i%%_*} >> sample_list.txt; done.
### activate conda environment mtServer-bam and run the command bash pipe.sh.



# set some variables

mtDNA=/path/to/ref/Ref/rCRS.fasta

fastqc=fastqc

trimgalore=trim_galore

bwa=bwa

samtools=samtools

picard=picard



min_mapping_quality=30



workdir=$(pwd)



# make a directory where all samples analyses will be stored
mkdir 0_all_fastq
mkdir 1_single_sample_analyses
mkdir 2_all_final_bam

mkdir 2_all_final_bam/bam
final_bam=2_all_final_bam/bam

mkdir -p 2_all_final_bam/indexes
indexes=2_all_final_bam/indexes



################################################################################
################################################################################

# for loop

for i in $(cat sample_list.txt)


do


echo "Starting analysis of ${i}"



# create sample directories

mkdir ${i}

mkdir -p ${i}/1_fastq
fastq=${i}/1_fastq

mkdir -p ${i}/2_fastqc/raw
fastqc_raw=${i}/2_fastqc/raw

mkdir -p ${i}/2_fastqc/trimmed
fastqc_trm=${i}/2_fastqc/trimmed

mkdir -p ${i}/3_trimmed_fastq/trm_fastq
trm_fastq=${i}/3_trimmed_fastq/trm_fastq

mkdir -p ${i}/3_trimmed_fastq/trm_report
trm_report=${i}/3_trimmed_fastq/trm_report

mkdir -p ${i}/4_bam
bam=${i}/4_bam

mkdir -p ${i}/5_duplicates
rmdup=${i}/5_duplicates



##########################################################################################


# quality check on raw reads with fastqc

${fastqc} --threads 8 -f fastq ${i}_*.fastq.gz -o ${fastqc_raw}


##########################################################################################


# quality and adapter trimming of raw fastq
# change the adapter option accordingly to the library prep kit you used

${trimgalore} --phred33 --paired -q 30 --nextera ${i}_*_R1*.fastq.gz ${i}_*_R2*.fastq.gz

mv ${i}*.fq.gz ${trm_fastq}

mv ${i}*trimming_report.txt ${trm_report}


##########################################################################################


# quality check on trimmed reads with fastqc

${fastqc} --threads 8 -f fastq ${trm_fastq}/${i}_*.fq.gz -o ${fastqc_trm}


##########################################################################################


# alignment

${bwa} mem \
-R "@RG\tID:${i}\tSM:${i}\tLB:illumina\tPL:IlluminaMiseq" \
-t 8 \
${mtDNA} \
${trm_fastq}/${i}_*_R1_*.fq.gz ${trm_fastq}/${i}_*_R2_*.fq.gz \
| ${samtools} view -q ${min_mapping_quality} -F 2820 -f 2 -bho ${bam}/${i}.bam

${samtools} sort ${bam}/${i}.bam -o ${bam}/${i}.sortco.bam







##########################################################################################


# remove duplicates

${picard} MarkDuplicates \
-I ${bam}/${i}.sortco.bam \
-O ${bam}/${i}.sortco.rmdup.tmp.bam \
-REMOVE_DUPLICATES TRUE \
-METRICS_FILE ${rmdup}/${i}_picard_metrics.txt

${samtools} index ${bam}/${i}.sortco.rmdup.tmp.bam


# copy final bam and indexes into the main folder

cp ${bam}/${i}.sortco.rmdup.tmp.bam ${final_bam}
cp ${bam}/${i}.sortco.rmdup.tmp.bam.bai ${indexes}
mv ${i} 1_single_sample_analyses


done

# move fastq files into the main folder

mv *.fastq.gz 0_all_fastq/
