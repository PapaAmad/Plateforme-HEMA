library(shiny)
library(sf)
library(terra)
library(dplyr)
library(leaflet)
library(viridis)
library(exactextractr)
library(ggplot2)

# -----------------------------
# 1) Charger les shapefiles
# -----------------------------
# Sénégal
adm0_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp", quiet = TRUE)
adm1_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp", quiet = TRUE)
adm2_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp", quiet = TRUE)
adm3_SN <- st_read("data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp", quiet = TRUE)

# Burkina Faso
adm0_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM0.shp", quiet = TRUE)
adm1_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM1.shp", quiet = TRUE)
adm2_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM2.shp", quiet = TRUE)
adm3_BFA <- st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM3.shp", quiet = TRUE)

# ----------------------------------
# 2) Charger les rasters (2000-2022)
# ----------------------------------
chemin_dossier_SN <- "data/Senegal/Rasters/Malaria"
chemin_dossier_BFA <- "data/Burkina/Rasters/Malaria"

fichiers_raster_SN  <- sort(list.files(chemin_dossier_SN, pattern = "\\.tiff$", full.names = TRUE))
fichiers_raster_BFA <- sort(list.files(chemin_dossier_BFA, pattern = "\\.tiff$", full.names = TRUE))

# Charger uniquement la première bande (band = 1) pour chaque TIFF
rasters_SN_list <- lapply(fichiers_raster_SN, function(f) {
  rast(f)[[1]]  # Extraire la première couche de chaque raster
})
rasters_SN <- rast(rasters_SN_list)

rasters_BFA_list <- lapply(fichiers_raster_BFA, function(f) {
  rast(f)[[1]]  # Extraire la première couche de chaque raster
})
rasters_BFA <- rast(rasters_BFA_list)

# Réaffirmer le CRS après empilage
crs(rasters_SN) <- crs(adm0_SN)
crs(rasters_BFA) <- crs(adm0_BFA)

# Création du vecteur année
years_vec <- 2000:2022

# -------------------------------------
# 2b) Charger les rasters de population
# -------------------------------------
# Fonction pour agréger les rasters de population si nécessaire
aggregate_population <- function(country_code, worldpop_path, fact = 50) {
  message(paste("Agrégation du raster de population pour", country_code))
  WorldPop <- rast(worldpop_path)
  
  WorldPop_aggregated <- aggregate(WorldPop, fact = fact, fun = sum, na.rm = TRUE)
  WorldPop_children <- WorldPop_aggregated * 0.001
  return(WorldPop_children)
}

# Sénégal
WorldPop_SN_children <- aggregate_population(
  country_code = "SEN",
  worldpop_path = "data/Senegal/Rasters/WorldPop/worldpop_SN.tif",
  fact = 50
)

# Burkina Faso
WorldPop_BFA_children <- aggregate_population(
  country_code = "BFA",
  worldpop_path = "data/Burkina/Rasters/WorldPop/worldpop_BFA.tif",
  fact = 50
)

# -----------------------------
# 3) Fonctions utilitaires
# -----------------------------
extract_stat_per_admin <- function(r, admin_sf, fun = "mean") {
  val <- exact_extract(r, admin_sf, fun)
  admin_sf[[paste0(fun, "_index")]] <- val
  return(admin_sf)
}

calc_stack_stat <- function(stack_obj, fun = mean) {
  terra::app(stack_obj, fun = fun, na.rm = TRUE)
}

extract_timeseries_one_admin <- function(poly, stack_obj, fun = "mean") {
  val_list <- exact_extract(stack_obj, poly, fun)
  val_vec  <- unlist(val_list)
  return(val_vec)
}

