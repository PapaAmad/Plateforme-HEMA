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

# Mapping des codes pays vers les noms complets
pays_mapping <- list(
  "SEN" = "Senegal",
  "BFA" = "Burkina Faso"
)

# Fonction pour charger les shapefiles en fonction du pays sélectionné et du niveau administratif
load_shapefiles <- function(country) {
  if (country == "Senegal") {
    list(
      adm0 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm0_anat_20240520.shp", quiet = TRUE),
      adm1 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm1_anat_20240520.shp", quiet = TRUE),
      adm2 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm2_anat_20240520.shp", quiet = TRUE),
      adm3 = st_read("data/Senegal/Shapefiles/sen_admbnda_adm3_anat_20240520.shp", quiet = TRUE)
    )
  } else {
    list(
      adm0 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM0.shp", quiet = TRUE),
      adm1 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM1.shp", quiet = TRUE),
      adm2 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM2.shp", quiet = TRUE),
      adm3 = st_read("data/Burkina/Shapefiles/geoBoundaries-BFA-ADM3.shp", quiet = TRUE)
    )
  }
}

# Interface utilisateur (UI)
ui <- fluidPage(
  
  # Ajouter du CSS pour rendre les tableaux scrollables
  tags$head(
    tags$style(HTML("
      .scrollable-table {
        max-height: 400px;
        overflow-y: scroll;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Année de départ :", 
                  choices = sort(unique(data_filtered$year), decreasing = TRUE),
                  selected = 2024),
      
      selectInput("admin_level", "Niveau administratif :", 
                  choices = c("Niveau 0" = "adm0",
                              "Niveau 1" = "adm1",
                              "Niveau 2" = "adm2",
                              "Niveau 3" = "adm3"), 
                  selected = "adm1")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Carte", leafletOutput("map", height = 600)),
        tabPanel("Résumé", 
                 div(class = "scrollable-table",
                     tableOutput("summary_table"))),
        tabPanel("Tendances temporelles", plotOutput("time_series_plot", height = 400))
      )
    )
  )
)

