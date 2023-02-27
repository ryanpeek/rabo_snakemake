# function to filter for bamlists



# function to filter data
bam_filt <- function(data, 
                     sample_types=c("tissue"), # defaults to tissue
                     species_sel=c("RAON"), # defaults to just RAON
                     site_types, # give a list c("A","B","C")
                     site_ids){ # give a list as well 
  data %>% 
    filter(species %in% {{species_sel}}, 
           sample_type %in% {{sample_types}},
           site_type %in% {{site_types}}, 
           site_id %in% {{site_ids}})
}
