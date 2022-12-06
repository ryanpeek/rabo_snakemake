
# data here
/home/maccamp/from-slims/

# try a few things?
```
gunzip -c SOMM570_S1_L001_I1_001.fastq.gz | head -n 400000 | awk 'NR%4==2' > i1.fastq
gunzip -c SOMM570_S1_L001_I2_001.fastq.gz | head -n 400000 | awk 'NR%4==2' > i2.fastq

# see top indices:
paste i1.fastq i2.fastq | sort | uniq -c | sort -k 1 -n | tail

# look at unique 8 barcodes
cat r1.fastq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c

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
