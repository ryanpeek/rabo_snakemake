# get depth assessment by sample


# Libraries ---------------------------------------------------------------

library(glue)
library(tidyverse)
library(ggthemes)
library(fs)

# Get Data ----------------------------------------------------------------

# either scp/sftp in and get file, or pull direct from github if file size is low
# sftp farmer/
# cd transfer
# get *
# done

df <- data.table::fread("outputs/stats/all_bams_depth.txt") %>% 
  rename(file=1, avg_depth=2)

# fix file name
df <- df %>% 
  mutate(filename=gsub(".sort.flt.bam", "", path_file(file)),
         plate_samp = gsub("SOMM570_", "", filename)) %>% 
  separate(plate_samp, sep = "_", into=c("plate","sample"), remove=TRUE)


# Plot --------------------------------------------------------------------

ggplot()+
  geom_hline(yintercept = mean(df$avg_depth), color="gray40", linetype=2)+
  geom_point(data=df, aes(filename, avg_depth, fill=plate), pch=21, alpha=0.5) +
  scale_fill_viridis_d() +
  scale_y_continuous(breaks=c(seq(0,40,5)))+
  theme_classic(base_family = "Roboto Condensed")+
  theme(axis.text.x = element_blank()) +
  labs(x="", y="Avg Depth {samtools depth}")
  
  
