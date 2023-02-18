#! /bin/bash

module load spack/R/4.1.1
module load rstudio-server/2022.07.1

rserver-farm


# to run use:
# srun -p high --time=3:00:00 --nodes=1 \
#            --cpus-per-task 1 --mem 5GB --pty bash ./run-rstudio.sh