# Serveur
server <- function(input, output, session) {
  
  # ------------------------------------------------------------------
  # 1. Récupération des paramètres depuis l'URL
  # ------------------------------------------------------------------
  query <- reactive({
    parseQueryString(session$clientData$url_search)
  })
  
  # Fonction pour obtenir un paramètre avec une valeur par défaut
  getParam <- function(param, default) {
    value <- query()[[param]]
    if (is.null(value) || length(value) != 1) {
      return(default)
    }
    return(URLdecode(value))
  }
  
  # Définir les valeurs par défaut
  default_pays <- "SEN"  # SEN pour Sénégal, BFA pour Burkina Faso
  default_stat <- "event_type"
  
  # ------------------------------------------------------------------
  # 2. Mettre à jour les variables basées sur les paramètres de l'URL
  # ------------------------------------------------------------------
  # Lire et mapper les paramètres
  selected_pays_code <- reactive({
    pays_code <- getParam("pays", default_pays)
    if (toupper(pays_code) %in% names(pays_mapping)) {
      toupper(pays_code)
    } else {
      default_pays
    }
  })
  
  selected_pays <- reactive({
    pays_mapping[[selected_pays_code()]]
  })
  
  selected_stat <- reactive({
    stat <- getParam("stat", default_stat)
    if (stat %in% c("event_type", "event_count")) {
      stat
    } else {
      default_stat
    }
  })
  
  # ------------------------------------------------------------------
  # 3. Filtrer les données selon la sélection utilisateur et l'URL
  # ------------------------------------------------------------------
  filtered_data <- reactive({
    data_filtered %>% 
      filter(country == selected_pays(), year >= input$year)
  })
  
  # ------------------------------------------------------------------
  # 4. Charger les shapefiles dynamiquement en fonction du pays et du niveau administratif
  # ------------------------------------------------------------------
  selected_shapefiles <- reactive({
    shape_data <- load_shapefiles(selected_pays())[[(input$admin_level)]]
    
    # Vérifier les colonnes disponibles pour éviter l'erreur "NAME_1 not found"
    col_names <- colnames(shape_data)
    if ("NAME_1" %in% col_names) {
      shape_data$label_col <- shape_data$NAME_1
    } else if ("NAME_FR" %in% col_names) {
      shape_data$label_col <- shape_data$NAME_FR
    } else {
      shape_data$label_col <- shape_data[[1]]  # Utilisation de la première colonne disponible
    }
    
    return(shape_data)
  })
  
  # ------------------------------------------------------------------
  # 5. Calculer le nombre d'événements par unité administrative (si nécessaire)
  # ------------------------------------------------------------------
  event_counts <- reactive({
    req(selected_stat() == "event_count")
    shp <- selected_shapefiles()
    if (is.null(shp)) return(NULL)
    
    # Identifier la colonne administrative pour le regroupement
    admin_col_data <- switch(input$admin_level,
                             "adm0" = "country",
                             "adm1" = "admin1",
                             "adm2" = "admin2",
                             "adm3" = "admin3")
    
    # Compter les événements par unité administrative
    counts <- filtered_data() %>%
      group_by_at(admin_col_data) %>%
      summarise(event_count = n(), .groups = 'drop') %>%
      rename(label_col = !!sym(admin_col_data))
    
    # Joindre les counts avec le shapefile
    shp <- shp %>%
      left_join(counts, by = "label_col") %>%
      mutate(event_count = ifelse(is.na(event_count), 0, event_count))
    
    return(shp)
  })
  
  # ------------------------------------------------------------------
  # 6. Générer la carte interactive
  # ------------------------------------------------------------------
  output$map <- renderLeaflet({
    if (selected_stat() == "event_type") {
      data_points <- filtered_data()
      pal <- colorFactor(viridis(length(unique(data_points$event_type)), option = "turbo"), domain = data_points$event_type)
      
      leaflet() %>%
        addTiles() %>%
        addPolygons(
          data = selected_shapefiles(),
          color = "brown", weight = 1, fillOpacity = 0.4, 
          popup = ~label_col
        ) %>%
        addCircleMarkers(
          data = data_points, 
          lng = ~longitude, lat = ~latitude,
          color = ~pal(event_type), 
          popup = ~paste(event_type, "<br>", event_date),
          radius = 3  # Taille des cercles réduite
        ) %>%
        addLegend("bottomright", 
                  pal = pal, 
                  values = data_points$event_type, 
                  title = "Type d'événement")
      
    } else if (selected_stat() == "event_count") {
      shp_counts <- event_counts()
      req(shp_counts)
      
      pal <- colorNumeric(
        palette = "YlOrRd",
        domain  = shp_counts$event_count,
        na.color = "transparent"
      )
      
      labels <- paste0(
        shp_counts$label_col, ": ",
        shp_counts$event_count, " événement(s)"
      )
      
      leaflet() %>%
        addTiles() %>%
        addPolygons(
          data = shp_counts,
          fillColor = ~pal(event_count),
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
        addLegend("bottomright", 
                  pal = pal, 
                  values = shp_counts$event_count, 
                  title = "Nombre d'événements")
    }
  })
  
  # ------------------------------------------------------------------
  # 7. Résumé des données en fonction du niveau administratif
  # ------------------------------------------------------------------
  output$summary_table <- renderTable({
    admin_col <- switch(input$admin_level,
                        "adm0" = "country",
                        "adm1" = "admin1",
                        "adm2" = "admin2",
                        "adm3" = "admin3")
    
    if (selected_stat() == "event_type") {
      filtered_data() %>%
        group_by_at(vars(all_of(admin_col), event_type)) %>%
        summarise(Nombre = n(), .groups = 'drop') %>%
        arrange(desc(Nombre))
    } else {
      filtered_data() %>%
        group_by_at(vars(all_of(admin_col))) %>%
        summarise(Nombre_total = n(), .groups = 'drop') %>%
        arrange(desc(Nombre_total))
    }
  })
  
  # ------------------------------------------------------------------
  # 8. Graphique de séries temporelles
  # ------------------------------------------------------------------
  output$time_series_plot <- renderPlot({
    df <- filtered_data() %>%
      group_by(year) %>%
      summarise(Nombre_attaques = n())
    
    ggplot(df, aes(x = year, y = Nombre_attaques)) +
      geom_line(color = "blue", size = 1.2) +
      geom_point(color = "red", size = 3) +
      theme_minimal() +
      labs(title = paste("Nombre d'attaques au", selected_pays(), "depuis", input$year),
           x = "Année", y = "Nombre d'attaques")
  })
  
}

# -----------------------------
# Lancer l'application
# -----------------------------
shinyApp(ui = ui, server = server)
