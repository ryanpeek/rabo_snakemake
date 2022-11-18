# rabo_snakemake

Snakemake workflow for RAD novaseq data


## Getting started

```
mamba create --file angsd.yml
mamba activate radseq
# or in conda
conda env create --name radseq --file environment.yml
conda activate radseq

### set a session:
srun -p high -J split -t 12:00:00 --mem=10G --pty bash

### run a test (dry run)
snakemake -n

### try this to submit 3 jobs at once, and rerun incompletes
snakemake -j 3 --use-conda --rerun-incomplete --latency-wait 15 --resources mem_mb=200000 --cluster "sbatch -t 10080 -J radseq -p high -n 1 -N 1" -k

### run 16 jobs and use default params from config  
snakemake -j 16 --use-conda --rerun-incomplete --latency-wait 15 --resources mem_mb=200000 --cluster "sbatch -t 10080 -J radseq -p high -n 1 -N 1 -c {threads} --mem={resources.mem_mb}" -k -n
```


