
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

