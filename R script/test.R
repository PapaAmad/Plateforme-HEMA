library(shiny)
library(sf)
library(raster)
library(dplyr)
library(leaflet)
library(viridis)
library(exactextractr)
library(ggplot2)

# -----------------------------
# 1) Charger les shapefiles
# -----------------------------
# Sénégal
adm0_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp")
adm1_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp")
adm2_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp")
adm3_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp")

# Burkina
adm0_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM0.shp")
adm1_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM1.shp")
adm2_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM2.shp")
adm3_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM3.shp")

# -----------------------------
# 2) Charger les rasters (2000-2022)
# -----------------------------
chemin_dossier_SN <- "data/Senegal/Rasters/Malaria"
chemin_dossier_BFA <- "data/Burkina/Rasters/Malaria"

fichiers_raster_SN  <- list.files(chemin_dossier_SN, pattern = "\\.tiff$", full.names = TRUE)
fichiers_raster_BFA <- list.files(chemin_dossier_BFA, pattern = "\\.tiff$", full.names = TRUE)

# IMPORTANT : Charger seulement la première bande (band = 1) pour chaque TIFF
r_list_SN  <- lapply(fichiers_raster_SN,  function(f) raster(f, band = 1))
rasters_SN <- stack(r_list_SN)

r_list_BFA <- lapply(fichiers_raster_BFA, function(f) raster(f, band = 1))
rasters_BFA <- stack(r_list_BFA)

years_vec <- 2000:2022

# -----------------------------
# 3) Fonctions utilitaires
# -----------------------------
extract_stat_per_admin <- function(r, admin_sf, fun = "mean") {
  val <- exact_extract(r, admin_sf, fun)
  admin_sf[[paste0(fun, "_index")]] <- val
  return(admin_sf)
}

calc_stack_stat <- function(stack_obj, fun = mean) {
  calc(stack_obj, fun = fun, na.rm = TRUE)
}

extract_timeseries_one_admin <- function(poly, stack_obj, fun = "mean") {
  val_list <- exact_extract(stack_obj, poly, fun = fun)
  val_vec  <- unlist(val_list)
  return(val_vec)
}

# -----------------------------
# 4) Interface UI
# -----------------------------
ui <- fluidPage(
  fluidRow(
    # ---- COLONNE 1 : Boîte d'options ----
    column(
      width = 3,
      wellPanel(
        h4("Options"),
        radioButtons("display_type", "Type de visualisation :",
                     choices = c("Polygones agrégés (2000-2022)" = "aggregated_poly",
                                 "Raster agrégé (2000-2022)" = "aggregated_raster")),
        
        # Suppression des sélections 'pays' et 'stat'
        
        # Afficher le choix du niveau admin uniquement en mode "aggregated_poly"
        conditionalPanel(
          condition = "input.display_type == 'aggregated_poly'",
          selectInput("admin_level", "Niveau administratif :",
                      choices = c("Niveau 0" = 0, "Niveau 1" = 1, "Niveau 2" = 2, "Niveau 3" = 3),
                      selected = 1),
          helpText("Cliquez sur un polygone pour voir la série temporelle.")
        )
      )
    ),
    
    # ---- COLONNE 2 : Carte ----
    column(
      width = 5,
      leafletOutput("map", height = 600)  # Hauteur fixe de 600px
    ),
    
    # ---- COLONNE 3 : Zone de résultats ----
    column(
      width = 4,
      # On n'affiche le bloc résultats que si mode poly + un polygone est cliqué
      conditionalPanel(
        condition = "input.display_type == 'aggregated_poly' && output.polyClicked == true",
        h4("Résultats pour la zone sélectionnée"),
        
        div(
          style = "height:600px; overflow-y:auto; border: 1px solid #ddd; padding: 10px;",
          
          tabsetPanel(
            tabPanel("Résumé", tableOutput("resume_table")),
            tabPanel("Évolution", plotOutput("time_series_plot", height = "400px"))
          )
        )
      )
    )
  )
)

