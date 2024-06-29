#!/bin/bash

### Pipeline to process raw fastq files (produced by target mtDNA sequencing) and align them to rCRS. 
### Final output is a filtered BAM file to be used as input for mtDNA-server 2.

#!/bin/bash

rCRS=rCRS/rCRS.fasta

for INPUT_FASTQS in "$@"; do
	
if [[ $INPUT_FASTQS == *"R1"* ]]; then

R1=${INPUT_FASTQS}
R2=${INPUT_FASTQS/R1/R2}
SAMPLE_NAME=$(basename ${R1%%_*})

echo "

##### processing pair: ${R1} and ${R2}
      
      "

mkdir ${SAMPLE_NAME}

mkdir -p ${SAMPLE_NAME}/logs

# fastqc on raw data

echo "

##### ${SAMPLE_NAME}: fastqc on raw data
      
      "

mkdir -p ${SAMPLE_NAME}/fastqc_raw

fastqc --threads 4 -f fastq ${R1} ${R2} -o ${SAMPLE_NAME}/fastqc_raw 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.fastqc.raw.log

# process raw data  and fastqc on trimmed data

echo "

##### ${SAMPLE_NAME}:  process raw data and fastqc on trimmed data
      
      "

mkdir -p ${SAMPLE_NAME}/trm_fastq ${SAMPLE_NAME}/fastqc_trm

trim_galore --phred33 --paired -q 30 -j 4 --nextera ${R1} ${R2} -o ${SAMPLE_NAME}/trm_fastq \
--fastqc --fastqc_args "--outdir ${SAMPLE_NAME}/fastqc_trm" 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.trimgalore.log

# align processed reads to rCRS and filter resulting BAM file

echo "

##### ${SAMPLE_NAME}:  align processed reads to rCRS and filter resulting BAM file
      
      "

mkdir -p ${SAMPLE_NAME}/bam

bwa mem \
-R "@RG\tID:${SAMPLE_NAME}\tSM:${SAMPLE_NAME}\tLB:illumina\tPL:Illumina" \
-t 4 \
${rCRS} \
${SAMPLE_NAME}/trm_fastq/${SAMPLE_NAME}*R1*.fq.gz ${SAMPLE_NAME}/trm_fastq/${SAMPLE_NAME}*R2*.fq.gz \
| samtools view -q 30 -F 4 -bho - \
| samtools sort -o ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.bam 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.bwa.and.filt.log

# remove duplicates

echo "

##### ${SAMPLE_NAME}:  remove duplicates
      
      "

picard MarkDuplicates \
-I ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.bam \
-O ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.rmdup.bam \
-REMOVE_DUPLICATES TRUE \
-METRICS_FILE ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.picard.metrics.txt 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.picard.markduplicates.log

samtools index ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.rmdup.bam

rm ${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.bam

# make some stats

echo "

##### ${SAMPLE_NAME}:  make some stats
      
      "

mkdir -p ${SAMPLE_NAME}/mosdepth

mosdepth \
-t 4  \
${SAMPLE_NAME}/mosdepth/${SAMPLE_NAME} \
${SAMPLE_NAME}/bam/${SAMPLE_NAME}.mapped.sortco.rmdup.bam 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.mosdepth.log

multiqc ${SAMPLE_NAME}/ --outdir ${SAMPLE_NAME}/multiqc/ 2> ${SAMPLE_NAME}/logs/${SAMPLE_NAME}.multiqc.log

echo "

##### ${SAMPLE_NAME}:  analysis complete!
      
      "

fi

done






