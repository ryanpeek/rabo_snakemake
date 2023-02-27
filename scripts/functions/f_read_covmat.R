# function to read in covMat files
library(glue)

read_covmat <- function(fileName, subsample=NULL){
  
  if(!is.null(subsample)){
    covar <- read.table(glue("outputs/pca/{fileName}_{subsample}.covMat"))
    cat("subsample covMat read in!")
    return(covar)
  } else({
    print("no subsample avail")
    covar <- read.table(glue("outputs/pca/{fileName}.covMat"))
    cat("covMat read in!")
    return(covar)
  })
}
