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
