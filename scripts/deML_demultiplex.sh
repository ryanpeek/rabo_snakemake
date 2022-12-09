#!/bin/bash
##Name: deML_demultiplex.sh




manifest=$1	#doc containing barcodes and sample names
r1=$2	#read1 file
r2=$3	#read2 file
i1=$4	#index1 (i7)
i2=$5	#index2 (i5)
outpre=$6	#path and prefix of output files (program adds "_" after)
summary=$7	#name of summary file
error=$8	#name of error file

# install in bin via git: git clone https://github.com/grenaud/deML.git and then "make" in dir
~/bin/deML/src/deML -i ${manifest} -f ${r1} -r ${r2} -if1 ${i1} -if2 ${i2} -o ${outpre} -s ${summary} -e ${error} --mm 1


# run with
# sbatch -t 1440 -p high scripts/deML_demultiplex.sh samples/frog_somm570_deML_manifest.csv inputs/SOMM570_S1_L002_R1_001.fastq.gz inputs/SOMM570_S1_L002_R2_001.fastq.gz inputs/skSOMM570_S1_L002_I1_001.fq.gz inputs/skSOMM570_S1_L002_I2_001.fq.gz inputs/somm570frog somm570_summary somm570_errors