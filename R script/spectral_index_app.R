library(shiny)
library(leaflet)
library(raster)
library(sf)
library(dplyr)
library(viridis)
library(exactextractr)
library(ggplot2)

# Définir les chemins des fichiers
raster_paths <- list(
  "Sénégal" = list(
    "NDVI" = "data/Senegal/Rasters/Spectral_index/NDVI_SN.tif",
    "MNDWI" = "data/Senegal/Rasters/Spectral_index/MNDWI_SN.tif",
    "BSI_1" = "data/Senegal/Rasters/Spectral_index/Bare_Soil_Index_SN.tif",
    "NDBI" = "data/Senegal/Rasters/Spectral_index/NDBI_SN.tif",
    "EVI" = "data/Senegal/Rasters/Spectral_index/EVI_SN.tif"
  ),
  "Burkina Faso" = list(
    "NDVI" = "data/Burkina/Rasters/Spectral_index/NDVI_BFA.tif",
    "MNDWI" = "data/Burkina/Rasters/Spectral_index/MNDWI_BFA.tif",
    "BSI_1" = "data/Burkina/Rasters/Spectral_index/Bare_Soil_Index_BFA.tif",
    "NDBI" = "data/Burkina/Rasters/Spectral_index/NDBI_BFA.tif",
    "EVI" = "data/Burkina/Rasters/Spectral_index/EVI_BFA.tif"
  )
)

shapefile_paths <- list(
  "Sénégal" = list(
    "0" = "data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp",
    "1" = "data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp",
    "2" = "data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp",
    "3" = "data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp"
  ),
  "Burkina Faso" = list(
    "0" = "data/Burkina/Shapefiles/geoBoundaries-BFA-ADM0.shp",
    "1" = "data/Burkina/Shapefiles/geoBoundaries-BFA-ADM1.shp",
    "2" = "data/Burkina/Shapefiles/geoBoundaries-BFA-ADM2.shp",
    "3" = "data/Burkina/Shapefiles/geoBoundaries-BFA-ADM3.shp"
  )
)

# Définir les palettes pour les indices
indicator_palettes <- list(
  "NDVI" = "YlGn",      # Vert (végétation)
  "MNDWI" = "Blues",    # Bleu (eau)
  "BSI_1" = "Oranges",  # Orange (sols nus)
  "NDBI" = "Purples",   # Violet (zones construites)
  "EVI" = "Greens"      # Vert intense (végétation améliorée)
)

# Définir le mapping des codes pays aux noms complets
pays_mapping <- list(
  "SEN" = "Sénégal",
  "BFA" = "Burkina Faso"
)

# Interface utilisateur
ui <- fluidPage(
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("view_type", "Type de visualisation :", 
                   choices = c("Raster", "Agrégation par Niveau Administratif"),
                   selected = "Raster"),
      
      # Supprimer les sélecteurs de pays et d'indicateur
      # Afficher les valeurs sélectionnées via l'URL
      uiOutput("selected_params"),
      
      # Afficher le sélecteur de niveau administratif uniquement si Agrégation est choisi
      conditionalPanel(
        condition = "input.view_type == 'Agrégation par Niveau Administratif'",
        selectInput("admin_level", "Niveau administratif :", choices = c("0", "1", "2", "3"), selected = "0")
      )
    ),
    
    mainPanel(
      fluidRow(
        column(8,
               leafletOutput("map", height = 600)
        ),
        column(4,
               # Afficher la valeur moyenne seulement en mode Raster
               conditionalPanel(
                 condition = "input.view_type == 'Raster'",
                 wellPanel(
                   h4("Valeur Moyenne Globale"),
                   textOutput("meanValue")
                 )
               ),
               # Afficher les statistiques en mode Agrégation avec défilement
               conditionalPanel(
                 condition = "input.view_type == 'Agrégation par Niveau Administratif'",
                 wellPanel(
                   h4("Statistiques par Zone Administratif"),
                   # Encapsuler le tableau dans un div avec défilement
                   div(
                     style = "max-height: 400px; overflow-y: auto;",
                     tableOutput("adminStats")
                   )
                 )
               )
        )
      )
    )
  )
)

