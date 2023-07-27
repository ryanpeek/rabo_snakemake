#!/bin/bash -l

#SBATCH --mail-user=rapeek@ucdavis.edu
#SBATCH --mail-type=ALL
#SBATCH -J sfs
#SBATCH -o slurms/sfs_main.%j.out
#SBATCH -c 4
#SBATCH -p high
#SBATCH -t 720

# run with
# sbatch get_sfs_nosub.sh outputs/bamlists/sfs_pop_list

mkdir -p outputs/results_sfs

infile=$1 ### list containing population names ###

## IMPORTANT!!! Reference must correspond to ancestral states, if not supply a different fasta file for -anc!!! ###
# set reference alignment
ref="/home/rapeek/projects/SEQS/final_contigs_300.fa"


n=$(wc $infile | awk '{print $1}')

### Calculate saf files and the ML estimate of the sfs using the EM algorithm for each population ###
x=1
while [ $x -le $n ] 
do
        pop=$(sed -n ${x}p $infile)
                echo "#!/bin/bash" > ${pop}_sfs.sh
                echo "" >> ${pop}_sfs.sh
		echo "#SBATCH -o slurms/sfs_pop-%j.out" >> ${pop}_sfs.sh
		echo "#SBATCH -e slurms/sfs_pop-%j.err" >> ${pop}_sfs.sh
		echo "#SBATCH -J sfsFold" >> ${pop}_sfs.sh
		echo "" >> ${pop}_sfs.sh
		
		# if no filter paralogs, use this line for unfolded
		echo "angsd -bam outputs/bamlists/${pop}.bamlist -ref $ref -anc $ref -sites bait_lengths.txt -out outputs/results_sfs/${pop} -GL 2 -doSaf 1 -minMapQ 10 -minQ 20" >> ${pop}_sfs.sh
                # make unfolded initially and only fold AFTER for 2DSFS: see here: https://github.com/ANGSD/angsd/issues/259 
		
		# take sfs
		echo "realSFS outputs/results_sfs/${pop}.saf.idx -maxIter 100 > outputs/results_sfs/${pop}.sfs" >> ${pop}_sfs.sh
                # bootstrap
		echo "realSFS outputs/results_sfs/${pop}.saf.idx -bootstrap 100 -P 10 > outputs/results_sfs/${pop}_b.sfs" >> ${pop}_sfs.sh
		
		# plot
		#echo "~/scripts/plotSFS.R results_sfs/${pop}.sfs" >> ${pop}_sfs.sh
                
		#sbatch -J rpsfs -t 2880 --mem=16G -c 1 ${pop}_sfs.sh
		sbatch -J rpsfs -t 2880 -p high -c 4 ${pop}_sfs.sh
        x=$(( $x + 1 ))

done


<<Comment
### Calculate common sites and saf files for use in NGStools ###

list=$(sed 's/$/\.saf\.idx/' $infile | sed 's/^/results_sfs\//' | tr '\n' ' ')

echo "#!/bin/bash
#SBATCH -o slurm_outs/oldsaf-%j.out
realSFS print $list -oldout 1
" > oldsaf.sh

sbatch -J rapsaf -t 720 --mem=60G oldsaf.sh

zless shared.pos.gz | awk '{print $1}' | sort | uniq > common_loci.list

Comment

