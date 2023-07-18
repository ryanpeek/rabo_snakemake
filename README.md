# rabo_snakemake

Snakemake workflow for RABO radseq data

## Working on Cluster

If working on cluster, need an interactive session first, so not on headnode.

```
# session
srun --partition=high --time=24:00:00 --mem=10G --nodes=1 --pty /bin/bash -il
```


## Install Conda

```
echo source ~/.bashrc >> ~/.bash_profile
curl -LO https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh 

# fix channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

# then good to go!
```

## Getting started

```
# create environment
conda env create --name snakemake --file environment.yml
conda activate snakemake

# set a session (if haven't already):
srun -p high -J split -t 12:00:00 --mem=10G --pty bash

# run a test (dry run)
snakemake -j 1 --use-conda --rerun-incomplete --latency-wait 15 --resources mem_mb=200000 --cluster "sbatch -t 1080 -J fastqc -p high -n 1 -N 1" -k -n

# try this to submit 3 jobs at once, and rerun incompletes
snakemake -j 3 --use-conda --rerun-incomplete --latency-wait 15 --resources mem_mb=200000 --cluster "sbatch -t 10080 -J radseq -p high -n 1 -N 1" -k

# run 16 jobs and use default params from config  
snakemake -j 16 --use-conda --rerun-incomplete --latency-wait 15 --resources mem_mb=200000 --cluster "sbatch -t 10080 -J radseq -p high -n 1 -N 1 -c {threads} --mem={resources.mem_mb}" -k -n
```


