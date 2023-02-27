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

# write just historical or current
df_raon_ns %>% 
  group_by(site_type, site_id, samp_year) %>% 
  tally()

# write HISTORICAL
df_raon_ns_hist <- df_raon_ns %>% 
  filter(samp_year<2010)

# write all for mult pop comparison
bam_write(df_raon_ns_hist, somms = "SOMM", bamlist_name = "raon_northshore_hist")

# write CURRENT
df_raon_ns_curr <- df_raon_ns %>% 
  filter(samp_year>2010)

# write all for mult pop comparison
bam_write(df_raon_ns_curr, somms = "SOMM", bamlist_name = "raon_northshore_curr")

# get list of names
subpop_names <- df_raon_ns %>% st_drop_geometry() %>%
  ungroup() %>% 
  mutate(site_lab = case_when(
    grepl("Blue Point Spring, lower", site) ~ "BPL",
    grepl("Blue Point Spring, upper", site) ~ "BPU",
    TRUE ~ site_id
  )) %>% 
  arrange(site_lab) %>% 
  distinct(site, site_lab, site_id, samp_year) %>% 
  mutate(site_id_yr = glue("{site_lab}_{samp_year}")) %>% 
  group_by(site_id_yr)

# write just historical or current
df_raon_ns %>% 
  group_by(site, samp_year) %>% 
  tally()

# split out by subpop and sample year
df_ns_subpops <- df_raon_ns %>% st_drop_geometry() %>% 
  ungroup() %>% 
  mutate(site_lab = case_when(
    grepl("Blue Point Spring, lower", site) ~ "BPL",
    grepl("Blue Point Spring, upper", site) ~ "BPU",
    TRUE ~ site_id
  )) %>% 
  arrange(site_lab) %>% 
  mutate(site_id_yr = glue("{site_lab}_{samp_year}")) %>% 
  split(.$site_id_yr)

# check and write
purrr::map_int(df_ns_subpops, ~dim(.x)[1])

# now loop through and write out
imap(df_ns_subpops, 
     ~bam_write(.x, somms = "SOMM", bamlist_name = glue("raon_northshore_{.y}"), outdir="output/bamlists"))

## BAMLIST: BLACK CANYON -------------------------------

# just black canyon sites (hist and curr)
df_raon_bc <- df_raon_final %>% st_drop_geometry() %>% 
  filter(species=="RAON", analysis=="Y") %>% 
  filter(site_id %in% c("PR", "GC", "BS", "SC", "BL", "BH")) %>% 
  #BC only, n=188, fix year so it's even for comparisons
  mutate(samp_year = case_when(
    samp_year == 1997 ~ 1998,
    TRUE ~ samp_year))

# write all for PCA comparison
bam_write(df_raon_bc, somms = "SOMM", bamlist_name = "raon_blackcanyon")

# write just historical or current
df_raon_bc %>% 
  group_by(site_type, site_id, samp_year) %>% 
  tally()

# write HISTORICAL
df_raon_bc_hist <- df_raon_bc %>% 
  filter(samp_year<2010)
# write all for mult pop comparison
bam_write(df_raon_bc_hist, somms = "SOMM", bamlist_name = "raon_blackcanyon_hist")

# write CURRENT (but exclud TRANS sites)
df_raon_bc_curr_no_tran <- df_raon_bc %>% 
  filter(samp_year>2010, !site_type=="Tran")

# write all for mult pop comparison
bam_write(df_raon_bc_curr_no_tran, somms = "SOMM", bamlist_name = "raon_blackcanyon_curr_notran")

# write CURRENT (but include TRANS sites)
df_raon_bc_curr <- df_raon_bc %>% 
  filter(samp_year>2010)

# write all for mult pop comparison
bam_write(df_raon_bc_curr, somms = "SOMM", bamlist_name = "raon_blackcanyon_curr")

# get list of names
subpop_names <- df_raon_bc %>% st_drop_geometry() %>%
  ungroup() %>% 
  arrange(site_id) %>% 
  distinct(site, site_id, samp_year) %>% 
  mutate(site_id_yr = glue("{site_id}_{samp_year}")) %>% 
  group_by(site_id_yr) %>% 
  distinct(site_id_yr, .keep_all = TRUE)

# write just historical or current
df_raon_bc %>% 
  group_by(site_id, samp_year) %>% 
  tally()

# split out by subpop and sample year
df_bc_subpops <- df_raon_bc %>% st_drop_geometry() %>% 
  ungroup() %>% 
  arrange(site_id) %>% 
  mutate(site_id_yr = glue("{site_id}_{samp_year}")) %>% 
  split(.$site_id_yr)

# check and write
purrr::map_int(df_bc_subpops, ~dim(.x)[1])

# now loop through and write out
imap(df_bc_subpops, 
     ~bam_write(.x, somms = "SOMM", bamlist_name = glue("raon_blackcanyon_{.y}"), outdir="output/bamlists"))