# Fonction pour calculer les indicateurs d'enfants malades
calc_children_indicators <- function(admin_sf, selected_pays) {
  
  if (selected_pays == "SEN") {
    WorldPop_children <- WorldPop_SN_children
    stack_data <- rasters_SN
  } else {
    WorldPop_children <- WorldPop_BFA_children
    stack_data <- rasters_BFA
  }
  
  num_layers <- terra::nlyr(stack_data)
  
  # Calculer les indicateurs pour chaque année
  children_malaria_list <- list()
  children_total_list <- list()
  
  for (i in 1:num_layers) {
    raster_year <- stack_data[[i]]
    
    # Reprojeter et aligner le raster de malaria
    raster_proj <- project(raster_year, WorldPop_children, method = "near")
    raster_aligned <- resample(raster_proj, WorldPop_children, method = "near")
    
    # Calculer le nombre d'enfants malades
    children_malaria_raster <- raster_aligned * WorldPop_children
    
    # Extraire les valeurs par polygone
    malaria_vals <- exact_extract(children_malaria_raster, admin_sf, 'sum')
    total_vals <- exact_extract(WorldPop_children, admin_sf, 'sum')
    
    children_malaria_list[[i]] <- malaria_vals
    children_total_list[[i]] <- total_vals
  }
  
  # Convertir les listes en matrices
  children_malaria_mat <- do.call(cbind, children_malaria_list)
  children_total_mat <- do.call(cbind, children_total_list)
  
  # Calculer les taux
  taux_malaria_mat <- (children_malaria_mat / children_total_mat) * 100
  
  # Ajouter au shapefile
  admin_sf <- admin_sf %>%
    mutate(
      children_malaria_sum = rowSums(children_malaria_mat, na.rm = TRUE),
      children_total_sum = rowSums(children_total_mat, na.rm = TRUE),
      taux_malaria_mean = rowMeans(taux_malaria_mat, na.rm = TRUE)
    )
  
  return(admin_sf)
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
                     choices = c(
                       "Polygones agrégés (2000-2022)" = "aggregated_poly",
                       "Raster agrégé (2000-2022)" = "aggregated_raster",
                       "Raster classifié 2021" = "classified_raster"
                     )),
        
        # Afficher le choix du niveau admin uniquement en mode "aggregated_poly"
        conditionalPanel(
          condition = "input.display_type == 'aggregated_poly'",
          selectInput("admin_level", "Niveau administratif :",
                      choices = c("Niveau 0" = 0, "Niveau 1" = 1, "Niveau 2" = 2, "Niveau 3" = 3),
                      selected = 1),
          # Ajouter une sélection de statistique
          selectInput("stat_selection", "Statistique :",
                      choices = c(
                        "Mean" = "Mean",
                        "Median" = "Median",
                        "Min" = "Min",
                        "Max" = "Max",
                        "Nombre d'enfants malades" = "Children_Malaria",
                        "Taux d'enfants malades" = "Children_Rate"
                      ),
                      selected = "Mean"),
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
        # Remplacement du titre statique par un titre dynamique
        uiOutput("selected_zone_title"),
        
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
  
  # B) Extraire 'pays' depuis les paramètres
  selected_pays <- reactive({
    pays <- query()$pays
    if (is.null(pays) || !(pays %in% c("SEN", "BFA"))) {
      # Valeur par défaut ou gestion d'erreur
      "SEN"
    } else {
      pays
    }
  })
  
  # C) Extraire 'stat' depuis la sélection utilisateur
  selected_stat <- reactive({
    stat <- input$stat_selection
    if (is.null(stat) || !(stat %in% c("Mean", "Median", "Min", "Max", 
                                       "Children_Malaria", "Children_Rate"))) {
      # Valeur par défaut ou gestion d'erreur
      "Mean"
    } else {
      stat
    }
  })
  
  # D) Récupérer le stack (Sénégal ou Burkina) basé sur 'selected_pays'
  stack_react <- reactive({
    if (selected_pays() == "SEN") {
      rasters_SN
    } else {
      rasters_BFA
    }
  })
  
  # E) Déterminer la fonction d'agrégation basée sur 'selected_stat'
  agg_fun <- reactive({
    switch(selected_stat(),
           "Mean"   = mean,
           "Median" = median,
           "Min"    = min,
           "Max"    = max,
           "Children_Malaria" = sum,
           "Children_Rate" = mean)
  })
  
  # F) RASTER AGRÉGÉ (2000->2022) (commun aux deux modes)
  aggregated_raster <- reactive({
    req(stack_react())
    if (selected_stat() %in% c("Mean", "Median", "Min", "Max")) {
      calc_stack_stat(stack_react(), fun = agg_fun())
    } else {
      NULL
    }
  })
  
  # G) Mode POLYGONES AGRÉGÉS
  # G1. Récupérer le shapefile
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
  
  # G2. Extraire les valeurs agrégées pour chaque polygone
  sf_with_stat <- reactive({
    req(input$display_type == "aggregated_poly")
    
    admin_sf <- sf_admin_react()
    
    if (selected_stat() %in% c("Mean", "Median", "Min", "Max")) {
      admin_sf_stat <- extract_stat_per_admin(aggregated_raster(), admin_sf, tolower(selected_stat()))
      admin_sf_stat <- admin_sf_stat %>%
        mutate(row_id = seq_len(n()))
      return(admin_sf_stat)
    } else if (selected_stat() %in% c("Children_Malaria", "Children_Rate")) {
      admin_sf_indicators <- calc_children_indicators(admin_sf, selected_pays())
      admin_sf_indicators <- admin_sf_indicators %>%
        mutate(row_id = seq_len(n()))
      return(admin_sf_indicators)
    } else {
      return(NULL)
    }
  })
  
  # H) Carte Leaflet (sortie)
  output$map <- renderLeaflet({
    if (input$display_type == "aggregated_poly") {
      req(sf_with_stat())
      
      admin_sf <- sf_with_stat()
      
      if (selected_stat() %in% c("Mean", "Median", "Min", "Max")) {
        # Récupérer dynamiquement le nom de la première colonne
        name_col <- names(admin_sf)[1]
        
        # Extraire les valeurs pour la couleur
        col_name <- paste0(tolower(selected_stat()), "_index")
        vals <- admin_sf[[col_name]]
        
        # Définir la palette de couleurs
        pal <- colorNumeric("viridis", domain = vals, na.color = "transparent")
        
        leaflet(admin_sf) %>%
          addTiles() %>%
          addPolygons(
            layerId = ~paste0("poly_", row_id),
            fillColor = ~pal(vals),
            fillOpacity = 0.7,
            color = "white",
            weight = 2,
            highlightOptions = highlightOptions(color = "blue", weight = 3, bringToFront = TRUE),
            
            # Ajouter l'étiquette en utilisant la première colonne
            label = ~get(name_col),
            
            # Personnaliser les options de l'étiquette
            labelOptions = labelOptions(
              style = list(
                "font-weight" = "normal",
                padding = "3px 8px"
              ),
              textsize = "15px",
              direction = "auto"
            )
          ) %>%
          addLegend(
            position = "bottomright",
            pal = pal,
            values = vals,
            title = paste("Stat :", selected_stat(), "(2000-2022)")
          )
        
      } else if (selected_stat() == "Children_Malaria") {
        # Nombre d'enfants malades
        vals <- admin_sf$children_malaria_sum
        pal <- colorNumeric("Reds", domain = vals, na.color = "transparent")
        
        leaflet(admin_sf) %>%
          addTiles() %>%
          addPolygons(
            layerId = ~paste0("poly_", row_id),
            fillColor = ~pal(vals),
            fillOpacity = 0.7,
            color = "white",
            weight = 2,
            highlightOptions = highlightOptions(color = "red", weight = 3, bringToFront = TRUE),
            label = ~paste0(admin_sf[[1]], " Enfants malades: ", round(children_malaria_sum)),
            labelOptions = labelOptions(
              style = list(
                "font-weight" = "normal",
                padding = "3px 8px"
              ),
              textsize = "15px",
              direction = "auto"
            )
          ) %>%
          addLegend(
            position = "bottomright",
            pal = pal,
            values = vals,
            title = "Nombre d'enfants malades",
            opacity = 1
          )
        
      } else if (selected_stat() == "Children_Rate") {
        # Taux d'enfants malades
        vals <- admin_sf$taux_malaria_mean
        pal <- colorNumeric("Blues", domain = vals, na.color = "transparent")
        
        leaflet(admin_sf) %>%
          addTiles() %>%
          addPolygons(
            layerId = ~paste0("poly_", row_id),
            fillColor = ~pal(vals),
            fillOpacity = 0.7,
            color = "white",
            weight = 2,
            highlightOptions = highlightOptions(color = "blue", weight = 3, bringToFront = TRUE),
            label = ~paste0(admin_sf[[1]], " Taux de malaria: ", round(taux_malaria_mean, 2), "%"),
            labelOptions = labelOptions(
              style = list(
                "font-weight" = "normal",
                padding = "3px 8px"
              ),
              textsize = "15px",
              direction = "auto"
            )
          ) %>%
          addLegend(
            position = "bottomright",
            pal = pal,
            values = vals,
            title = "Taux d'enfants malades (%)",
            opacity = 1
          )
      }
      
    } else if (input$display_type == "aggregated_raster") {
      # Mode Raster agrégé
      req(aggregated_raster())
      
      r <- aggregated_raster()
      r_min <- global(r, min, na.rm = TRUE)[1,1]
      r_max <- global(r, max, na.rm = TRUE)[1,1]
      
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
      
    } else if (input$display_type == "classified_raster") {
      # Mode Raster Classifié 2021
      req(classified_raster_2021())
      
      # Récupérer les rasters classifiés binaires
      class_aucun <- classified_raster_2021()$aucun
      class_moyen <- classified_raster_2021()$moyen
      class_grave <- classified_raster_2021()$grave
      
      # Définir les palettes de couleurs pour chaque classe
      pal_vert <- colorFactor(palette = "green", na.color = "transparent", levels = c(1))
      pal_jaune <- colorFactor(palette = "yellow", na.color = "transparent", levels = c(1))
      pal_rouge <- colorFactor(palette = "red", na.color = "transparent", levels = c(1))
      
      leaflet() %>%
        addTiles() %>%
        
        # Ajouter le raster aucun
        addRasterImage(
          class_aucun, 
          colors = pal_vert,
          opacity = 0.6,
          group = "Aucun"
        ) %>%
        
        # Ajouter le raster moyen
        addRasterImage(
          class_moyen, 
          colors = pal_jaune, 
          opacity = 0.6, 
          group = "Moyen"
        ) %>%
        
        # Ajouter le raster grave
        addRasterImage(
          class_grave, 
          colors = pal_rouge, 
          opacity = 0.6,
          group = "Grave"
        ) %>%
        
        # Ajouter des contrôles de couches pour activer/désactiver chaque raster binaire
        addLayersControl(
          overlayGroups = c("Aucun", "Moyen", "Grave"),
          options = layersControlOptions(collapsed = FALSE)
        ) %>%
        
        # Ajouter une légende
        addLegend("bottomright", 
                  colors = c("green", "yellow", "red"), 
                  labels = c("Aucun", 
                             "Moyen", 
                             "Grave"),
                  title = "Classification",
                  opacity = 1)
    }
  })
  
  # I) Gestion du clic sur un polygone
  polyClicked <- reactiveVal(FALSE)
  output$polyClicked <- reactive({ polyClicked() })
  outputOptions(output, "polyClicked", suspendWhenHidden = FALSE)
  
  selected_poly_index <- reactiveVal(NULL)
  
  observeEvent(input$map_shape_click, {
    if (input$display_type != "aggregated_poly") {
      polyClicked(FALSE)
      selected_poly_index(NULL)
      return(NULL)
    }
    
    click <- input$map_shape_click
    if (is.null(click$id)) {
      polyClicked(FALSE)
      selected_poly_index(NULL)
    } else {
      # Extraire l'index de la polygon
      # Assurez-vous que 'row_id' est bien un nombre
      row_index <- as.numeric(gsub("poly_", "", click$id))
      
      # Vérifier que row_index est valide
      if (!is.na(row_index)) {
        total_rows <- nrow(sf_with_stat())
        if (row_index >= 1 && row_index <= total_rows) {
          polyClicked(TRUE)
          selected_poly_index(row_index)
        } else {
          polyClicked(FALSE)
          selected_poly_index(NULL)
          showNotification("Sélection de polygone invalide.", type = "error")
        }
      } else {
        polyClicked(FALSE)
        selected_poly_index(NULL)
      }
    }
  })
  
  # J) Série temporelle
  timeseries_data <- reactive({
    if (input$display_type != "aggregated_poly") {
      return(data.frame(Annee = numeric(0), Valeur = numeric(0)))
    }
    req(selected_poly_index())
    
    shape_data <- sf_admin_react() %>%
      mutate(row_id = dplyr::row_number())
    
    idx <- selected_poly_index()
    poly_sel <- shape_data[idx, ]
    
    # Initialiser le vecteur des valeurs
    val_vec <- numeric(length = length(years_vec))
    
    # Déterminer le raster de population basé sur le pays
    WorldPop_children_react <- if (selected_pays() == "SEN") {
      WorldPop_SN_children
    } else {
      WorldPop_BFA_children
    }
    
    # Itérer sur chaque année et extraire les valeurs
    for (i in seq_along(years_vec)) {
      year <- years_vec[i]
      raster_year <- stack_react()[[i]]
      
      if (selected_stat() %in% c("Mean", "Median", "Min", "Max")) {
        # Appliquer la fonction sélectionnée
        val <- exact_extract(raster_year, poly_sel, fun = tolower(selected_stat()))
        val_vec[i] <- val
      } else if (selected_stat() == "Children_Malaria") {
        # Calculer le nombre d'enfants malades pour l'année
        raster_proj <- project(raster_year, WorldPop_children_react, method = "near")
        raster_aligned <- resample(raster_proj, WorldPop_children_react, method = "near")
        children_malaria_raster <- raster_aligned * WorldPop_children_react
        sum_val <- exact_extract(children_malaria_raster, poly_sel, 'sum')[[1]]
        val_vec[i] <- sum_val
      } else if (selected_stat() == "Children_Rate") {
        # Calculer le taux d'enfants malades pour l'année
        raster_proj <- project(raster_year, WorldPop_children_react, method = "near")
        raster_aligned <- resample(raster_proj, WorldPop_children_react, method = "near")
        children_malaria_raster <- raster_aligned * WorldPop_children_react
        sum_val <- exact_extract(children_malaria_raster, poly_sel, 'sum')[[1]]
        total_vals <- exact_extract(WorldPop_children_react, poly_sel, 'sum')[[1]]
        taux <- ifelse(total_vals > 0, (sum_val / total_vals) * 100, NA)
        val_vec[i] <- taux
      }
    }
    
    df <- data.frame(
      Annee  = years_vec,
      Valeur = val_vec
    )
    
    # Nettoyer les données
    df <- na.omit(df)
    
    df
  })
  
  # K) Tableau Résumé
  output$resume_table <- renderTable({
    req(timeseries_data())
    df <- timeseries_data()
    
    if (selected_stat() == "Children_Malaria") {
      summary_df <- data.frame(
        Annee = df$Annee,
        "Nombre d'enfants malades" = round(df$Valeur)
      )
    } else if (selected_stat() == "Children_Rate") {
      summary_df <- data.frame(
        Annee = df$Annee,
        "Taux d'enfants malades (%)" = round(df$Valeur, 2)
      )
    } else {
      summary_df <- data.frame(
        Annee = df$Annee,
        Valeur = df$Valeur
      )
    }
    
    summary_df
  })
  
  # L) Graphique de la Série Temporelle
  output$time_series_plot <- renderPlot({
    req(timeseries_data())
    df <- timeseries_data()
    
    if (selected_stat() == "Children_Malaria") {
      y_label <- "Nombre d'enfants malades"
      title_plot <- "Évolution du nombre d'enfants malades de 2000 à 2022"
    } else if (selected_stat() == "Children_Rate") {
      y_label <- "Taux d'enfants malades (%)"
      title_plot <- "Évolution du taux d'enfants malades de 2000 à 2022"
    } else {
      y_label <- paste("Valeur", selected_stat())
      title_plot <- paste("Évolution de", selected_stat(), "de 2000 à 2022")
    }
    
    ggplot(df, aes(x = Annee, y = Valeur)) +
      geom_line(color = "blue") +
      geom_point(color = "blue") +
      theme_minimal() +
      labs(
        x = "Année",
        y = y_label,
        title = title_plot
      )
  })
  
  # M) Rendu Dynamique du Titre des Résultats
  output$selected_zone_title <- renderUI({
    req(selected_poly_index())
    
    shape_data <- sf_admin_react() %>%
      mutate(row_id = seq_len(n()))
    
    idx <- selected_poly_index()
    poly_sel <- shape_data[idx, ]
    
    # Extraire le nom de la première colonne
    zone_name <- poly_sel[[1]]
    
    h4(paste("Résultats pour la zone", zone_name))
  })
  
  # N) Fonction de Classification Binaire pour 2021
  classified_raster_2021 <- reactive({
    req(input$display_type == "classified_raster")
    
    # Charger le stack de rasters basé sur le pays sélectionné
    stack_data <- stack_react()
    
    # Extraire le raster pour l'année 2021 (supposons que c'est l'index 22)
    raster_2021 <- stack_data[[22]]
    
    # Calcul de la moyenne et de l'écart type sur le stack (2000-2022)
    moy_raster <- app(stack_data, fun = mean, na.rm = TRUE)
    ecrt_raster <- app(stack_data, fun = sd, na.rm = TRUE)
    
    # Définir les seuils de classification
    seuil1 <- moy_raster + ecrt_raster
    seuil2 <- moy_raster + 2 * ecrt_raster
    
    # Créer des rasters binaires pour chaque condition en utilisant des opérations logiques
    aucun <- (raster_2021 <= seuil1) * 1
    aucun[aucun == 0] <- NA
    
    moyen <- (raster_2021 > seuil1) & (raster_2021 < seuil2)
    moyen <- (moyen * 1)
    moyen[moyen == 0] <- NA
    
    grave <- (raster_2021 >= seuil2) * 1
    grave[grave == 0] <- NA
    
    # Retourner les rasters binaires dans une liste
    list(aucun = aucun, moyen = moyen, grave = grave)
  })
  
}

# -----------------------------
# 6) Lancement de l'application
# -----------------------------
shinyApp(ui = ui, server = server)
