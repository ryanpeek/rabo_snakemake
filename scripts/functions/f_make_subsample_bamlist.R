# filter bamlist by subsamples


# Libraries ---------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse);
  library(here);
  library(sf);
  library(glue);
})

#options(tibble.print_min = Inf) # print all rows 
options(scipen = 12)

# load bam filter and write functions
source("code/functions/f_write_bamlist_subsample.R")

# target bamlist
#targ_bamlist <- "raon_blackcanyon_curr_notran"
#meta <- read_rds("output/ronca_metadata_final_w_read_counts_sf.rds") %>% 
#  filter(!site_id=="SM")

# function ---------------------------------
f_make_subsample_bamlist <- function(
    targ_bamlist, 
    subsample = "30k"){
  
  # get target bamlist
  targ_bams <- read_tsv(glue("output/bamlists/{targ_bamlist}.bamlist"), 
                        col_names = "seqid") %>%
    # drop extension and /bams pre
    mutate(seq = str_replace(seqid, pattern = "\\..*", replacement = ""),
           seq = gsub(pattern = "bams/", replacement = "", seq))
  
  # read SOMM list (SOMM_AAGAGT_GGAAACATCGTGCAGG.merge.filt.bam)
  sub_bams <- read_tsv(
    glue("output/bamlists/z-archive/ronca_all_{subsample}.bamlist"), 
    col_names = "seqid_sub") %>%
    mutate(seq = str_replace(seqid_sub, pattern = "\\..*", replacement = ""))
  
  # now join target with subsampled list
  df_out <- inner_join(targ_bams, sub_bams, by="seq")
  
  # print how things have changed:
  print(glue("Originally {nrow(targ_bams)} samples, now {nrow(df_out)}. n={nrow(targ_bams)-nrow(df_out)} samples lost"))
  
  # write out
  bam_write_subsample(df_out, bamlist_name = targ_bamlist, subsample = subsample)
}