## BAMLIST: LITTLEFIELD ----------------------------------------

# just littlefield sites (hist only)
df_raon_lf <- df_raon_final %>% st_drop_geometry() %>% 
  filter(species=="RAON", analysis=="Y") %>% 
  filter(site_id %in% c("LF")) #LF, n=13

# write all for PCA comparison
bam_write(df_raon_lf, somms = "SOMM", bamlist_name = "raon_littlefield")

# write just historical or current
df_raon_lf %>% 
  group_by(site_type, site_id, samp_year) %>% 
  tally()

# get list of names
subpop_names <- df_raon_lf %>% st_drop_geometry() %>%
  ungroup() %>% 
  mutate(site_lab = "LF") %>%  
  arrange(site_lab) %>% 
  distinct(site, site_lab, site_id, samp_year) %>% 
  mutate(site_id_yr = glue("{site_lab}_{samp_year}")) %>% 
  group_by(site_id_yr)

# write just historical or current
df_raon_lf %>% 
  group_by(site, samp_year) %>% 
  tally()

# split out by subpop and sample year
df_lf_subpops <- df_raon_lf %>% st_drop_geometry() %>% 
  ungroup() %>% 
  mutate(site_lab = "LF") %>%  
  arrange(site_lab) %>% 
  mutate(site_id_yr = glue("{site_lab}_{samp_year}")) %>% 
  split(.$site_id_yr)

# check and write
purrr::map_int(df_lf_subpops, ~dim(.x)[1])

# now loop through and write out
imap(df_lf_subpops, 
     ~bam_write(.x, somms = "SOMM", bamlist_name = glue("raon_littlefield_{.y}"), outdir="output/bamlists"))


## BAMLIST: TRANSLOCATION SITES ONLY ----------------------------------

# ronca_tran
df_raon_final %>% st_drop_geometry() %>%  
  filter(species=="RAON", analysis=="Y", site_type=="Tran") %>% 
  group_by(site, site_type, site_id, samp_year) %>% 
  tally() %>% 
  as.data.frame() %>% 
  arrange(site_id) %>% print()

df_raon_tran <- df_raon_final %>% st_drop_geometry() %>% 
  filter(species=="RAON", analysis=="Y", site_type=="Tran")
# write all
bam_write(df_raon_tran, somms = "SOMM", bamlist_name = "raon_tran_all")

# get list of names
subpop_names <- df_raon_tran %>% st_drop_geometry() %>%
  ungroup() %>% 
  arrange(site_id) %>% 
  distinct(site, site_id, samp_year) %>% 
  mutate(site_id_yr = glue("{site_id}_{samp_year}")) %>% 
  group_by(site_id_yr) %>% 
  distinct(site_id_yr, .keep_all = TRUE)

# write just historical or current
df_raon_tran %>% 
  group_by(site_id, samp_year) %>% 
  tally()

# split out by subpop and sample year
df_tran_subpops <- df_raon_tran %>% st_drop_geometry() %>% 
  ungroup() %>% 
  arrange(site_id) %>% 
  mutate(site_id_yr = glue("{site_id}_{samp_year}")) %>% 
  split(.$site_id_yr)

# check and write
purrr::map_int(df_tran_subpops, ~dim(.x)[1])

# now loop through and write out
imap(df_tran_subpops, subpop_names$site_id_yr, 
     ~bam_write(.x, somms = "SOMM", bamlist_name = glue("raon_translocated_{.y}"), outdir="output/bamlists"))


# PUT BAMLIST ON CLUSTER -----------------------------------------


# go to local dir with bamlists
# cd data_output/bamlists/
# sftp farm
# cd /group/millermrgrp3/ryan3/ronca/bamlists
glue("put {somms}_{bamlistName}*") # (this goes from local to cluster)
glue("put {bamlistName}*") # (this goes from local to cluster)

# CALL ANGSD PCA  -----------------------------------------------------

# NEW PCA method...run from SEQS
# farm
paste0("cd /group/millermrgrp3/ryan3/ronca/")
bamlist <- "ronca_only_nodups.bamlist"
# glue("sbatch --mem=60G code/08_pcAngsd.sh {bamlist}")
glue("sbatch 05_pca_ibs.sh {bamlist} /group/millermrgrp3/ryan3/ronca/bams")

# ANGSD ADMIX --------------------------------------------------------

# ADMIX k=12 (sbatch -t 3600 -p med --mem=60G 04_get_admix.sh all_rabo_filt10_100k 12)
#paste0("sbatch -p med -t 3600 --mem=60G --mail-type ALL --mail-user rapeek@ucdavis.edu 04_get_admix.sh ", siteName,"_",bamNo,"k ", 12)

# sbatch --mem MaxMemPerNode 09_admix.sh ronca_subpop_GS_2018 2

