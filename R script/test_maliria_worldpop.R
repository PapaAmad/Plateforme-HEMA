# Charger les packages
library(sf)
library(terra)
library(dplyr)
library(leaflet)
library(exactextractr)

# Paramétrage de base -----------------------------------------------

# Charger les données administratives
adm0_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp")
adm1_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp")
adm2_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp")
adm3_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp")

# Charger les rasters de malaria
fichiers_raster_SN <- list.files("data/Senegal/Rasters/Malaria", pattern = "\\.tiff$", full.names = TRUE)
# Extraire uniquement la première bande de chaque raster
r_list_SN <- lapply(fichiers_raster_SN, function(x) terra::rast(x)[[1]])

# Créer un SpatRaster avec une seule couche par année
rasters_SN <- rast(r_list_SN)

# Charger le raster de population
WorldPop_SN <- terra::rast("data/Senegal/Rasters/WorldPop/worldpop_SN.tif")

# Agréger le raster de population à 5 km
WorldPop_SN_aggregated <- terra::aggregate(WorldPop_SN, fact = 50, fun = sum, na.rm = TRUE, 
                                           filename = "data/Senegal/Rasters/WorldPop/worldpop_SN_aggregated.tif", 
                                           overwrite = TRUE)

# Calculer le nombre d'enfants (0-12 ans)
WorldPop_SN_children <- WorldPop_SN_aggregated * 0.001

# Sélection des rasters de malaria
malaria_raster_2000 <- rasters_SN[[1]]
malaria_raster_2001 <- rasters_SN[[2]]
malaria_raster_2002 <- rasters_SN[[3]]
malaria_raster_2003 <- rasters_SN[[4]]
malaria_raster_2004 <- rasters_SN[[5]]
malaria_raster_2005 <- rasters_SN[[6]]
malaria_raster_2006 <- rasters_SN[[7]]
malaria_raster_2007 <- rasters_SN[[8]]
malaria_raster_2008 <- rasters_SN[[9]]
malaria_raster_2009 <- rasters_SN[[10]]
malaria_raster_2010 <- rasters_SN[[11]]
malaria_raster_2011 <- rasters_SN[[12]]
malaria_raster_2012 <- rasters_SN[[13]]
malaria_raster_2013 <- rasters_SN[[14]]
malaria_raster_2014 <- rasters_SN[[15]]
malaria_raster_2015 <- rasters_SN[[16]]
malaria_raster_2016 <- rasters_SN[[17]]
malaria_raster_2017 <- rasters_SN[[18]]
malaria_raster_2018 <- rasters_SN[[19]]
malaria_raster_2019 <- rasters_SN[[20]]
malaria_raster_2020 <- rasters_SN[[21]]
malaria_raster_2021 <- rasters_SN[[22]]
malaria_raster_2022 <- rasters_SN[[23]]

#-----------------------------------------------------------------------
#------------------Initialisation de la fonction pour le nombre d'enfant
#-----------------------------------------------------------------------

