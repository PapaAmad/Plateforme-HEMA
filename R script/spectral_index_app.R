library(shiny)
library(leaflet)
library(raster)
library(sf)
library(dplyr)
library(viridis)
library(exactextractr)
library(ggplot2)

# --------------------------------------------------------------------
# 1. Définition des chemins des fichiers
# --------------------------------------------------------------------
raster_paths <- list(
  "Sénégal" = list(
    "NDVI"  = "data/Senegal/Rasters/Spectral_index/NDVI_SN_5km.tif",
    "MNDWI" = "data/Senegal/Rasters/Spectral_index/MNDWI_SN_5km.tif",
    "BSI_1" = "data/Senegal/Rasters/Spectral_index/Bare_Soil_Index_SN_5km.tif",
    "NDBI"  = "data/Senegal/Rasters/Spectral_index/NDBI_SN_5km.tif",
    "EVI"   = "data/Senegal/Rasters/Spectral_index/EVI_SN_5km.tif"
  ),
  "Burkina Faso" = list(
    "NDVI"  = "data/Burkina/Rasters/Spectral_index/NDVI_BFA_5km.tif",
    "MNDWI" = "data/Burkina/Rasters/Spectral_index/MNDWI_BFA_5km.tif",
    "BSI_1" = "data/Burkina/Rasters/Spectral_index/Bare_Soil_Index_BFA_5km.tif",
    "NDBI"  = "data/Burkina/Rasters/Spectral_index/NDBI_BFA_5km.tif",
    "EVI"   = "data/Burkina/Rasters/Spectral_index/EVI_BFA_5km.tif"
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

# --------------------------------------------------------------------
# 2. Palettes de couleurs pour chaque indicateur
# --------------------------------------------------------------------
indicator_palettes <- list(
  "NDVI"  = "YlGn",      # Vert (végétation)
  "MNDWI" = "Blues",     # Bleu (eau)
  "BSI_1" = "Oranges",   # Orange (sols nus)
  "NDBI"  = "Purples",   # Violet (zones construites)
  "EVI"   = "Greens"     # Vert intense (végétation améliorée)
)

# --------------------------------------------------------------------
# 3. Mapping des codes pays (SEN, BFA) vers leurs noms complets
# --------------------------------------------------------------------
pays_mapping <- list(
  "SEN" = "Sénégal",
  "BFA" = "Burkina Faso"
)

# --------------------------------------------------------------------
# 4. Interface utilisateur
# --------------------------------------------------------------------
ui <- fluidPage(
  
  sidebarLayout(
    sidebarPanel(
      radioButtons("view_type", "Type de visualisation :", 
                   choices = c("Raster", "Agrégation par Niveau Administratif"),
                   selected = "Raster"),
      
      # Afficher les valeurs (pays / stat) provenant de l'URL
      uiOutput("selected_params"),
      
      # Sélecteur de niveau administratif (seulement si Agrégation)
      conditionalPanel(
        condition = "input.view_type == 'Agrégation par Niveau Administratif'",
        selectInput("admin_level", "Niveau administratif :", 
                    choices = c("0", "1", "2", "3"), selected = "0")
      )
    ),
    
    mainPanel(
      fluidRow(
        column(8,
               leafletOutput("map", height = 600)
        ),
        column(4,
               conditionalPanel(
                 condition = "input.view_type == 'Raster'",
                 wellPanel(
                   h4("Valeur Moyenne Globale"),
                   textOutput("meanValue")
                 )
               ),
               conditionalPanel(
                 condition = "input.view_type == 'Agrégation par Niveau Administratif'",
                 wellPanel(
                   h4("Statistiques par Zone Administrative"),
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

# --------------------------------------------------------------------
# 5. Serveur
# --------------------------------------------------------------------
server <- function(input, output, session) {
  
  # ------------------------------------------------------------------
  # 5.1 Récupération des paramètres depuis l'URL
  # ------------------------------------------------------------------
  query <- reactive({
    parseQueryString(session$clientData$url_search)
  })
  
  selected_pays_code <- reactive({
    pays_code <- query()$pays
    if (is.null(pays_code) || length(pays_code) != 1 || 
        !(toupper(pays_code) %in% names(pays_mapping))) {
      # Défaut : SEN
      "SEN"
    } else {
      toupper(pays_code)
    }
  })
  
  selected_pays <- reactive({
    pays_mapping[[ selected_pays_code() ]]
  })
  
  selected_stat <- reactive({
    stat <- query()$stat
    if (is.null(stat) || length(stat) != 1 || 
        !(stat %in% names(indicator_palettes))) {
      # Défaut : NDVI
      "NDVI"
    } else {
      stat
    }
  })
  
  # ------------------------------------------------------------------
  # 5.2 Lecture “à la demande” (lazy loading) du raster
  # ------------------------------------------------------------------
  current_raster <- reactive({
    req(selected_pays(), selected_stat())
    path <- raster_paths[[ selected_pays() ]][[ selected_stat() ]]
    if (!is.null(path) && file.exists(path)) {
      raster::raster(path)
    } else {
      NULL
    }
  })
  
  # ------------------------------------------------------------------
  # 5.3 Lecture “à la demande” du shapefile
  # ------------------------------------------------------------------
  current_shapefile <- reactive({
    req(selected_pays(), input$admin_level)
    path <- shapefile_paths[[ selected_pays() ]][[ as.character(input$admin_level) ]]
    if (!is.null(path) && file.exists(path)) {
      st_read(path, quiet = TRUE)
    } else {
      NULL
    }
  })
  
  # ------------------------------------------------------------------
  # 5.4 Détection de la colonne de nom de zone (première colonne texte)
  # ------------------------------------------------------------------
  zone_name_column <- reactive({
    shp <- current_shapefile()
    if (is.null(shp)) return(NULL)
    char_cols <- names(shp)[sapply(shp, function(col) is.character(col) || is.factor(col))]
    if (length(char_cols) == 0) {
      return(NULL)
    }
    # On prend la première colonne qui est de type texte
    char_cols[1]
  })
  
  # ------------------------------------------------------------------
  # 5.5 Calcul agrégé (exactextractr) par zone
  # ------------------------------------------------------------------
  aggregated_data <- reactive({
    req(current_raster(), current_shapefile(), zone_name_column())
    extracted_vals <- exact_extract(current_raster(), current_shapefile(), 'mean')
    shp_df <- current_shapefile()
    shp_df$mean_value <- extracted_vals
    shp_df
  })
  
  # ------------------------------------------------------------------
  # 5.6 Calcul de la moyenne globale (uniquement en mode Raster)
  # ------------------------------------------------------------------
  mean_value <- reactive({
    req(current_raster())
    round(raster::cellStats(current_raster(), stat = "mean", na.rm = TRUE), 2)
  })
  
  # ------------------------------------------------------------------
  # 5.7 Output Leaflet (renderLeaflet)
  # ------------------------------------------------------------------
  output$map <- renderLeaflet({
    
    if (input$view_type == "Raster") {
      # ---------- Mode Raster -----------
      req(current_raster())
      rast <- current_raster()
      stat <- selected_stat()
      
      # Palette
      pal <- colorNumeric(
        palette = indicator_palettes[[ stat ]],
        domain  = values(rast),
        na.color = "transparent"
      )
      
      leaflet() %>%
        addTiles() %>%
        addRasterImage(
          rast,
          colors = pal,
          opacity = 0.8,
          group = stat
        ) %>%
        addLegend(
          pal = pal,
          values = values(rast),
          title = paste("Indice :", stat),
          position = "bottomright"
        )
      
    } else {
      # ---------- Mode Agrégation -----------
      req(aggregated_data())
      shp_df <- aggregated_data()
      stat <- selected_stat()
      zone_col <- zone_name_column()
      
      pal <- colorNumeric(
        palette = indicator_palettes[[ stat ]],
        domain  = shp_df$mean_value,
        na.color = "transparent"
      )
      
      labels <- paste0(
        shp_df[[zone_col]], ": ",
        ifelse(is.na(shp_df$mean_value), "NA",
               paste0("Valeur moyenne : ", round(shp_df$mean_value, 2)))
      )
      
      leaflet(shp_df) %>%
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
          values = shp_df$mean_value,
          title = paste("Indice :", stat),
          position = "bottomright"
        )
    }
  })
  
  # ------------------------------------------------------------------
  # 5.8 Affichage de la moyenne globale (texte)
  # ------------------------------------------------------------------
  output$meanValue <- renderText({
    req(input$view_type == "Raster", mean_value())
    paste("Valeur moyenne globale de l'indicateur :", mean_value())
  })
  
  # ------------------------------------------------------------------
  # 5.9 Tableau des statistiques par zone
  # ------------------------------------------------------------------
  output$adminStats <- renderTable({
    req(input$view_type == "Agrégation par Niveau Administratif", aggregated_data())
    shp_df <- aggregated_data()
    zone_col <- zone_name_column()
    if (is.null(zone_col)) return(NULL)
    
    stats_table <- shp_df %>%
      st_set_geometry(NULL) %>%
      select(Zone = all_of(zone_col), Mean_Value = mean_value) %>%
      arrange(desc(Mean_Value))
    
    stats_table$Mean_Value <- round(stats_table$Mean_Value, 2)
    
    stats_table
  })
  
}

# --------------------------------------------------------------------
# 6. Lancement de l'application
# --------------------------------------------------------------------
shinyApp(ui, server)
