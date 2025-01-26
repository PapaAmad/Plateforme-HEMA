# Interface utilisateur (UI)
ui <- fluidPage(
  titlePanel("Analyse des événements au Sénégal et au Burkina Faso"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Choisir un pays :", 
                  choices = unique(data_filtered$country), 
                  selected = "Senegal"),
      
      selectInput("year", "Année de départ :", 
                  choices = sort(unique(data_filtered$year), decreasing = TRUE),
                  selected = 2024),
      
      radioButtons("display_type", "Que souhaitez-vous afficher ?", 
                   choices = c("Types d'événements" = "event_type", 
                               "Nombre d'événements" = "event_count")),
      
      selectInput("admin_level", "Niveau administratif :", 
                  choices = c("National (adm0)" = "adm0",
                              "Régional (adm1)" = "adm1",
                              "Départemental (adm2)" = "adm2",
                              "Commune (adm3)" = "adm3"), 
                  selected = "adm1"),
      
      actionButton("update", "Mettre à jour")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Carte", leafletOutput("map", height = 600)),
        tabPanel("Résumé", tableOutput("summary_table")),
        tabPanel("Tendances temporelles", plotOutput("time_series_plot", height = 400))
      )
    )
  )
)
