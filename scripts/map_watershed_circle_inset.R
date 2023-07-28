# get and plot watershed quickly

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(sf)
library(glue)
library(tigris)
library(nhdplusTools)
#library(arrow)
#library(geoarrow) # remotes::install_github("paleolimbot/geoarrow")
library(rmapshaper)
library(mapview)
mapviewOptions(fgb=FALSE)

# for fancy fonts
library(showtext)
showtext_opts(dpi=300)
#font_paths()

fnt_headers <- "Merriweather"
fnt_text <- "Source Sans Pro"

#fnt_headers <- "Lora"
#fnt_text <- "Libre Franklin"

# add straight from google
font_add_google(fnt_headers)
font_add_google(fnt_text)

# call this before plots else showtext_begin and _end
showtext_auto()

# Get State/Counties ------------------------------------------------------

ca <- tigris::states(progress_bar=FALSE) %>% filter(NAME=="California")
ca_cnty <- counties("CA", cb = TRUE, progress_bar = FALSE)
ca_cnty <- st_cast(ca_cnty, "MULTIPOLYGON")

ca <- st_transform(ca, 3310)
ca_cnty <- st_transform(ca_cnty, 3310)


# Get Hillshade -----------------------------------------------------------

library(terra)
hill <- terra::rast("/Users/rapeek/Downloads/kx-california-hillshade-30m-JPEG/ca_30m_hillshade.jpg")
plot(hill$ca_30m_hillshade)
crs(hill)

# Get HUC Watersheds ------------------------------------------------------

# can specify any given option for huc8, huc10, etc
huc8 <- nhdplusTools::get_huc(ca, type = "huc08") # this takes a minute or two
huc8 <- st_cast(huc8, "MULTIPOLYGON") # fix geometry
h8 <- st_transform(huc8, 3310)

# pull out a single watershed
# mapview::mapview(h8) # can view with mapview 18060006: Central Coastal 18060005: Salinas
watershed <- c("Salinas", "Central Coastal")
h8_sel <- h8 %>% filter(name %in% watershed)
plot(h8_sel$geometry)
h8_sel_mrg <- rmapshaper::ms_dissolve(h8_sel)
plot(h8_sel_mrg$geometry)


# CropHillshade -----------------------------------------------------------

hill_crop <- crop(hill, h8_sel_mrg)
hill_crop <- mask(hill_crop, terra::vect(ca))

plot(hill_crop, axes=FALSE)
plot(ca_cnty$geometry, add=TRUE)
plot(h8_sel_mrg$geometry, border="blue", add=TRUE)

ca_cnty_sel <- ca_cnty[h8_sel_mrg,]

# Get Water Data ----------------------------------------------------------

ca_water <- tigris::area_water("CA", ca_cnty_sel$COUNTYFP)
ca_water <- st_transform(ca_water, st_crs(h8_sel_mrg))

# now crop by watershed
st_crs(ca_water)==st_crs(h8_sel_mrg)
ca_water_sel <- ca_water[h8_sel_mrg,] # select via spatial join
ca_water_sel2 <- st_intersection(ca_water_sel, h8_sel_mrg)

# Now Get Data ------------------------------------------------------------

# pull mainstem rivers and lakes for watershed
shed_wb <- nhdplusTools::get_waterbodies(h8_sel_mrg) # water bodies

# get flowlines
shed_rivs <- get_nhdplus(h8_sel_mrg)

# Base Map ----------------------------------------------------------------

# quick map
plot(hill_crop, axes=FALSE)
plot(h8_sel$geometry, border = "gray50", lty=2, add=TRUE)
plot(shed_rivs$geometry, col="steelblue4", lwd=shed_rivs$streamorde/4, add=TRUE)
plot(ca_water_sel2$geometry, border="cyan4", col="cyan4", add=TRUE)
plot(shed_wb$geometry, border="steelblue2", col=alpha("steelblue2",0.9), add=TRUE)
plot(h8_sel_mrg$geometry, border="gray40", lwd=3, add=TRUE)
title(main = glue("{watershed} Watershed"), family=fnt_headers)


# ggplot Map --------------------------------------------------------------

# filter out negative numbers
shed_rivs2 <- filter(shed_rivs, streamorde>0)

library(tidyterra)

