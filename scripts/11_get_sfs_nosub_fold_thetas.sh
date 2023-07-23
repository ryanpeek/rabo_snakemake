#!/bin/bash

#SBATCH --mail-user=rapeek@ucdavis.edu
#SBATCH --mail-type=ALL
#SBATCH -J sfs
#SBATCH -o slurms/11_sfsMain.%j.out
#SBATCH -p high
#SBATCH -c 10
#SBATCH -t 720

mkdir -p results_sfs_folded  ### All output goes here ###

infile=$1 ### list containing population names ##
#thresh=$2 # label for level of subsample/threshold used, i.e., 25k, or 100k

## IMPORTANT!!! Reference must correspond to ancestral states, if not supply a different fasta file for -anc!!! ###
# set reference alignment
ref="/home/rapeek/projects/SEQS/final_contigs_300.fa"

n=$(wc -l $infile | awk '{print $1}')

### Calculate saf files and the ML estimate of the sfs using the EM algorithm for each population ###
x=1
while [ $x -le $n ] 
do

	pop=$(sed -n ${x}p $infile)

		echo "#!/bin/bash" > ${pop}_folded.sh
		echo "" >> ${pop}_folded.sh
		echo "#SBATCH -o slurms/11_sfs_folded-%j.out" >> ${pop}_folded.sh
		echo "#SBATCH -e slurms/11_sfs_folded-%j.err" >> ${pop}_folded.sh
		echo "#SBATCH -J sfsPop" >> ${pop}_folded.sh
		echo "" >> ${pop}_folded.sh
		
		# new method uses default sfs (fold after), this script assumes SFS exists
		echo "realSFS results_sfs/${pop}.saf.idx -fold 1 > results_sfs_folded/${pop}.folded.sfs" >> ${pop}_folded.sh
		# bootstrap
		echo "realSFS results_sfs/${pop}.saf.idx -bootstrap 100 -P 10 > results_sfs_folded/${pop}_b.folded.sfs" >> ${pop}_folded.sh

		# make a plot
		echo "~/scripts/plotSFS.R results_sfs_folded/${pop}.folded.sfs" >> ${pop}_folded.sh

		# calc thetas for each site:
		mkdir -p results_thetas

		# this makes .thetas.idx
		echo "realSFS saf2theta results_sfs/${pop}.saf.idx -sfs results_sfs_folded/${pop}.folded.sfs -outname results_thetas/${pop}_folded" >> ${pop}_folded.sh

		# get logscale per site thetas with: thetaStat print out.thetas.idx 2>/dev/null | head
		# get genome side theta stats with sliding window of one (every site), output is idx.pestPG
		echo "thetaStat do_stat results_thetas/${pop}_folded.thetas.idx -win 1 -step 1 -outnames results_thetas/${pop}_folded_gw_thetasWin.gz" >> ${pop}_folded.sh

		#sbatch -J rpfoldsfs --mem=16G -t 2880 -c 1 ${pop}_folded.sh
		sbatch -J rpfoldsfs -t 720 -p high -c 1 ${pop}_folded.sh
	x=$(( $x + 1 ))

done

