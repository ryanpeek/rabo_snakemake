#!/bin/bash -l

#SBATCH -e slurms/bamstats.%j.err
#SBATCH -o slurms/bamstats.%j.out
#SBATCH -c 20
#SBATCH -p high
#SBATCH --time=270

module load samtools

# bamlist
list=$1

wc=$(wc -l ${list} | awk '{print $1}')

x=1
while [ $x -le $wc ] 
do
string="sed -n ${x}p ${list}"
str=$($string)

var=$(echo $str | awk -F"\t" '{print $1, $2, $3}')
set -- $var
c1=$1
c2=$2
c3=$3

# total reads
samtools flagstat ${c1} | sed -n 1p | cut -d" " -f1 >> outputs/count1_aligns.txt

# mapped reads
samtools flagstat ${c1} | sed -n 5p | cut -d" " -f1 >> outputs/count2_mapped.txt

# paired in sequencing
samtools flagstat ${c1} | sed -n 8p | cut -d" " -f1 >> outputs/count3_paired.txt

# proper pairs
samtools flagstat ${c1} | sed -n 9p | cut -d" " -f1 >> outputs/count4_ppaired.txt

x=$(( $x + 1 ))

done

# paste the status from above together into a single file
paste $list outputs/count1_aligns.txt outputs/count2_mapped.txt outputs/count3_paired.txt outputs/count4_ppaired.txt > outputs/alignment_stats.txt

# add header row
sed -i '1ibamfile\ttotal_aligns\tmapped_aligns\tpaired_aligns\tprop_pairs' outputs/alignment_stats.txt

rm outputs/count?_*.txt


