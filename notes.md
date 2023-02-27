
# Investigating Seqs

First we need to start an interactive session:

`srun --partition=high --time=24:00:00 --mem=10G --nodes=1 --pty /bin/bash -il`

## Unzip and Get 100k

Try unzipping and `awk` the indexes out for the first 100k reads.

```
gunzip -c skSOMM570_S1_L002_I1_001.fq.gz | head -n 400000 | awk 'NR%4==2' > somm570_i1.fq
gunzip -c skSOMM570_S1_L002_I2_001.fq.gz | head -n 400000 | awk 'NR%4==2' > somm570_i2.fq
```

## Look at top barcodes

```
paste somm570_i1.fq somm570_i2.fq | sort | uniq -c | sort -k 1 -n | tail
```
Which returns this:

```
1161 TCTTGTAT        AGATCTCG
1230 AGAGTCAT        AGATCTCG
1575 GGACCGAT        TGATACGC
1756 CACGCGAT        CTCTGGTT
1975 GCGCCCAT        TACCACAG
1975 TGGTTCAT        AGATCTCG
2063 TCTGCGAT        TTGGTGAG
2116 CGCCCCAT        GTCGGTAA
2695 CTTGCCAT        ACCAATGC
3185 CATTTCAT        AGATCTCG
```

## Look at unique 8 barcodes

```
cat somm570_i1.fq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c

```

## `grep` checks for well barcodes


```
cat r1.fastq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c
```

### to grep files w radseq data

```
gunzip -c r1.fastq.gz | head -n 400000 | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c | sort -k 1 -n | tail
```

# Unzip files in parallel

Important to do this in an interactive session. This unzips multiple files (8 in this case so 8 jobs in parallel).

```
parallel --jobs 8 gunzip {} ::: *.fq.gz
```

# Snakemake

We can then use snakemake to do the well split, alignment and general analysis.

```
snakemake -j 16 --use-conda --rerun-incomplete --unlock --latency-wait 15 --cluster "sbatch -t 5000 -J radseq -p high -n 1 -N 1 --mail-user=rapeek@ucdavis.edu -o slurms/align_%j.out" -k -n
```

If we want to try a dry run, make sure to use `-n`. Sometimes we need to use the `--unlock` flag too if things break along the way and we need to restart.

# Look at Alignment Stats

## Calculate Mean Read Depth v1

To look at coverage we can generate coverage per locus with samtools.

```
samtools depth mybam.sort.bam > reads.sort.coverage

# then look at this to calculate the avg coverage (or depth) over the sequenced region:
cat reads.sort.coverage | sort -g -k 3 | awk '{sum+=$3} END {if (NR > 0) print "AVG=",sum/NR,"\\n"}'

# or in a single line calc average coverage for each sample or bam
samtools depth bam.sort.fam | awk '{sum+=$3} END {if (NR > 0) print "AVG=", sum/NR}'

```

To combine all:

```
cat *depth > all_bams_depth.txt
```

## Calculate Mean Read Depth v2

Provides the ref seq name, the 1-based left mapped position, and the depth at position. Gives the total positions (c) and cumulative depth (s) for mean read depth.

```
samtools depth -a file.bam | awk '{c++;s+=$3}END{print s/c}'
```

## Breadth of Coverage

Depth at each position, `-a` means even zero depth. `c` is the total positions, so this gives the "breadth of coverage" for alignment.

```
samtools depth -a file.bam | awk '{c++; if($3>0) total+=1}END{print (total/c)*100}'
```

## Proportion of reads that mapped to the reference

```
samtools flagstat file.bam | awk -F "[(|%]" 'NR == 3 {print $1}' | cut -d" " -f1
```

From samtools flagstat: 

```
print 'total_reads' 'mapped_reads' 'paired_reads' 'proper_pairs' > tst.txt

# total reads
samtools flagstat ${c1} | sed -n 1p | IFS=':' cut -f2 | paste  -d" " - >> tst.txt
# or 
samtools flagstat ${c1} | sed -n 1p | cut -d" " -f1 | paste  -d" " - >> tst.txt

# mapped reads
samtools flagstat ${c1} | sed -n 5p | IFS=':' cut -f2 | paste  -d" " - >> tst.txt

# paired in sequencing
samtools flagstat ${c1} | sed -n 8p | IFS=':' cut -f2 | paste  -d" " - >> tst.txt

# proper pairs
samtools flagstat ${c1} | sed -n 9p | IFS=':' cut -f2 | paste  -d" " - >> tst.txt


# paste the status from above together into a single file
paste $list count1_aligns.txt count2_mapped.txt count3_paired.txt count4_ppaired.txt > alignment_stats.txt

# add header row
sed -i '1ibamfile\ttotal_aligns\tmapped_aligns\tpaired_aligns\tprop_pairs' alignment_stats.txt

```