calc_nb_enf_per_admin <- function(admin, raster){
  
  # Reprojeter le raster de malaria pour qu'il corresponde au raster de population
  raster_proj <- terra::project(raster, WorldPop_SN_children, method = "near")
  
  # Aligner l'extent et la résolution
  raster_aligned <- terra::resample(raster_proj, WorldPop_SN_children, method = "near")
  
  # Calculer le nombre d'enfants atteints de malaria
  children_malaria_raster <- raster_aligned * WorldPop_SN_children
  # Transformer le niveau administratif au CRS du raster
  adm_level <- st_transform(admin, crs(children_malaria_raster))
  
  # Extraction des valeurs raster par polygone
  children_malaria_values <- exact_extract(children_malaria_raster, adm_level, 'sum')
  children_total_values <- exact_extract(WorldPop_SN_children, adm_level, 'sum')
  
  # Ajouter les résultats au shapefile
  adm_level <- adm_level %>%
    mutate(
      children_malaria = children_malaria_values,
      children_total = children_total_values,
      taux_malaria = (children_malaria / children_total) * 100
    )
  
  # Visualisation avec leaflet
  pal_count <- colorNumeric(palette = "Reds", domain = adm_level$children_malaria, na.color = "transparent")
  
  # Carte pour le nombre d'enfants malades
  map_count <- leaflet(adm_level) %>%
    addTiles() %>%
    addPolygons(fillColor = ~pal_count(children_malaria),
                weight = 1,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(
                  weight = 2,
                  color = "#666",
                  dashArray = "",
                  fillOpacity = 0.7,
                  bringToFront = TRUE),
                label = ~paste0("Division: ", adm_level[[1]],
                                " Enfants malades: ", round(children_malaria))) %>%
    addLegend(pal = pal_count, values = ~children_malaria, opacity = 0.7, title = "Nombre d'enfants malades",
              position = "bottomright")
  
  # Retourner la carte
  return(map_count)
}

#-----------------------------------------------------------------------
#------------------Initialisation de la fonction pour le taux d'enfant
#-----------------------------------------------------------------------

calc_taux_enf_per_admin <- function(admin, raster){
    
    # Reprojeter le raster de malaria pour qu'il corresponde au raster de population
    raster_proj <- terra::project(raster, WorldPop_SN_children, method = "near")
    
    # Aligner l'extent et la résolution
    raster_aligned <- terra::resample(raster_proj, WorldPop_SN_children, method = "near")
    
    # Calculer le nombre d'enfants atteints de malaria
    children_malaria_raster <- raster_aligned * WorldPop_SN_children
    # Transformer le niveau administratif au CRS du raster
    adm_level <- st_transform(admin, crs(children_malaria_raster))
    
    # Extraction des valeurs raster par polygone
    children_malaria_values <- exact_extract(children_malaria_raster, adm_level, 'sum')
    children_total_values <- exact_extract(WorldPop_SN_children, adm_level, 'sum')
    
    # Ajouter les résultats au shapefile
    adm_level <- adm_level %>%
      mutate(
        children_malaria = children_malaria_values,
        children_total = children_total_values,
        taux_malaria = (children_malaria / children_total) * 100
      )
    
    # Visualisation avec leaflet
    pal_rate <- colorNumeric(palette = "Blues", domain = adm_level$taux_malaria, na.color = "transparent")
    
    # Carte pour le taux de malaria
    map_rate <- leaflet(adm_level) %>%
      addTiles() %>%
      addPolygons(fillColor = ~pal_rate(taux_malaria),
                  weight = 1,
                  opacity = 1,
                  color = "white",
                  dashArray = "3",
                  fillOpacity = 0.7,
                  highlight = highlightOptions(
                    weight = 2,
                    color = "#666",
                    dashArray = "",
                    fillOpacity = 0.7,
                    bringToFront = TRUE),
                  label = ~paste0("Division: ", adm_level[[1]],
                                  " Taux de malaria: ", round(taux_malaria, 2), "%")) %>%
      addLegend(pal = pal_rate, values = ~taux_malaria, opacity = 0.7, title = "Taux de malaria (%)",
                position = "bottomright")
    
    # Afficher la carte 
    return(map_rate)
}

# Test de la fonction pour calculer le nombre d'enfant malade pour l'année 2021 et par région
map1 <- calc_nb_enf_per_admin(admin = adm2_SN, raster = malaria_raster_2021)
map1

map2 <- calc_taux_enf_per_admin(admin = adm2_SN, raster = malaria_raster_2021)
map2


library(terra)

# Charger le raster de population original
WorldPop_BFA <- rast("data/Burkina/Rasters/WorldPop/worldpop_BFA.tif")

# Vérifier les détails du raster
print(WorldPop_BFA)
plot(WorldPop_BFA)

file.remove("data/Burkina/Rasters/WorldPop/worldpop_BFA_aggregated.tif")

