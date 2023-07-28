#!/bin/bash

#SBATCH --mail-user=rapeek@ucdavis.edu
#SBATCH --mail-type=ALL
#SBATCH -J pca_ibs
#SBATCH -e slurms/pca_ibs.%j.err
#SBATCH -o slurms/pca_ibs.%j.out
#SBATCH -c 20
#SBATCH -p high
#SBATCH --time=5-20:00:00

#set -e # exits upon failing command
set -v # verbose -- all lines
set -x # trace of all commands after expansion before execution

# run script with
#       sbatch --mem MaxMemPerNode pca.sh bamlistNAME outname

# bamlist
bamlist=$1
outname=$2
ref="/home/rapeek/projects/SEQS/final_contigs_300.fa" # de novo reference alignment

# make results folder
mkdir -p outputs/pca

echo "Starting Job: "
date


nInd=$(wc outputs/bamlists/${bamlist} | awk '{print $1}')
#minInd=$[$nInd/5]
minInd=3

# PCAngsd (http://www.popgen.dk/software/index.php/PCAngsd)

# make sure to index
# angsd sites index bait_lengths.txt 


## First generate genotype likelihoods in Beagle format using angsd
#angsd -bam ${bamlist} -out results_pca/${outname}_genolikes -doGlf 2 -doMajorMinor 1 -minMaf 0.05 -doMaf 2 -minInd ${minInd} -minMapQ 30 -minQ 20 -SNP_pval 1e-9 -GL 2 -nThreads 16 -ref $ref -sites bait_lengths.txt
angsd -bam outputs/bamlists/${bamlist} -out outputs/pca/${outname} -doIBS 1 -doCounts 1 -doMajorMinor 1 -minFreq 0.05 -maxMis ${minInd} -minMapQ 30 -minQ 20 -SNP_pval 1e-6 -makeMatrix 1 -doCov 1 -GL 1 -doMaf 1 -nThreads 16 -ref $ref -sites bait_lengths.txt

echo "Done!"


