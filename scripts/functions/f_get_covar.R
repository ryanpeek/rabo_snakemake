# get Covar and merge

# libraries
library(glue)
library(readr)
library(dplyr)
library(sf)
library(stringr)

# function
get_covMat <- function(covfile, subsample, mapview=FALSE){
   
      # if using IBS, assumes files live in output/pca/
   covar <- read.table(glue("output/pca/{covfile}_{subsam}.covMat")) 
   
   # Check for NAs
   stopifnot("matrix has zeros"= sum(colSums(is.na(covar)))==0 || sum(rowSums(is.na(covar)))==0)
   # get metadata
   meta <- read_rds(glue("output/ronca_metadata_{subsam}_sf.rds"))
   # get bams
   bams <- read_tsv(glue("output/bamlists/{covfile}_{subsam}.bamlist"), col_names = F)
   bams$sommseq <- sub(pattern = "(.*?)\\..*$", replacement = "\\1", basename(bams$X1)) 
   bams$SOMM <- substr(bams$sommseq, 1,7)  # add a somm col
   bams$seqid <- stringr::str_replace_all(bams$sommseq, glue("{bams$SOMM}_"), "")
   bams <- bams %>% rename(seqfull = X1)

   # now join with metadata by seq_id
   annot <- left_join(bams, meta, by=c("sommseq")) # join
   
   # MAPVIEW
   if(mapview==TRUE){
      library(mapview)
      annot_sf <- annot %>% st_as_sf(coords=c("lon","lat"), crs=4326, remove=F)
      m1 <- mapview(annot_sf, zcol="site")
      print("covar read in successfully & mapview map")
      return(list(annot=annot, m1=m1))
   } else {
      print("covar read in successfully!")
   return(annot)
   }
}

# test function
covfile <- "ronca_hist"
subsam <- "50k"

dat <- get_covMat(covfile, subsam, mapview=TRUE)
annot <- dat$annot
(m1 <- dat$m1)