# -----------------------------
# 5) Server
# -----------------------------
server <- function(input, output, session) {
  
  # A) Lire les paramètres de l'URL
  query <- reactive({
    parseQueryString(session$clientData$url_search)
  })
  
  # B) Extraire 'pays' et 'stat' depuis les paramètres
  selected_pays <- reactive({
    pays <- query()$pays
    if (is.null(pays) || !(pays %in% c("SEN", "BFA"))) {
      # Valeur par défaut ou gestion d'erreur
      "SEN"
    } else {
      pays
    }
  })
  
  selected_stat <- reactive({
    stat <- query()$stat
    if (is.null(stat) || !(stat %in% c("Mean", "Median", "Min", "Max"))) {
      # Valeur par défaut ou gestion d'erreur
      "Mean"
    } else {
      stat
    }
  })
  
  # C) Récupérer le stack (Sénégal ou Burkina) basé sur 'selected_pays'
  stack_react <- reactive({
    if (selected_pays() == "SEN") {
      rasters_SN
    } else {
      rasters_BFA
    }
  })
  
  # D) Déterminer la fonction d'agrégation basée sur 'selected_stat'
  agg_fun <- reactive({
    switch(selected_stat(),
           "Mean"   = mean,
           "Median" = median,
           "Min"    = min,
           "Max"    = max)
  })
  
  # E) RASTER AGRÉGÉ (2000->2022) (commun aux deux modes)
  aggregated_raster <- reactive({
    calc_stack_stat(stack_react(), fun = agg_fun())
  })
  
  # F) Mode POLYGONES AGRÉGÉS
  # F1. Récupérer le shapefile
  sf_admin_react <- reactive({
    req(input$display_type == "aggregated_poly")
    
    if (selected_pays() == "SEN") {
      switch(as.character(input$admin_level),
             "0" = adm0_SN,
             "1" = adm1_SN,
             "2" = adm2_SN,
             "3" = adm3_SN)
    } else {
      switch(as.character(input$admin_level),
             "0" = adm0_BFA,
             "1" = adm1_BFA,
             "2" = adm2_BFA,
             "3" = adm3_BFA)
    }
  })
  
  # F2. Extraire les valeurs agrégées pour chaque polygone
  sf_with_stat <- reactive({
    req(input$display_type == "aggregated_poly", aggregated_raster(), sf_admin_react())
    
    fun_label <- tolower(selected_stat())
    admin_sf  <- sf_admin_react()
    
    admin_sf_stat <- extract_stat_per_admin(aggregated_raster(), admin_sf, fun = fun_label)
    admin_sf_stat <- admin_sf_stat %>%
      mutate(row_id = dplyr::row_number())
    
    admin_sf_stat
  })
  
  # G) Carte Leaflet (sortie)
  output$map <- renderLeaflet({
    if (input$display_type == "aggregated_poly") {
      req(sf_with_stat())
      
      col_name <- paste0(tolower(selected_stat()), "_index")
      vals <- sf_with_stat()[[col_name]]
      
      pal <- colorNumeric("viridis", domain = vals, na.color = "transparent")
      
      leaflet(sf_with_stat()) %>%
        addTiles() %>%
        addPolygons(
          layerId = ~paste0("poly_", row_id),
          fillColor = ~pal(vals),
          fillOpacity = 0.7,
          color = "white",
          weight = 2,
          highlightOptions = highlightOptions(color = "blue", weight = 3, bringToFront = TRUE)
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal,
          values = vals,
          title = paste("Stat :", selected_stat(), "(2000-2022)")
        )
      
    } else {
      # Mode Raster agrégé
      req(aggregated_raster())
      
      r <- aggregated_raster()
      r_min <- raster::minValue(r)
      r_max <- raster::maxValue(r)
      
      pal <- colorNumeric("viridis", domain = c(r_min, r_max), na.color = "transparent")
      
      leaflet() %>%
        addTiles() %>%
        addRasterImage(
          r,
          colors  = pal,
          opacity = 0.7,
          project = TRUE
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal,
          values = c(r_min, r_max),
          title = paste("Indice :", selected_stat(), "(2000-2022)")
        )
    }
  })
  
  # H) Gestion du clic sur un polygone
  polyClicked <- reactiveVal(FALSE)
  output$polyClicked <- reactive({ polyClicked() })
  outputOptions(output, "polyClicked", suspendWhenHidden = FALSE)
  
  selected_poly_index <- reactiveVal(NULL)
  
  observeEvent(input$map_shape_click, {
    if (input$display_type != "aggregated_poly") {
      polyClicked(FALSE)
      return(NULL)
    }
    
    click <- input$map_shape_click
    if (is.null(click$id)) {
      polyClicked(FALSE)
    } else {
      polyClicked(TRUE)
      row_index <- as.numeric(sub("poly_", "", click$id))
      selected_poly_index(row_index)
    }
  })
  
  # I) Série temporelle
  timeseries_data <- reactive({
    if (input$display_type != "aggregated_poly") {
      return(data.frame(Annee = numeric(0), Valeur = numeric(0)))
    }
    req(selected_poly_index())
    
    shape_data <- sf_admin_react() %>%
      mutate(row_id = dplyr::row_number())
    
    idx <- selected_poly_index()
    poly_sel <- shape_data[shape_data$row_id == idx, ]
    
    val_vec <- extract_timeseries_one_admin(poly_sel, stack_react(), fun = tolower(selected_stat()))
    
    df <- data.frame(
      Annee  = years_vec,
      Valeur = val_vec
    )
    df <- na.omit(df)
    df
  })
  
  output$resume_table <- renderTable({
    req(timeseries_data())
    timeseries_data()
  })
  
  output$time_series_plot <- renderPlot({
    req(timeseries_data())
    df <- timeseries_data()
    
    ggplot(df, aes(x = Annee, y = Valeur)) +
      geom_line(color = "blue") +
      geom_point(color = "blue") +
      theme_minimal() +
      labs(
        x = "Année",
        y = paste("Valeur", selected_stat()),
        title = paste("Évolution de", selected_stat(), "de 2000 à 2022")
      )
  })
}

# -----------------------------
# 6) Lancement de l'application
# -----------------------------
shinyApp(ui = ui, server = server)
