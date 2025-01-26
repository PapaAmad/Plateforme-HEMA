# Serveur
server <- function(input, output, session) {
  
  # Filtrer les données selon la sélection utilisateur
  filtered_data <- reactive({
    data_filtered %>% filter(country == input$country, year >= input$year)
  })
  
  # Charger les shapefiles dynamiquement en fonction du pays et du niveau administratif
  selected_shapefiles <- reactive({
    shape_data <- load_shapefiles(input$country)[[input$admin_level]]
    
    # Vérifier les colonnes disponibles pour éviter l'erreur "NAME_1 not found"
    col_names <- colnames(shape_data)
    if ("NAME_1" %in% col_names) {
      shape_data$label_col <- shape_data$NAME_1
    } else if ("NAME_FR" %in% col_names) {
      shape_data$label_col <- shape_data$NAME_FR
    } else {
      shape_data$label_col <- shape_data[,1]  # Utilisation de la première colonne disponible
    }
    
    return(shape_data)
  })
  
  # Générer la carte interactive
  output$map <- renderLeaflet({
    shapes <- selected_shapefiles()
    data_points <- filtered_data()
    
    pal <- colorFactor(viridis(nrow(data_points), option = "turbo"), domain = data_points$event_type)
    
    leaflet(shapes) %>%
      addTiles() %>%
      addPolygons(
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
      addLegend("bottomright", pal = pal, values = data_points$event_type, title = "Type d'événement")
  })
  
  # Résumé des données en fonction du niveau administratif
  output$summary_table <- renderTable({
    admin_col <- switch(input$admin_level,
                        "adm0" = "country",
                        "adm1" = "admin1",
                        "adm2" = "admin2",
                        "adm3" = "admin3")
    
    if (input$display_type == "event_type") {
      filtered_data() %>%
        group_by(!!sym(admin_col), event_type) %>%
        summarise(Nombre = n(), .groups = 'drop') %>%
        arrange(desc(Nombre))
    } else {
      filtered_data() %>%
        group_by(!!sym(admin_col)) %>%
        summarise(Nombre_total = n(), .groups = 'drop')
    }
  })
  
  # Graphique de séries temporelles
  output$time_series_plot <- renderPlot({
    df <- filtered_data() %>%
      group_by(year) %>%
      summarise(Nombre_attaques = n())
    
    ggplot(df, aes(x = year, y = Nombre_attaques)) +
      geom_line(color = "blue", size = 1.2) +
      geom_point(color = "red", size = 3) +
      theme_minimal() +
      labs(title = paste("Nombre d'attaques au", input$country, "depuis", input$year),
           x = "Année", y = "Nombre d'attaques")
  })
}
