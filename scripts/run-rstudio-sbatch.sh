#! /bin/bash -login
#SBATCH -J rstudio-server
#SBATCH -t 3:00:00
#SBATCH -p high
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --mem=5gb
#SBATCH -e rstudio-%u.%j.err           # write stderr to this file - user/job
#SBATCH -o rstudio-%u.%j.out           # write stderr to this file - user/job

module load spack/R/4.1.1
module load rstudio-server/2022.07.1

rserver-farm
