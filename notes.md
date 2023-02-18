
# data here
/home/maccamp/from-slims/

# try a few things?
```
gunzip -c skSOMM570_S1_L002_I1_001.fq.gz | head -n 400000 | awk 'NR%4==2' > somm570_i1.fq
gunzip -c skSOMM570_S1_L002_I2_001.fq.gz | head -n 400000 | awk 'NR%4==2' > somm570_i2.fq

# see top indices:
paste somm570_i1.fq somm570_i2.fq | sort | uniq -c | sort -k 1 -n | tail
```
# which returns this:

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

# look at unique 8 barcodes
cat somm570_i1.fq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c

```

# grep notes

### grep for well barcodes

```
cat r1.fastq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c
```

### to grep files w radseq data

```
gunzip -c r1.fastq.gz | head -n 400000 | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c | sort -k 1 -n | tail
```

# Demultiplexing

