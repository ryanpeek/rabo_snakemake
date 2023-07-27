#!/bin/bash

#SBATCH -J fstPrep
#SBATCH -o slurms/get_fst.%j.out
#SBATCH -p high
#SBATCH -t 700

mkdir -p outputs/results_fst  ### All output goes here ###

# run with: sbatch 06_get_sfs_fst.sh outputs/bamlists/sfs_subpops_no_ext

infile=$1 ### list containing population names ###
#thresh=$2 # filtered threshold (i.e., 30k)
n=$(wc -l $infile | awk '{print $1}')

### calculate all pairwise 2dsfs's then Fst ###
x=1
while [ $x -le $n ] 
do
	y=$(( $x + 1 ))
	while [ $y -le $n ]
	do
	
	pop1=$( (sed -n ${x}p $infile) )  
	pop2=$( (sed -n ${y}p $infile) )

		echo "#!/bin/bash" > ${pop1}.${pop2}.sh
		echo "" >> ${pop1}.${pop2}.sh	
		echo "#SBATCH -o slurms/sfs_fst-%j.out" >> ${pop1}.${pop2}.sh
		echo "#SBATCH -e slurms/sfs_fst-%j.err" >> ${pop1}.${pop2}.sh
		echo "" >> ${pop1}.${pop2}.sh

		# calculate folded 2DSFS: see here: https://github.com/ANGSD/angsd/issues/259
		echo "realSFS outputs/results_sfs/${pop1}.saf.idx outputs/results_sfs/${pop2}.saf.idx -fold 1 > outputs/results_fst/${pop1}.${pop2}.folded.ml" >> ${pop1}.${pop2}.sh
		
		# use unfolded saf and folded sfs (.ml file) to calc per site fst.idx file (for small pops -whichFst 1)
		echo "realSFS fst index outputs/results_sfs/${pop1}.saf.idx outputs/results_sfs/${pop2}.saf.idx -whichFst 1 -sfs outputs/results_fst/${pop1}.${pop2}.folded.ml -fstout outputs/results_fst/${pop1}.${pop2}.folded" >> ${pop1}.${pop2}.sh
		
		# calc FST global estimate
		echo "realSFS fst stats outputs/results_fst/${pop1}.${pop2}.folded.fst.idx > outputs/results_fst/${pop1}.${pop2}.folded.Fst" >> ${pop1}.${pop2}.sh

		sbatch -J rp2dFst -p high --mem=8G -t 2000 -c 4 ${pop1}.${pop2}.sh

	y=$(( $y + 1 ))
	
	done

x=$(( $x + 1 ))

done

