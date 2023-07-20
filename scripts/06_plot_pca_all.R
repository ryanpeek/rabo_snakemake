# plot PCA

# sftp farmer
# cd /group/millermrgrp3/ryan3/

# Library -----------------------------------------------------------------

library(sf)
library(glue)
library(janitor)
library(tidyverse)
library(mapview)
library(ggthemes)
library(colorspace)
library(scico) # scico_palette_show()
library(ggthemes)

# if using IBS:
source("scripts/functions/f_read_covmat.R")

# Get covMat ---------------------------------------------------------------

fileName <- "rabo_sc_all_run1"

# no subsample
covar <- read_covmat(fileName)

# with subsample
#subsam <- "50k"
#covar <- read_covmat(fileName, subsample = subsam)

# Check for NAs and replace with zero
sum(colSums(is.na(covar))) # if anything not zero, replace w zero for now
sum(rowSums(is.na(covar)))
# which row or cols?
which(colSums(is.na(covar))==ncol(covar))
which(rowSums(is.na(covar))==nrow(covar))
# apply(covar,2,function(x) which(rowSums(is.na(covar))==nrow(covar)))

# col/row to drop
toDROP <- which(rowSums(is.na(covar))==nrow(covar))

# any row with a NA
covar[is.na(covar)] <- NA

# drop missing
covar <- remove_empty(covar, c("rows","cols"))

# any row with a 0 to just plot anyway
# covar[is.na(covar)] <- 0

# Get Metadata  -----------------------------------------------------------

# select just SC sites
sc_sites <- c("San Carpoforo Creek", "Dutra", "Burro")

# read in metadata
meta <- read_csv("samples/2022_metadata_seq_samples_joined.csv") %>% 
   filter(!is.na(y)) %>%  # rm blank
   st_as_sf(coords=c("x","y"), remove=FALSE, crs=4326) %>% 
   filter(grepl(glue_collapse(sc_sites,"|"), locality)) %>% 
   mutate(river = case_when(
      grepl("Dutra Creek", locality) ~ "Dutra_Ck",
      grepl("Burro Creek", locality) ~ "Burro_Ck",
      grepl("San Carpoforo", locality) ~ "San Carpoforo"), .before="locality") %>% 
   mutate(sommseq = glue("{plate_name}_{well_barcodefull}"), .before=plate_name) %>% 
   #remove_empty(c("cols","rows")) %>% 
   remove_constant(na.rm=TRUE, quiet = FALSE)

# Sync With Bamlist -------------------------------------------------------

source("scripts/functions/f_join_covmat_bams.R")

# no subsample
annot <- join_covmat_bams(fileName = fileName,  metadata = meta)

# drop if needed
annot <- annot[-toDROP,]

# Mapview Map -------------------------------------------------------------

annot_sf <- annot %>% st_as_sf(coords=c("x","y"), crs=4326, remove=F)
mapview(annot_sf, zcol="river")

# Basic PCA ---------------------------------------------------------------
# simple test
#e <- eigen(covar)
#plot(e$vectors[,1:2],lwd=2,ylab="PC 1",xlab="PC 2",main="Principal components",col="red",pch=21)

# Set Up PCs --------------------------------------------------------------

# get pca vals
eig <- eigen(covar, symm=TRUE)
eig$val <- eig$val/sum(eig$val)
PC <- as.data.frame(eig$vectors)
colnames(PC) <- gsub("V", "PC", colnames(PC))

# these are all local variables that can be added...ultimately up to personal pref for plot:
vars_to_add <- annot %>% select(sample_id:sex, dna_type)
PC <- cbind(PC, vars_to_add)
# make factor:
PC <- PC %>% mutate(across(c(names(vars_to_add)), .fns = factor))

# Set Up Color & Aesthetics -----------------------------------------------

# set up color ramp
#hclplot(sequential_hcl(21, h = c(260, 60), c = c(20,75,10), l = c(30, 95), power = 1))
colorN <- length(unique(PC$river)) # number of levels

# Set Up PCs and Title ----------------------------------------------------

# set up PCs to plot
pcs <- c(1,2)

# PC's:
pc1 <- pcs[1]
pc2 <- pcs[2]

# Title: (% explained)
title <- paste("PC",pc1," (",signif(eig$val[pc1], digits=3)*100,"%)"," / PC", pc2," (",signif(eig$val[pc2], digits=3)*100,"%)", sep="",collapse="")

## Make PCA ----------------------------------------------------------------

# blank
PC_filt <- PC

# PCA: site and type
(gg12a <- ggplot(data=PC_filt, 
                 aes_string(x=paste0("PC",pc1), y=paste0("PC",pc2),
                            color=quote(river),
                            #color=quote(total_aligns), 
                            shape=quote(sample_type), 
                            #shape=quote(species), 
                            text=quote(glue("ID={sample_id} ({sample_type})")))) +
   geom_point(size=4, alpha=0.8) +
   labs(
      subtitle = glue("{fileName}"))+
      #subtitle = glue("{fileName}_{subsam}"))+
   theme_bw() +
   #ggrepel::geom_text_repel(data=PC, aes(label=site_id), size=3, color="gray40") +
   ggrepel::geom_text_repel(data=PC_filt, aes(label=sample_id), size=3, color="gray40") +
   #theme(legend.position = c(0.75,0.3)) +
   scale_color_colorblind("River")+
   #scale_color_discrete_diverging(name="Site", palette="Purple-Green") + 
   #scale_color_scico_d(palette = 'romaO') + # see romaO, tofino, imola 
   #scale_color_viridis_d("Site") +
   #scale_color_viridis_c("Reads") +
   scale_shape("Sample Type") + 
   #scale_shape("Species") + 
   ggtitle(paste0(title)))

# plotly
plotly::ggplotly(gg12a)

## subsamp
#ggsave(filename = glue("figs/{fileName}_{subsam}_pca_{pc1}_{pc2}.jpg"), width = 11, height = 8, units = "in", dpi=300)

## no sub
ggsave(filename = glue("figs/{fileName}_pca_{pc1}_{pc2}.jpg"), width = 11, height = 8, units = "in", dpi=300)
# ggsave(filename = glue("figs/{fileName}_pca_{pc1}_{pc2}_filtered_20k.jpg"), width = 11, height = 8, units = "in", dpi=300)

# plotly
# library(plotly)
# ggplotly(gg12a)
