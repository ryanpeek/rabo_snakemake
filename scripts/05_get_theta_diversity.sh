#!/bin/bash

#SBATCH -J rpthetacount
#SBATCH --mem 16G
#SBATCH -e slurms/thetas_count.%j.err
#SBATCH -o slurms/thetas_count.%j.out
#SBATCH -p high
#SBATCH --time=5-20:00:00

# run with: sbatch get_theta_diversity.sh rabo_sc rabo_sc_thetas

mkdir -p results_thetas  ### All output goes here ###

date

# just the first part of the file (i.e., rabo_sc)
file=$1 # file name without extension
outfile=$2 # what to save output as

# need to make list of filenames (using pestPG)
ls outputs/results_thetas/${file}*.gz.pestPG > outputs/results_thetas/${file}_thetalist_gw
# use ls of all files with gw_thetasWin.gz.pestPG to generate results
input="outputs/results_thetas/${file}_thetalist_gw"


wc=$(wc -l ${input} | awk '{print $1}')
x=1

echo "#id tw tw_sd tp tp_sd tD tD_sd ns" > outputs/results_thetas/${outfile}.txt  #i.e.,  theta_counts_gw
while [ $x -le $wc ] 
do

        string="sed -n ${x}p ${input}" 
        str=$($string)

        var=$(echo $str | awk -F"\t" '{print $1,$2,$3}')   
        set -- $var
        c1=$1
        c2=$2
        c3=$3
	# calc the mean and sd for wattersons theta, tajima theta, taj D and number of sites used genome wide:
	stats=$(cat ${c1} | awk '{ Tw += $4 }; {Twsq +=$4^2}; { Tp += $5 }; {Tpsq +=$5^2}; { Td += $9 }; {Tdsq +=$9^2}; { sites += $14 }; END { print Tw / sites" "sqrt(Twsq/NR-(Tw/NR)^2)" "Tp / sites" "sqrt(Tpsq/NR-(Tp/NR)^2)" "Td / sites" "sqrt(Tdsq/NR-(Td/NR)^2)" "sites }')
echo "${c1} $stats" >> outputs/results_thetas/${outfile}.txt

        x=$(( $x + 1 ))

done

