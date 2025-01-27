# Charger les bibliothèques nécessaires
library(shiny)
library(sf)
library(dplyr)
library(leaflet)
library(raster)
library(terra)
library(ggplot2)
library(viridis)
library(leaflet.extras)
library(readr)

# Charger les données depuis le fichier CSV
data_path <- "data/Points_data.csv"
data <- read_delim(data_path, delim = ";", escape_double = FALSE, trim_ws = TRUE)

# Filtrer pour le Sénégal et le Burkina Faso
data_filtered <- data %>% filter(country %in% c("Senegal", "Burkina Faso"))

# Fonction pour charger les shapefiles en fonction du pays sélectionné et du niveau administratif
load_shapefiles <- function(country) {
  if (country == "Senegal") {
    list(
      adm0 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp"),
      adm1 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp"),
      adm2 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp"),
      adm3 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp")
    )
  } else {
    list(
      adm0 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM0.shp"),
      adm1 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM1.shp"),
      adm2 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM2.shp"),
      adm3 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM3.shp")
    )
  }
}


source("ui_envent.R")
source("server_envet.R")

# -----------------------------
# Lancer l'application
shinyApp(ui = ui, server = server)