ggplot() +
   geom_spatraster(data=hill_crop, show.legend = FALSE, interpolate = TRUE, maxcell = 2e6) +
   scale_fill_whitebox_c(palette = "arid", alpha = 0.5)+
   geom_sf(data=h8_sel, fill=NA, color="gray50", linewidth=0.3, lty=2) +
   geom_sf(data=shed_rivs2, color="steelblue4", 
           linewidth=shed_rivs2$streamorde/6, show.legend = FALSE)+
   geom_sf(data=ca_water_sel2, fill="cyan4", color="cyan4")+
   geom_sf(data=shed_wb, fill=alpha("steelblue2", 0.9), color="steelblue2")+
   geom_sf(data=h8_sel_mrg, fill=NA, color="gray40", linewidth=1.2)+
   theme_void(base_family = fnt_text) +
   labs(title = glue("{watershed} Watershed")) +
   theme(plot.title = element_text(face="bold", vjust=-0.5, hjust=0.3, size=14))


# Add Circular Inset ------------------------------------------------------

# use a lat lon
pt <- sf::st_as_sf(data.frame(x = -121.27190, y = 35.85476),
             coords = c("x", "y"), crs = 4326)

# make a circle buffer
center_proj <- pt
dist <-  10000 # the buffer
circle_buff <- center_proj %>%
  st_buffer(dist = dist) %>%
  st_transform(crs = 3310)
plot(circle_buff$geometry)

# crop the data
shed_rivs_crop <- shed_rivs2 %>%
  st_intersection(circle_buff)
ca_water_crop <- ca_water_sel2 %>%
  st_intersection(circle_buff)
h8_sel_crop <- h8_sel %>% st_intersection(circle_buff)
hill_cir_crop <- crop(hill_crop, circle_buff)
hill_cir_crop <- mask(hill_cir_crop, circle_buff)

# Main Map before Circle ------------------------

(main_map <-
   ggplot() +
    geom_spatraster(data=hill_crop, show.legend = FALSE, maxcell = 2e6, interpolate = TRUE) +
   scale_fill_whitebox_c(palette = "arid", alpha = 0.5)+
   geom_sf(data=h8_sel, lwd = 0, fill=NA)+ #color = alpha("white",0.1)) +
   labs(
     title = glue("{watershed} & {watershed[2]} Watersheds"),
     caption = "Data: NHD & {tigris} | Graphic by R. Peek") +
   geom_sf(data=h8_sel, fill=NA, color="brown4", linewidth=0.2, lty=1) +
   geom_sf(data=shed_rivs2, color="steelblue4", linewidth=shed_rivs2$streamorde/6, show.legend = FALSE, alpha=0.6) +
   #geom_sf(data=ca_water_sel2, fill="cyan4", color="cyan4")+
   geom_sf(data=shed_wb, fill=alpha("steelblue2", 0.9), color="steelblue2")+
   # add the outline
   geom_sf(data=circle_buff, fill=NA, col="black", linewidth=.5)+
   coord_sf(expand = FALSE) +
   theme_void() +
   theme(
     # defines the edge of the legend.position coordinates
     #legend.justification = c(0.2, 1),
     legend.position = c(0.2, .25),
     title = element_text(family = fnt_headers),
     legend.title = element_text(family = fnt_headers, size = 10, face = "bold"),
     legend.text = element_text(family = fnt_text, size = 10)
   ))


# Make Circular Plot ------------------------------------------------------

(circ_plot <-
   ggplot() +
    geom_sf(data=circle_buff, fill="white", col="black", linewidth=1)+
    geom_spatraster(data=hill_cir_crop, show.legend = FALSE, interpolate = TRUE, maxcell = 2e6) +
    #scale_fill_hypso_c(palette = 'dem_print', alpha=0.5)+
    scale_fill_hypso_c(palette = 'colombia_hypso', alpha=0.7)+
    geom_sf(data=shed_rivs_crop, color="steelblue4", linewidth=shed_rivs_crop$streamorde/6, show.legend = FALSE) +
    geom_sf(data=ca_water_crop, fill="cyan4", color="cyan4")+
    geom_sf(data=h8_sel_crop, fill=NA, color="brown4", linewidth=0.5, lty=1)+
    geom_sf(data=circle_buff, fill=NA, col="black", linewidth=1.5)+
    coord_sf(expand = 0.01) +
    theme_void()
)


# Combine w patchwork -----------------------------------------------------------------

library(patchwork)

# draw

(p1 <- main_map + inset_element(circ_plot,
                                left =  0.45, bottom = 0.45, 1, 1,
                                align_to = 'plot',
                                on_top = TRUE))



# save pdf
ggsave(plot = p1,
       filename = glue("figs/map_{first(watershed)}_watershed_circle_inset.pdf"),
       device = cairo_pdf, bg="white", scale = 1,
       width = 8.5, height = 11)

# png
ggsave(plot = p1,
       filename = glue("figs/map_{first(watershed)}_watershed_circle_inset.png"),
       bg="white", dpi=300, device = "png",
       width = 8.5, height = 11, units = "in")


