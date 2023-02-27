# function to write to bamlist

library(dplyr)
library(fs)
library(glue)

bam_write <- function(data, 
                      somms ="SOMMS",# name of SOMM prefix 
                      bamlist_name, # name of bamlist to write
                      outdir ="outputs/bamlists",
                      extension = "sort.flt.bam"
){ # outdir default
  
  # create dir if it doesn't exist
  fs::dir_create(outdir)
  
  # Write to bamlist for angsd call (for IBS, pcAngsd)
  data <- data %>% 
    mutate(seqid=glue("{plate_barcode}_GG{well_barcode}TGCAGG"))
  
  # write out SOMM list
  cat(glue("writing bamlist to: \n {outdir}/{bamlist_name}.bamlist"))
  write_delim(as.data.frame(
    glue("outputs/bams/{somms}_{data$seqid}.{extension}")),
    file = glue("{outdir}/{bamlist_name}.bamlist"), col_names = F)
  cat("\nbamlist written!")
}