# Serveur
server <- function(input, output, session) {
  
  # Pré-charger les rasters et shapefiles
  raster_data <- raster_paths
  for (country in names(raster_data)) {
    for (stat in names(raster_data[[country]])) {
      path <- raster_data[[country]][[stat]]
      if (file.exists(path)) {
        raster_data[[country]][[stat]] <- raster(path)
      } else {
        raster_data[[country]][[stat]] <- NULL
      }
    }
  }
  
  shapefile_data <- shapefile_paths
  for (country in names(shapefile_data)) {
    for (level in names(shapefile_data[[country]])) {
      path <- shapefile_data[[country]][[level]]
      if (file.exists(path)) {
        shapefile_data[[country]][[level]] <- st_read(path, quiet = TRUE)
      } else {
        shapefile_data[[country]][[level]] <- NULL
      }
    }
  }
  
  # Fonction pour extraire les paramètres de l'URL
  query <- reactive({
    parseQueryString(session$clientData$url_search)
  })
  
  # Sélection du pays
  selected_pays_code <- reactive({
    pays_code <- query()$pays
    if (is.null(pays_code) || length(pays_code) != 1 || !(toupper(pays_code) %in% names(pays_mapping))) {
      "SEN"
    } else {
      toupper(pays_code)
    }
  })
  
  selected_pays <- reactive({
    pays_code <- selected_pays_code()
    pays_mapping[[pays_code]]
  })
  
  # Sélection de la statistique
  selected_stat <- reactive({
    stat <- query()$stat
    if (is.null(stat) || length(stat) != 1 || !(stat %in% names(indicator_palettes))) {
      "NDVI"
    } else {
      stat
    }
  })
  
  # Raster courant
  current_raster <- reactive({
    req(selected_pays(), selected_stat())
    raster_obj <- raster_data[[selected_pays()]][[selected_stat()]]
    if (!is.null(raster_obj)) {
      raster_obj
    } else {
      NULL
    }
  })
  
  # Shapefile courant
  current_shapefile <- reactive({
    req(selected_pays(), input$admin_level)
    shapefile_obj <- shapefile_data[[selected_pays()]][[as.character(input$admin_level)]]
    if (!is.null(shapefile_obj)) {
      shapefile_obj
    } else {
      NULL
    }
  })
  
  # Nom de la zone
  zone_name_column <- reactive({
    shapefile <- current_shapefile()
    if (is.null(shapefile)) return(NULL)
    char_cols <- names(shapefile)[sapply(shapefile, function(col) is.character(col) || is.factor(col))]
    if (length(char_cols) == 0) {
      return(NULL)
    }
    char_cols[1]
  })
  
  # Données agrégées
  aggregated_data <- reactive({
    req(current_raster(), current_shapefile(), zone_name_column())
    extracted_values <- exact_extract(current_raster(), current_shapefile(), 'mean')
    shapefile_df <- current_shapefile()
    shapefile_df$mean_value <- extracted_values
    shapefile_df
  })
  
  # Moyenne globale
  mean_value <- reactive({
    req(current_raster())
    round(cellStats(current_raster(), stat = "mean", na.rm = TRUE), 2)
  })
  
  # Carte Leaflet
  output$map <- renderLeaflet({
    if (input$view_type == "Raster") {
      req(current_raster(), selected_stat(), selected_pays())
      
      raster_obj <- current_raster()
      palette <- colorNumeric(
        palette = indicator_palettes[[selected_stat()]],
        domain = values(raster_obj),
        na.color = "transparent"
      )
      
      leaflet() %>%
        addTiles() %>%
        addRasterImage(
          raster_obj,
          colors = palette,
          opacity = 0.8,
          group = selected_stat()
        ) %>%
        addLegend(
          pal = palette,
          values = values(raster_obj),
          title = paste("Indice :", selected_stat()),
          position = "bottomright"
        )
      
    } else if (input$view_type == "Agrégation par Niveau Administratif") {
      req(aggregated_data(), selected_stat(), selected_pays(), input$admin_level)
      
      shapefile_df <- aggregated_data()
      zone_col <- zone_name_column()
      
      pal <- colorNumeric(
        palette = indicator_palettes[[selected_stat()]],
        domain = shapefile_df$mean_value,
        na.color = "transparent"
      )
      
      labels <- paste0(shapefile_df[[zone_col]], ": ", 
                       ifelse(is.na(shapefile_df$mean_value), "NA", 
                              paste0("Valeur Moyenne: ", round(shapefile_df$mean_value, 2))))
      
      leaflet(shapefile_df) %>%
        addTiles() %>%
        addPolygons(
          fillColor = ~pal(mean_value),
          fillOpacity = 0.7,
          color = "black",
          weight = 1,
          highlightOptions = highlightOptions(color = "blue", weight = 2, bringToFront = TRUE),
          label = ~labels,
          labelOptions = labelOptions(
            style = list("font-weight" = "normal", padding = "3px 8px"),
            textsize = "15px",
            direction = "auto"
          )
        ) %>%
        addLegend(
          pal = pal,
          values = shapefile_df$mean_value,
          title = paste("Indice :", selected_stat()),
          position = "bottomright"
        )
    }
  })
  
  # Valeur moyenne globale
  output$meanValue <- renderText({
    req(input$view_type == "Raster", mean_value())
    paste("Valeur moyenne globale de l'indicateur sélectionné :", mean_value())
  })
  
  # Statistiques par niveau administratif
  output$adminStats <- renderTable({
    req(input$view_type == "Agrégation par Niveau Administratif", aggregated_data(), zone_name_column())
    shapefile_df <- aggregated_data()
    zone_col <- zone_name_column()
    
    stats_table <- shapefile_df %>%
      st_set_geometry(NULL) %>%
      select(Zone = all_of(zone_col), Mean_Value = mean_value) %>%
      arrange(desc(Mean_Value))
    
    stats_table$Mean_Value <- round(stats_table$Mean_Value, 2)
    
    stats_table
  })
  
}

# Lancer l'application Shiny
shinyApp(ui, server)
