# get depth assessment by sample


# Libraries ---------------------------------------------------------------

library(glue)
library(tidyverse)
library(ggthemes)
library(fs)
library(janitor)
library(sf)

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


# Join with metadata ------------------------------------------------------

# southCoast bamlist:
fileName <- "rabo_sc_all_run1"

bams <- read_tsv(glue("outputs/bamlists/{fileName}.bamlist"), col_names = F)
bams$sommseq <- sub(pattern = "(.*?)\\..*$", 
                    replacement = "\\1", basename(bams$X1))
bams <- bams %>% rename(seqfull = X1)

# join with depth data
df_sc <- left_join(bams, df, by=c("sommseq"="filename")) # join

# join with metadata
sc_sites <- c("San Carpoforo Creek", "Dutra", "Burro")
meta <- read_csv("samples/2022_metadata_seq_samples_joined.csv") %>% 
  filter(!is.na(y)) %>%  # rm blank
  st_as_sf(coords=c("x","y"), remove=FALSE, crs=4326) %>% 
  filter(grepl(glue_collapse(sc_sites,"|"), locality)) %>% 
  mutate(river = case_when(
    grepl("Dutra Creek", locality) ~ "Dutra_Ck",
    grepl("Burro Creek", locality) ~ "Burro_Ck",
    grepl("San Carpoforo", locality) ~ "San Carpoforo"), .before="locality") %>% 
  mutate(sommseq = glue("{plate_name}_{well_barcodefull}"), .before=plate_name) %>% 
  remove_constant(na.rm=TRUE, quiet = FALSE)

# join with depth data
df_sc_meta <- left_join(df_sc, meta, by=c("sommseq")) %>% 
  select(-plate.y) %>% 
  rename(plate=plate.x)


# Plot --------------------------------------------------------------------

# barplot by depth and plate
ggplot()+
  geom_hline(yintercept = mean(df_sc_meta$avg_depth), color="gray40", linetype=2)+
  geom_boxplot(data=df_sc_meta, aes(x=plate, y=avg_depth, fill=plate), alpha=0.5) +
  geom_jitter(data=df_sc_meta, aes(x=plate, y=avg_depth, fill=plate), pch=21, alpha=0.5) +
  scale_fill_viridis_d() +
  scale_y_continuous(breaks=c(seq(0,40,5)))+
  theme_classic(base_family = "Roboto Condensed")+
  theme(axis.text.x = element_blank()) +
  labs(x="", y="Avg Depth {samtools depth}")
  

# barplot by sample type
ggplot()+
  geom_hline(yintercept = mean(df_sc_meta$avg_depth), color="gray40", linetype=2)+
  geom_boxplot(data=df_sc_meta, aes(x=sample_type, y=avg_depth, fill=sample_type), alpha=0.5) +
  geom_jitter(data=df_sc_meta, aes(x=sample_type, y=avg_depth, fill=sample_type), pch=21, alpha=0.5) +
  scale_fill_viridis_d() +
  scale_y_continuous(breaks=c(seq(0,40,5)))+
  theme_classic(base_family = "Roboto Condensed")+
  theme(axis.text.x = element_blank()) +
  labs(x="", y="Avg Depth {samtools depth}")
  
