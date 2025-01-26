library(shiny)
library(leaflet)
library(raster)
library(sf)

# Définir les chemins des fichiers
raster_paths <- list(
  "Sénégal" = list(
    "NDVI" = "Senegal/indices/NDVI_SN.tif",
    "MNDWI" = "Senegal/indices/MNDWI_SN.tif",
    "BSI_1" = "Senegal/indices/Bare_Soil_Index_SN.tif",
    "NDBI" = "Senegal/indices/NDBI_SN.tif",
    "EVI" = "Senegal/indices/EVI_SN.tif"
  ),
  "Burkina Faso" = list(
    "NDVI" = "Burkina/indices/NDVI_BFA.tif",
    "MNDWI" = "Burkina/indices/MNDWI_BFA.tif",
    "BSI_1" = "Burkina/indices/Bare_Soil_Index_BFA.tif",
    "NDBI" = "Burkina/indices/NDBI_BFA.tif",
    "EVI" = "Burkina/indices/EVI_BFA.tif"
  )
)

shapefile_paths <- list(
  "Sénégal" = "Senegal/shapefiles/sen_admbnda_adm0_anat_20240520.shp",
  "Burkina Faso" = "Burkina/shapefiles/geoBoundaries-BFA-ADM0.shp"
)

# Définir les palettes pour les indices
indicator_palettes <- list(
  "NDVI" = "YlGn",      # Vert (végétation)
  "MNDWI" = "Blues",    # Bleu (eau)
  "BSI_1" = "Oranges",  # Orange (sols nus)
  "NDBI" = "Purples",   # Violet (zones construites)
  "EVI" = "Greens"      # Vert intense (végétation améliorée)
)

# Interface utilisateur
ui <- fluidPage(
  titlePanel("Visualisation des indices par pays"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Choisir un pays :", choices = names(raster_paths)),
      selectInput("indicator", "Choisir un indicateur :", choices = names(indicator_palettes))
    ),
    mainPanel(
      leafletOutput("map"),
      textOutput("meanValue")
    )
  )
)

# Serveur
server <- function(input, output, session) {
  # Réactif pour charger le raster sélectionné
  current_raster <- reactive({
    req(input$country, input$indicator)
    raster_path <- raster_paths[[input$country]][[input$indicator]]
    if (file.exists(raster_path)) {
      raster(raster_path)
    } else {
      NULL
    }
  })
  
  # Réactif pour charger le shapefile sélectionné
  current_shapefile <- reactive({
    req(input$country)
    shapefile_path <- shapefile_paths[[input$country]]
    if (file.exists(shapefile_path)) {
      st_read(shapefile_path, quiet = TRUE)
    } else {
      NULL
    }
  })
  
  # Calculer la moyenne de l'indice
  mean_value <- reactive({
    req(current_raster())
    round(cellStats(current_raster(), stat = "mean", na.rm = TRUE), 2)
  })
  
  # Afficher la carte Leaflet
  output$map <- renderLeaflet({
    req(current_raster(), current_shapefile(), input$indicator)
    
    raster_data <- current_raster()
    shapefile_data <- current_shapefile()
    palette <- colorNumeric(
      palette = indicator_palettes[[input$indicator]],
      domain = values(raster_data),
      na.color = "transparent"
    )
    
    leaflet() %>%
      addTiles() %>%
      addRasterImage(
        raster_data,
        colors = palette,
        opacity = 0.8,
        group = input$indicator
      ) %>%
      addPolygons(
        data = shapefile_data,
        color = "black",
        weight = 1,
        fill = FALSE
      ) %>%
      addLegend(
        pal = palette,
        values = values(raster_data),
        title = paste("Indice :", input$indicator),
        position = "bottomright"
      )
  })
  
  # Afficher la valeur moyenne de l'indicateur
  output$meanValue <- renderText({
    req(mean_value())
    paste("Valeur moyenne de l'indicateur sélectionné :", mean_value())
  })
}

# Lancer l'application Shiny
shinyApp(ui, server)
