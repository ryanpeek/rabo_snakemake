
# data here
/home/maccamp/from-slims/

# try a few things?
cat r1.fastq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c

gunzip -c r1.fastq.gz | head -n 400000 | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c | sort -k 1 -n | tail


# grep notes

### grep for well barcodes

```
cat r1.fastq | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c
```

### to grep files w radseq data

```
gunzip -c r1.fastq.gz | head -n 400000 | grep ^GG | perl -ne 'while(m/^GG(\w{8})TGCAGG/g){print $1."\n"}'| sort | uniq -c | sort -k 1 -n | tail
```