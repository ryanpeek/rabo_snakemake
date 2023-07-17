
# Make PCA ----------------------------------------------------------------

library(glue)
library(ggplot2)
library(ggthemes)
library(colorspace)
library(scico) # scico_palette_show()

covfile <- "ronca_core"
subsam <- "40k"

get_pca <- function(covfile, subsam, covar, annot, pc1, pc2){
   
   # get pca vals
   eig <- eigen(covar, symm=TRUE)
   eig$val <- eig$val/sum(eig$val)
   PC <- as.data.frame(eig$vectors)
   colnames(PC) <- gsub("V", "PC", colnames(PC))
   
   # add metadata vals
   PC$ID <- factor(annot$sample_id)
   PC$Site <- factor(annot$site)
   PC$spp <- factor(annot$species)
   PC$sex <- factor(annot$sex)
   PC$sample_type <- factor(annot$sample_type)
   PC$site_type <- factor(annot$site_type)
   
   # PC's:
   pc1 <- pc1
   pc2 <- pc2
   
   # Title: (% explained)
   title <- paste("PC",pc1," (",signif(eig$val[pc1], digits=3)*100,"%)"," / PC", pc2," (",signif(eig$val[pc2], digits=3)*100,"%)", sep="",collapse="")
   
   # PCA: site and type
   (gg12a <- ggplot(data=PC, 
                    aes_string(x=paste0("PC",pc1), y=paste0("PC",pc2),
                               color=quote(Site), shape=quote(spp), text=quote(paste0("ID=",ID)))) +
       geom_point(size=4, alpha=0.8) +
       labs(subtitle = glue("{covfile}_{subsam}"))+
       theme_bw() +
       ggrepel::geom_text_repel(data=PC, aes(label=ID), size=3, color="gray40") +
       #theme(legend.position = c(0.75,0.3)) +
       #scale_color_colorblind("Site Type")+
       #scale_color_discrete_diverging(name="Site", palette="Purple-Green") + 
       scale_color_scico_d(palette = 'romaO') + # see romaO, tofino, imola 
       #scale_color_viridis_d("Site") +
       scale_shape("Species") + 
       ggtitle(paste0(title)))
   
}   

pc1 <- 1
pc2 <- 2
get_pca(covfile, subsam, covar, annot, 1, 2)

   
ggsave(filename = glue("figs/{covfile}_{subsam}_pca_{pc1}_{pc2}.jpg"), width = 11, height = 8, units = "in", dpi=300)
