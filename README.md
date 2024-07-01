# mtDNA_pipe
Simple script to process raw fastq files (produced by target mtDNA sequencing) and align them to rCRS. Final output is a filtered BAM file to be used as input for mtDNA-server 2

# Usage

Clone the repository on your PC:

```git clone https://github.com/NicRamb/mtDNA_pipe.git```

If it is the first time running this (or it is a new PC), create the conda environment and activate it (or just activate it if you already have the env):

```cd mtDNA_pipe/```

```conda env create -f mtDNA-pipe.yml```

```conda activate mtDNA-pipe```

You can run the pipe on a test dataset by using:

```bash pipe_local.sh test-data/*.fastq.gz```

To run it on your data, execute the script specifying the path to your data (paired-end raw fastq files). The script creates a sub-directory for each sample in the main working directory where you launch it.

It is important to always have the "rCRS" folder in the same directory where you have and launch the script (otherwise you will have to change the path to rCRS inside the script).

Run on your data:

```bash pipe_local.sh PATH/TO/YOUR/DATA/*.fastq.gz```

# Output

In each sample's directory you will find the following sub-directories:

- **fastqc_raw**: QC on raw fastq
- **trm_fastq**: processed fastq
- **fastqc_trm**: QC on processed fastq
- **bam**: aligned and filtered reads (this is the file you'll need for mtDNA-server 2)
- **mosdepth**: stats on depth and coverage
- **multiqc**: aggregated stats and info on your sample (look at the multiqc_report.html file to QC your run and get info/stats of the sample)
- **logs**: all log files from each step

# mtDNA-server 2

You are now ready to run mtDNA-server 2 (https://doi.org/10.1093/nar/gkae296) to analyze and classify your samples.

Go to the Mitoverse page (https://mitoverse.i-med.ac.at/#!), register and/or login and run it.

To avoid selecting each BAM from each sample folder you can do the following (your current directory should be the one where you ran the script):

```mkdir all_bams```

```for BAM in $(find . -name '*.bam'); do cp ${BAM} all_bams/; done```

You can now select all bams from this directory when using mtDNA-server 2 (remember to delete thus folder once done to avoid having two copies of each bam file)

```rm -rf all_bams/```
