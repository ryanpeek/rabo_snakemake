# make South Coast sample bamlist

library(tidyverse)
library(fs)
library(sf)
library(glue)
library(mapview)
mapviewOptions(fgb=FALSE)

#options(tibble.print_min = Inf) # print all rows 
options(scipen = 12)

# load bam filter and write functions
source("scripts/functions/f_write_bamlist.R")

# Get Data ----------------------------------------------------------------

dat <- read_csv("samples/2022_metadata_seq_samples_joined.csv")

# make sf
dat_sf <- dat %>% filter(!is.na(y)) %>%  # rm blank
  st_as_sf(coords=c("x","y"), remove=FALSE, crs=4326)

# select just SC sites
sc_sites <- c("San Carpoforo Creek", "Dutra", "Burro")

# filter down
dat_sc <- dat_sf %>% filter(grepl(glue_collapse(sc_sites,"|"), locality))

# Relabel -----------------------------------------------------------------

# add new better labels
dat_sc <- dat_sc %>% 
  mutate(river = case_when(
    grepl("Dutra Creek", locality) ~ "Dutra_Ck",
    grepl("Burro Creek", locality) ~ "Burro_Ck",
    grepl("San Carpoforo", locality) ~ "San Carpoforo"), .before="locality")

# quick map
mapview(dat_sc, zcol="river")

# Make Bamlists -------------------------------------------------------

## Make All Bamlist --------------------------------------

dat_sc_all <- dat_sc %>% st_drop_geometry() 

# write all for PCA comparison
bam_write(dat_sc_all, somms = "SOMM570", bamlist_name = "rabo_sc_all", extension = "sort.flt.bam")

## Make Burros Bamlist --------------------------------------

dat_sc_burro <- dat_sc %>% st_drop_geometry() %>% 
  filter(river=="Burro_Ck")

# write for PCA comparison
bam_write(dat_sc_burro, somms = "SOMM570", bamlist_name = "rabo_sc_burro", extension = "sort.flt.bam")

## Make SanCarpoforos Bamlist --------------------------------------

dat_sc_sancarp <- dat_sc %>% st_drop_geometry() %>% 
  filter(river=="San Carpoforo")

# write for PCA comparison
bam_write(dat_sc_sancarp, somms = "SOMM570", bamlist_name = "rabo_sc_sancarp", extension = "sort.flt.bam")

## Make Dutra Bamlist --------------------------------------

dat_sc_dutra <- dat_sc %>% st_drop_geometry() %>% 
  filter(river=="Dutra_Ck")

# write for PCA comparison
bam_write(dat_sc_dutra, somms = "SOMM570", bamlist_name = "rabo_sc_dutra", extension = "sort.flt.bam")



# PUT BAMLIST ON CLUSTER -----------------------------------------

# go to local dir with bamlists
# cd outputs/bamlists/
# sftp farm
# cd /group/millermrgrp3/ryan3/sneks/rabo_snakemake/outputs/bamlists
somms <- "SOMM570"
bamlistName <- "rabo_sc_all"
glue("put {somms}_{bamlistName}*") # (this goes from local to cluster)
glue("put {bamlistName}*") # (this goes from local to cluster)

# CALL ANGSD PCA  -----------------------------------------------------

# NEW PCA method...run from SEQS
# farm
# glue("sbatch --mem=60G code/08_pcAngsd.sh {bamlist}")
glue("sbatch 05_pca_ibs.sh {bamlistName} /group/millermrgrp3/ryan3/ronca/bams")

# ANGSD ADMIX --------------------------------------------------------

# ADMIX k=12 (sbatch -t 3600 -p med --mem=60G 04_get_admix.sh all_rabo_filt10_100k 12)
#paste0("sbatch -p med -t 3600 --mem=60G --mail-type ALL --mail-user rapeek@ucdavis.edu 04_get_admix.sh ", siteName,"_",bamNo,"k ", 12)

# sbatch --mem MaxMemPerNode 09_admix.sh ronca_subpop_GS_2018 2

