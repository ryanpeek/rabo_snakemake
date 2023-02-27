# Join covMat with bams
library(readr)
library(stringr)
library(dplyr)

join_covmat_bams <- function(fileName, metadata, subsample=NULL){
  if(!is.null(subsample)){
    bams <- read_tsv(glue("outputs/bamlists/{fileName}_{subsample}.bamlist"),
                     col_names = F)
    bams$sommseq <- sub(pattern = "(.*?)\\..*$", 
                        replacement = "\\1", basename(bams$X1))
    bams <- bams %>% rename(seqfull = X1)
    annot <- left_join(bams, meta, by=c("sommseq")) # join
    return(annot)
  } else({
    bams <- read_tsv(glue("outputs/bamlists/{fileName}.bamlist"), col_names = F)
    bams$sommseq <- sub(pattern = "(.*?)\\..*$", 
                        replacement = "\\1", basename(bams$X1))
    bams <- bams %>% rename(seqfull = X1)
    annot <- left_join(bams, metadata, by=c("sommseq")) # join
    return(annot)
  })
}
