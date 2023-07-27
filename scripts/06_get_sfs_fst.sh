#!/bin/bash

#SBATCH -J fstPrep
#SBATCH -o slurms/13_fst.%j.out
#SBATCH -p high
#SBATCH -t 700

mkdir -p results_fst  ### All output goes here ###

# run with: sbatch 13_get_2dsfs_fst.sh bamlists/subpops/sfs_subpops_no_ext 30k 

infile=$1 ### list containing population names ###
thresh=$2 # filtered threshold
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
		echo "#SBATCH -o slurms/13_2dsfs_fst-%j.out" >> ${pop1}.${pop2}.sh
		echo "#SBATCH -e slurms/13_2dsfs_fst-%j.err" >> ${pop1}.${pop2}.sh
		echo "" >> ${pop1}.${pop2}.sh

		# calculate folded 2DSFS: see here: https://github.com/ANGSD/angsd/issues/259
		echo "realSFS results_sfs/${pop1}_${thresh}.saf.idx results_sfs/${pop2}_${thresh}.saf.idx -fold 1 > results_fst/${pop1}.${pop2}_${thresh}.folded.ml" >> ${pop1}.${pop2}.sh
		
		# use unfolded saf and folded sfs (.ml file) to calc per site fst.idx file (for small pops -whichFst 1)
		echo "realSFS fst index results_sfs/${pop1}_${thresh}.saf.idx results_sfs/${pop2}_${thresh}.saf.idx -whichFst 1 -sfs results_fst/${pop1}.${pop2}_${thresh}.folded.ml -fstout results_fst/${pop1}.${pop2}_${thresh}.folded" >> ${pop1}.${pop2}.sh
		
		# calc FST global estimate
		echo "realSFS fst stats results_fst/${pop1}.${pop2}_${thresh}.folded.fst.idx > results_fst/${pop1}.${pop2}_${thresh}.folded.Fst" >> ${pop1}.${pop2}.sh

		#sbatch -J ryan2dsfs --mem=60G -t 720 -c 1 ${pop1}.${pop2}.sh
		sbatch -J rp2dFst -p high --mem=8G -t 2000 -c 4 ${pop1}.${pop2}.sh

	y=$(( $y + 1 ))
	
	done

x=$(( $x + 1 ))

done

