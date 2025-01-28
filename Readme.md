# Plateforme de Statistique Exploratoire Spatiale

Bienvenue sur la **Plateforme de Statistique Exploratoire Spatiale**, développée dans le cadre du cours de Statistique Exploratoire Spatiale donné à l'École nationale de la Statistique et de l'Analyse économique Pierre NDIAYE de Dakar (ENSAE).

![Image de la Plateforme](https://github.com/PapaAmad/Plateforme-HEMA/blob/main/assets/img/image_plateforme.png)

## Table des Matières

1. [Introduction](#introduction)
2. [Accès à la Plateforme et aux Applications Shiny](#accès-à-la-plateforme-et-aux-applications-shiny)
3. [Intégration des Applications Shiny](#intégration-des-applications-shiny)
    - [Structure HTML](#structure-html)
    - [Script JavaScript](#script-javascript)
    - [Lecture et Extraction des Paramètres URL dans Shiny](#lecture-et-extraction-des-paramètres-url-dans-shiny)
    - [Exemples de Liens Shiny](#exemples-de-liens-shiny)
4. [Groupes d'Indices](#groupes-dindices)
    - [1. Taux de Malaria](#1-taux-de-malaria)
        - [1.1. Sources et Chargement des Données](#11-sources-et-chargement-des-données)
        - [1.2. Fonctions Utilitaires](#12-fonctions-utilitaires)
        - [1.3. Calcul des Indicateurs de Malaria](#13-calcul-des-indicateurs-de-malaria)
        - [1.4. Classification des Zones de Malaria pour 2021](#14-classification-des-zones-de-malaria-pour-2021)
    - [2. Indices Spectraux](#2-indices-spectraux)
        - [2.1. NDVI (Indice de Végétation par Différence Normalisée)](#21-ndvi-indice-de-végétation-par-différence-normalisée)
        - [2.2. MNDWI (Indice de Différence Normalisée d'Eau Modifié)](#22-mndwi-indice-de-différence-normalisée-deau-modifié)
        - [2.3. BSI_1 (Indice de Stabilité du Sol)](#23-bsi_1-indice-de-stabilité-du-sol)
        - [2.4. NDBI (Indice de Développement Urbain par Différence Normalisée)](#24-ndbi-indice-de-développement-urbain-par-différence-normalisée)
        - [2.5. EVI (Indice Amélioré de Végétation)](#25-evi-indice-amélioré-de-végétation)
    - [3. Événements Dangereux](#3-événements-dangereux)
5. [Documentation sur les Événements](#documentation-sur-les-événements)
    - [1. Résumé des Données par Niveau Administratif](#1-résumé-des-données-par-niveau-administratif)
    - [2. Analyse Temporelle des Événements](#2-analyse-temporelle-des-événements)
    - [3. Présentation de la Base de Données Utilisée](#3-présentation-de-la-base-de-données-utilisée)
    - [4. Avantages des Indicateurs Calculés](#4-avantages-des-indicateurs-calculés)
        - [4.1. Nombre d'Événements](#41-nombre-dévénements)
        - [4.2. Types d'Événements](#42-types-dévénements)
6. [Sources de Données](#sources-de-données)
7. [Contribution](#contribution)

## Introduction

Cette plateforme web présente un résumé des indicateurs statistiques spatiaux calculés au niveau administratif pour le **Sénégal** et le **Burkina Faso**. Elle offre une visualisation interactive des indicateurs tels que le taux de malaria, les indices spectraux comme le NDVI, ainsi que des indicateurs liés aux événements dangereux.

L'objectif principal de ce projet est de rassembler et d'appliquer tous les travaux pratiques (TP) réalisés lors du cours dispensé par [**M. Aboubacar HEMA**](https://github.com/Abson-dev/). Vous trouverez l'ensemble de ces TP dans ce dépôt [GitHub](https://github.com/Abson-dev/Statistique-Exploratoire-Spatiale), offrant ainsi une ressource complète pour les étudiants et les chercheurs intéressés par l'analyse spatiale des données statistiques.

## Accès à la Plateforme et aux Applications Shiny

- **Lien de la plateforme web** : [Accéder à la Plateforme](https://papaamad.github.io/Plateforme-HEMA/)
- **Lien des applications Shiny** :
  - [Taux de Malaria](https://papaamad.shinyapps.io/SES_Shiny/)
  - [Indices Spectraux](https://papaamad.shinyapps.io/SES_Shiny_Spectral/)
  - [Événements Dangereux](https://papaamad.shinyapps.io/SES_Shiny_event/)

## Intégration des Applications Shiny

Cette section décrit techniquement comment les applications Shiny sont intégrées à la plateforme web, permettant une interaction fluide et dynamique avec les utilisateurs.

### Structure HTML

La plateforme utilise une **iframe** pour intégrer les applications Shiny. Voici un extrait du code HTML utilisé pour cette intégration :

```html
<!-- IFRAME (application Shiny) -->
<div id="shinyContainer" style="display:none; margin-top:30px;">
  <iframe
    id="shinyFrame"
    src=""
    style="width: 100%; height: 700px;"
  ></iframe>
</div>
```
- **`div#shinyContainer`** : Conteneur qui enveloppe l'iframe. Il est initialement caché (`display: none`) et s'affiche lorsqu'une application Shiny est sélectionnée.
- **`iframe#shinyFrame`** : Élément iframe où l'application Shiny est chargée. La source (`src`) est définie dynamiquement via JavaScript en fonction de la sélection de l'utilisateur.

### Script JavaScript

Le fichier `main.js` gère l'interaction entre les sélections de l'utilisateur et le chargement des applications Shiny. Voici les parties clés du script :

```javascript
// Mapping des groupes d'indices aux URLs Shiny correspondantes
const shinyURLs = {
  "Taux de Malaria": "https://papaamad.shinyapps.io/SES_Shiny/",
  "Indices spectraux": "https://papaamad.shinyapps.io/SES_Shiny_Spectral/",
  "Événements dangereux": "https://papaamad.shinyapps.io/SES_Shiny_event/"
};

// Fonction pour construire l'URL Shiny et l'afficher dans l'iframe
function showShinyApp() {
  const paysVal  = countrySelect.value;
  const statVal  = indexSelect.value; 

  // Trouver le groupe auquel appartient l'option sélectionnée
  const selectedOption = indexSelect.options[indexSelect.selectedIndex];
  const optgroup = selectedOption.parentElement;
  const groupLabel = optgroup.label;

  // Déterminer la base URL en fonction du groupe
  let baseURL = "";
  if (shinyURLs.hasOwnProperty(groupLabel)) {
    baseURL = shinyURLs[groupLabel];
  } else {
    console.error("Groupe d'indice non reconnu :", groupLabel);
    shinyContainer.style.display = 'none';
    return;
  }

  // Construire la query string
  const queryString = `?pays=${encodeURIComponent(paysVal)}`
                    + `&stat=${encodeURIComponent(statVal)}`;

  const finalURL = baseURL + queryString;

  // Mettre à jour la source de l'iframe
  shinyFrame.src = finalURL;

  // Afficher le conteneur
  shinyContainer.style.display = 'block';
}
```
Un objet `shinyURLs` associe chaque groupe d'indices à son URL Shiny correspondante.

**Fonction `showShinyApp`** :
- **Récupération des valeurs sélectionnées** : Le pays et l'indice sélectionnés par l'utilisateur.
- **Identification du groupe d'indice** : Détermine à quel groupe appartient l'indice sélectionné.
- **Construction de l'URL finale** : Combine la base URL du groupe avec les paramètres de requête (`pays` et `stat`) pour personnaliser l'application Shiny.
- **Mise à jour de l'iframe** : Définit la source de l'iframe avec l'URL construite et affiche le conteneur.

### Lecture et Extraction des Paramètres URL dans Shiny

Les applications Shiny intégrées à la plateforme sont conçues pour lire et extraire les paramètres de l'URL afin de personnaliser les visualisations en fonction des sélections de l'utilisateur. Voici comment cela est implémenté côté Shiny :

#### Code R dans l'Application Shiny

```r
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

# C) Extraire 'stat' depuis les paramètres de l'URL
selected_stat <- reactive({
  stat <- query()$stat
  allowed_stats <- c("Mean", "Median", "Min", "Max", 
                     "Children_Malaria", "Children_Rate", "NDVI", "MNDWI", "BSI_1", "NDBI", "EVI", "event_type")
  if (is.null(stat) || !(stat %in% allowed_stats)) {
    # Valeur par défaut ou gestion d'erreur
    "Mean"
  } else {
    stat
  }
})

# Utilisation des paramètres extraits pour générer les visualisations
output$plot <- renderPlot({
  # Exemple d'utilisation des paramètres
  data <- getData(selected_pays(), selected_stat())
  plot(data)
})
```
- `parseQueryString(session$clientData$url_search)` : Cette fonction lit la chaîne de requête de l'URL et la parse en une liste de paramètres.
  
- `selected_pays` : Cette fonction réactive vérifie si le paramètre `pays` existe et s'il est valide (`"SEN"` ou `"BFA"`). Si non, une valeur par défaut `"SEN"` est utilisée.
  
- `selected_stat` : Cette fonction réactive vérifie si le paramètre `stat` existe et s'il fait partie des statistiques autorisées (`"Mean"`, `"Median"`, etc.). Si non, une valeur par défaut `"Mean"` est utilisée.

- Les valeurs extraites (`selected_pays()` et `selected_stat()`) sont utilisées pour charger les données appropriées et générer les visualisations correspondantes.

Cette approche permet aux applications Shiny de personnaliser dynamiquement leur contenu en fonction des paramètres passés dans l'URL, offrant ainsi une expérience utilisateur personnalisée et interactive.

### Exemples de Liens Shiny

Les applications Shiny sont accessibles via des URLs spécifiques, intégrant des paramètres de requête pour personnaliser l'affichage en fonction des sélections de l'utilisateur. Voici quelques exemples de liens générés :

1. **Taux de Malaria au Sénégal avec Taux Moyen** :
   ```
   https://papaamad.shinyapps.io/SES_Shiny/?pays=SEN&stat=Mean
   ```
   ![Image](https://github.com/PapaAmad/Plateforme-HEMA/blob/main/assets/img/image1.png)

2. **Indices Spectraux au Burkina Faso avec NDVI** :
   ```
   https://papaamad.shinyapps.io/SES_Shiny_Spectral/?pays=BFA&stat=NDVI
   ```
   ![Image](https://github.com/PapaAmad/Plateforme-HEMA/blob/main/assets/img/image2.png)

3. **Événements Dangereux au Sénégal avec Type d'Événements** :
   ```
   https://papaamad.shinyapps.io/SES_Shiny_event/?pays=SEN&stat=event_type
   ```
   ![Image](https://github.com/PapaAmad/Plateforme-HEMA/blob/main/assets/img/image3.png)

## Groupes d'Indices

### 1. Taux de Malaria

Le **Taux de Malaria** est une composante cruciale de la **Plateforme de Statistique Exploratoire Spatiale**, développée pour analyser et visualiser les indicateurs liés à la malaria au sein des régions administratives du **Sénégal** et du **Burkina Faso**. Cette documentation se concentre exclusivement sur les aspects computationnels et méthodologiques de l'application, détaillant les processus de chargement des données, de traitement, de calcul des indicateurs, ainsi que les critères de classification utilisés pour l'analyse des zones affectées par la malaria.

#### 1.1. Sources et Chargement des Données

##### 1.1.1. Shapefiles Administratifs

Les shapefiles définissent les limites administratives des pays étudiés à différents niveaux hiérarchiques. Ils sont essentiels pour l'agrégation et l'analyse spatiale des données de malaria.

- **Sénégal**
  - `adm0_SN` : Niveau administratif 0 (pays)
  - `adm1_SN` : Niveau administratif 1 (région)
  - `adm2_SN` : Niveau administratif 2 (département)
  - `adm3_SN` : Niveau administratif 3 (commune)

- **Burkina Faso**
  - `adm0_BFA` : Niveau administratif 0 (pays)
  - `adm1_BFA` : Niveau administratif 1 (région)
  - `adm2_BFA` : Niveau administratif 2 (province)
  - `adm3_BFA` : Niveau administratif 3 (district)

Les shapefiles sont chargés en utilisant la fonction `st_read` du package **sf**, permettant de lire les fichiers de formes géographiques et de les manipuler en tant qu'objets spatiaux dans R.

##### 1.1.2. Rasters de Malaria (2000-2022)

Les rasters représentent les données spatiales annuelles sur la malaria, capturées sous forme de fichiers TIFF pour chaque année de 2000 à 2022. Chaque raster contient une seule bande représentant l'intensité de la malaria.

- **Chemins des dossiers**
  - Sénégal : `data/Senegal/Rasters/Malaria`
  - Burkina Faso : `data/Burkina/Rasters/Malaria`

Les rasters sont chargés et empilés à l'aide des fonctions `rast` et `app` du package **terra**, permettant des opérations d'analyse spatiale sur l'ensemble de la période.

```r
# Chargement des rasters pour le Sénégal
fichiers_raster_SN  <- sort(list.files("data/Senegal/Rasters/Malaria", pattern = "\\.tiff$", full.names = TRUE))
rasters_SN_list <- lapply(fichiers_raster_SN, function(f) {
  rast(f)[[1]]  # Extraire la première couche de chaque raster
})
rasters_SN <- rast(rasters_SN_list)

# Chargement des rasters pour le Burkina Faso
fichiers_raster_BFA <- sort(list.files("data/Burkina/Rasters/Malaria", pattern = "\\.tiff$", full.names = TRUE))
rasters_BFA_list <- lapply(fichiers_raster_BFA, function(f) {
  rast(f)[[1]]  # Extraire la première couche de chaque raster
})
rasters_BFA <- rast(rasters_BFA_list)

# Réaffirmer le CRS après empilage
crs(rasters_SN) <- crs(adm0_SN)
crs(rasters_BFA) <- crs(adm0_BFA)

# Création du vecteur année
years_vec <- 2000:2022
```

##### 1.1.3. Rasters de Population (WorldPop)

Les rasters de population (WorldPop) fournissent des données démographiques nécessaires pour calculer les indicateurs d'enfants malades. Ces rasters sont agrégés pour correspondre à la résolution des rasters de malaria, facilitant ainsi les calculs de taux et de nombres d'enfants malades.

> [!NOTE]
> Les raster Worldpop ont été utilisés pour toutes les 23 années par soucis de manque de données.

```r
# Fonction pour agréger les rasters de population si nécessaire
aggregate_population <- function(country_code, worldpop_path, fact = 50) {
  message(paste("Agrégation du raster de population pour", country_code))
  WorldPop <- rast(worldpop_path)
  
  WorldPop_aggregated <- aggregate(WorldPop, fact = fact, fun = sum, na.rm = TRUE)
  WorldPop_children <- WorldPop_aggregated * 0.001  # Estimation des enfants (0.1%)
  return(WorldPop_children)
}

# Agrégation des rasters de population pour le Sénégal
WorldPop_SN_children <- aggregate_population(
  country_code = "SEN",
  worldpop_path = "data/Senegal/Rasters/WorldPop/worldpop_SN.tif",
  fact = 50
)

# Agrégation des rasters de population pour le Burkina Faso
WorldPop_BFA_children <- aggregate_population(
  country_code = "BFA",
  worldpop_path = "data/Burkina/Rasters/WorldPop/worldpop_BFA.tif",
  fact = 50
)
```

#### 1.2. Fonctions Utilitaires

L'application utilise plusieurs fonctions utilitaires pour le traitement et l'analyse des données spatiales.

##### 1.2.1. `extract_stat_per_admin`

Cette fonction extrait des statistiques agrégées (moyenne, médiane, etc.) pour chaque polygone administratif à partir des rasters de malaria.

```r
extract_stat_per_admin <- function(r, admin_sf, fun = "mean") {
  val <- exact_extract(r, admin_sf, fun)
  admin_sf[[paste0(fun, "_index")]] <- val
  return(admin_sf)
}
```

- **Paramètres** :
  - `r` : Raster contenant les données de malaria.
  - `admin_sf` : Shapefile administratif.
  - `fun` : Fonction statistique à appliquer (par défaut, la moyenne).

##### 1.2.2. `calc_stack_stat`

Calcule une statistique agrégée sur un stack de rasters.

```r
calc_stack_stat <- function(stack_obj, fun = mean) {
  terra::app(stack_obj, fun = fun, na.rm = TRUE)
}
```

- **Paramètres** :
  - `stack_obj` : Stack de rasters.
  - `fun` : Fonction statistique à appliquer (par défaut, la moyenne).

##### 1.2.3. `extract_timeseries_one_admin`

Extrait une série temporelle d'une statistique pour un polygone administratif spécifique.

```r
extract_timeseries_one_admin <- function(poly, stack_obj, fun = "mean") {
  val_list <- exact_extract(stack_obj, poly, fun)
  val_vec  <- unlist(val_list)
  return(val_vec)
}
```

- **Paramètres** :
  - `poly` : Polygone administratif sélectionné.
  - `stack_obj` : Stack de rasters.
  - `fun` : Fonction statistique à appliquer (par défaut, la moyenne).

##### 1.2.4. `calc_children_indicators`

Calcule les indicateurs d'enfants malades en fonction des rasters de malaria et de population.

```r
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
```

- **Paramètres** :
  - `admin_sf` : Shapefile administratif.
  - `selected_pays` : Code du pays sélectionné ("SEN" pour Sénégal, "BFA" pour Burkina Faso).

- **Processus** :
  1. Sélection du stack de rasters et des rasters de population en fonction du pays.
  2. Itération sur chaque année pour projeter et aligner les rasters de malaria avec les rasters de population.
  3. Calcul du nombre d'enfants malades en multipliant les valeurs de malaria par la population d'enfants.
  4. Extraction des valeurs par polygone administratif.
  5. Calcul des sommes et des taux d'enfants malades par polygone.

#### 1.3. Calcul des Indicateurs de Malaria

L'application calcule plusieurs indicateurs clés pour évaluer l'impact de la malaria au sein des régions administratives étudiées.

##### 1.3.1. Nombre d'Enfants Malades

Le nombre d'enfants malades est calculé en multipliant les valeurs du raster de malaria par les données de population agrégées (WorldPop_children). Cette multiplication permet d'estimer le nombre absolu d'enfants affectés par la malaria dans chaque polygone administratif.

```r
children_malaria_raster <- raster_aligned * WorldPop_children
```

##### 1.3.2. Taux d'Enfants Malades

Le taux d'enfants malades est obtenu en divisant le nombre d'enfants malades par la population totale d'enfants, puis en multipliant par 100 pour obtenir un pourcentage. Ce taux permet d'évaluer la prévalence de la malaria parmi les enfants dans chaque région.

```r
taux_malaria_mean = (children_malaria_mat / children_total_mat) * 100
```

#### 1.4. Classification des Zones de Malaria pour 2021

Pour une analyse approfondie, les zones sont classifiées en trois catégories basées sur l'intensité des cas de malaria pour l'année 2021 : **Aucun**, **Moyen** et **Grave**. Cette classification permet d'identifier les régions nécessitant des interventions prioritaires.

##### 1.4.1. Définition des Seuils de Classification

Les seuils de classification sont déterminés en fonction de la distribution statistique des données de malaria sur la période 2000-2022. Ils sont définis comme suit :

- **Seuil 1** : Moyenne + 1 écart-type
- **Seuil 2** : Moyenne + 2 écarts-types

Ces seuils permettent de segmenter les données en fonction de la gravité des cas de malaria, offrant une perspective claire sur les zones les plus affectées.

##### 1.4.2. Processus de Classification

1. **Calcul de la Moyenne et de l'Écart-Type**

   La moyenne (`moy_raster`) et l'écart-type (`ecrt_raster`) sont calculés sur l'ensemble du stack de rasters de malaria, fournissant une base statistique pour la classification.

   ```r
   moy_raster <- app(stack_data, fun = mean, na.rm = TRUE)
   ecrt_raster <- app(stack_data, fun = sd, na.rm = TRUE)
   ```

2. **Application des Seuils**

   Les seuils sont appliqués au raster de l'année 2021 pour classer chaque pixel selon les critères définis.

   ```r
   seuil1 <- moy_raster + ecrt_raster
   seuil2 <- moy_raster + 2 * ecrt_raster
   ```

3. **Création des Rasters Binaires**

   - **Aucun** : Pixels avec des valeurs de malaria inférieures ou égales à `seuil1`.
   - **Moyen** : Pixels avec des valeurs de malaria comprises entre `seuil1` et `seuil2`.
   - **Grave** : Pixels avec des valeurs de malaria supérieures ou égales à `seuil2`.

   ```r
   aucun <- (raster_2021 <= seuil1) * 1
   
   moyen <- (raster_2021 > seuil1) & (raster_2021 < seuil2)
   moyen <- (moyen * 1)
   
   grave <- (raster_2021 >= seuil2) * 1
   ```

   Ces rasters binaires sont ensuite intégrés dans une liste pour une utilisation ultérieure dans l'analyse des données.

### 2. Indices Spectraux

Les indices spectraux sont des indicateurs dérivés de l'analyse d'images satellites, utiles pour évaluer divers aspects environnementaux et urbains. Les indices disponibles incluent :

#### 2.1. NDVI (Indice de Végétation par Différence Normalisée)

L’indice de végétation par différence normalisée (NDVI) est un indicateur de la densité et de la santé de la végétation. Il est calculé à partir des bandes spectrales du proche infrarouge (NIR) et du rouge (RED) d’une image satellite (ici Copernicus).

**Calcul :**
```
NDVI = (NIR – RED) / (NIR + RED)
```

1. **NIR (Near Infrared – Infrarouge Proche)**
   - Le proche infrarouge est une bande spectrale captée par les satellites.
   - Les plantes saines réfléchissent fortement la lumière dans cette bande en raison de la structure interne de leurs feuilles.
   - Un NIR élevé indique généralement une végétation dense et en bonne santé.

2. **RED (Rouge)**
   - Il s’agit de la bande du spectre visible correspondant à la lumière rouge.
   - Les plantes absorbent fortement cette lumière pour réaliser la photosynthèse.
   - Un RED faible correspond à une végétation saine, car plus de lumière rouge est absorbée.

3. **Numérateur : (NIR – RED)**
   - La différence entre NIR et RED est essentielle pour quantifier le contraste entre la réflexion dans l’infrarouge et l’absorption dans le rouge.
   - Plus cette différence est grande, plus la végétation est dense et vigoureuse.

4. **Dénominateur : (NIR + RED)**
   - Cette somme permet de normaliser les valeurs pour éviter que les variations dues aux conditions d’éclairage ou aux caractéristiques des sols n’influencent les résultats.
   - Cela garantit que le NDVI reste compris entre -1 et +1.

**Avantages :**
- **Évaluation de la santé de la végétation** : Le NDVI permet d’estimer la densité chlorophyllienne et la vitalité des plantes, utile pour surveiller les cultures ou les forêts.
- **Suivi des changements environnementaux** : Il aide à détecter les zones de déforestation ou les effets de la sécheresse.
- **Planification agricole** : Il offre des informations cruciales pour optimiser l’utilisation des terres agricoles et anticiper les récoltes.

#### 2.2. MNDWI (Indice de Différence Normalisée d'Eau Modifié)

L’indice de différence normalisée d'eau modifié (MNDWI) est utilisé pour détecter les zones couvertes par l’eau et est particulièrement efficace pour différencier les surfaces aquatiques des sols ou de la végétation. Il est calculé en utilisant les bandes du vert (GREEN) et du moyen infrarouge (SWIR).

**Calcul :**
```
MNDWI = (GREEN – SWIR) / (GREEN + SWIR)
```

1. **GREEN (Vert)**
   - Correspond à la bande spectrale du vert visible captée par les satellites.
   - L’eau réfléchit fortement dans cette bande, ce qui permet de la distinguer plus facilement des autres surfaces comme les sols nus ou la végétation.

2. **SWIR (Shortwave Infrared – Infrarouge à Ondes Courtes)**
   - Il s’agit de la bande infrarouge à ondes courtes, qui est absorbée par l’eau.
   - Les surfaces non aquatiques (comme les sols secs ou urbains) réfléchissent fortement dans cette bande, tandis que l’eau a une réflexion très faible.

3. **Numérateur : (GREEN – SWIR)**
   - Cette différence met en évidence les surfaces où la réflexion est plus forte dans le vert et plus faible dans l’infrarouge à ondes courtes, typique des zones d’eau.
   - Un résultat élevé indique des zones probablement couvertes par de l’eau.

4. **Dénominateur : (GREEN + SWIR)**
   - La somme sert à normaliser les valeurs, rendant l’indice robuste face aux variations de conditions d’éclairage ou de capteurs.
   - Cela garantit que l’indice reste compris entre -1 et +1.

**Avantages :**
- **Détection des surfaces aquatiques** : Permet d’identifier efficacement les plans d’eau, les rivières, et les zones humides.
- **Surveillance des ressources en eau** : Utile pour la gestion et la planification des ressources hydriques.
- **Gestion des inondations** : Aide à cartographier et à surveiller les zones inondées en temps réel.

#### 2.3. BSI_1 (Indice de Stabilité du Sol)

L’indice de stabilité du sol (BSI_1) mesure les caractéristiques du sol en fonction de sa teneur en matières organiques et de son exposition. Il est calculé à partir des bandes du rouge (RED), du proche infrarouge (NIR), du bleu (BLUE) et du moyen infrarouge (SWIR) d’une image satellite de Copernicus. Cet indice a été dérivé en exploitant les capacités de Google Earth Engine. Une fois les données téléchargées, elles ont été regroupées par division administrative afin d’en tirer des informations locales pertinentes.

**Calcul :**
```
BSI_1 = [(SWIR + RED) – (NIR + BLUE)] / [(SWIR + RED) + (NIR + BLUE)]
```

1. **SWIR (Shortwave Infrared – Infrarouge à Ondes Courtes)**
   - Cette bande spectrale est sensible à l’humidité des sols.
   - Les sols nus ou dégradés réfléchissent fortement dans cette bande, contrairement aux zones végétalisées.

2. **RED (Rouge)**
   - Cette bande est liée à l’absorption de la lumière par la végétation.
   - Un niveau élevé de réflexion dans le rouge est souvent associé à des sols dénudés ou à une végétation clairsemée.

3. **NIR (Near Infrared – Infrarouge Proche)**
   - Le NIR est fortement réfléchi par les surfaces végétalisées et peu par les sols nus.
   - Une faible valeur de NIR est typique des sols exposés.

4. **BLUE (Bleu)**
   - Cette bande spectrale est influencée par la réflexion des surfaces claires, comme les sols secs ou sableux.

5. **Numérateur : (SWIR + RED) – (NIR + BLUE)**
   - Cette différence met en évidence les zones où la réflexion est plus forte dans le SWIR et le RED (typiques des sols dégradés ou nus) et plus faible dans le NIR et le BLUE.
   - Des valeurs positives indiquent généralement des sols nus ou des surfaces instables.

6. **Dénominateur : (SWIR + RED) + (NIR + BLUE)**
   - La somme permet de normaliser les valeurs, garantissant que l’indice varie entre -1 et +1.
   - Cela rend l’indice robuste face aux variations d’éclairage ou de capteurs.

**Avantages :**
- **Analyse des sols dénudés** : Le BSI_1 identifie les sols exposés, permettant de surveiller l’érosion et les risques de dégradation des terres.
- **Aménagement du territoire** : Il aide à identifier les zones vulnérables nécessitant des interventions pour stabiliser les sols.
- **Suivi des changements environnementaux** : Il permet de surveiller l’impact des activités humaines sur la stabilité des sols (urbanisation, agriculture intensive).

#### 2.4. NDBI (Indice de Développement Urbain par Différence Normalisée)

L’indice de développement urbain par différence normalisée (NDBI) permet d’identifier les zones urbanisées. Il est basé sur les bandes du moyen infrarouge (SWIR) et du proche infrarouge (NIR) et est calculé selon la formule suivante :

**Calcul :**
```
NDBI = (SWIR – NIR) / (SWIR + NIR)
```

1. **Numérateur : (SWIR – NIR)**
   - La différence met en évidence les zones où la réflexion est plus forte dans le SWIR (zones construites) et plus faible dans le NIR (absence de végétation).
   - Des valeurs positives indiquent généralement des zones urbaines ou bâties.

2. **Dénominateur : (SWIR + NIR)**
   - La somme sert à normaliser l’indice, permettant de le limiter entre -1 et +1.

**Avantages :**
- **Identification des zones urbaines** : Permet de cartographier et de surveiller l’expansion urbaine.
- **Planification urbaine** : Aide les urbanistes à prendre des décisions éclairées sur le développement des infrastructures.
- **Surveillance des changements urbains** : Facilite le suivi des transformations urbaines au fil du temps.

#### 2.5. EVI (Indice Amélioré de Végétation)

L’indice amélioré de végétation (EVI) est utilisé pour une évaluation précise de la végétation, en tenant compte des corrections liées à l’effet de l’atmosphère et des sols. Cet indice a été calculé sur Google Earth Engine à partir d’une image du satellite Copernicus et téléchargé sous forme de données spatiales. Les résultats ont été agrégés par division administrative pour l’analyse des conditions de végétation.

**Calcul :**
```
EVI = G * (NIR – RED) / (NIR + C1 * RED – C2 * BLUE + L)
```

1. **G (Gain)**
   - Le facteur de gain (2.5) amplifie les contrastes dans l’indice pour mieux différencier les zones végétalisées des zones non végétalisées.

2. **C1 * RED et C2 * BLUE**
   - Ces termes corrigent les effets atmosphériques qui pourraient fausser les valeurs du NIR et du RED, garantissant une mesure plus précise.

3. **L (Facteur de Correction du Sol)**
   - Facteur de correction du sol (valeur de 1) pour minimiser l’influence des sols exposés dans les zones où la végétation est clairsemée.

**Avantages :**
- **Précision accrue sur la végétation** : L’EVI corrige les effets atmosphériques et les interférences des sols, fournissant une estimation plus fiable de la santé végétale.
- **Suivi des écosystèmes** : Il est particulièrement adapté pour surveiller les forêts tropicales et les zones densément végétalisées.
- **Aide à la gestion agricole** : Il permet de mieux comprendre les conditions de croissance des cultures, améliorant ainsi la gestion agricole.

### 3. Événements Dangereux

Ce groupe d'indices se concentre sur les événements potentiellement dangereux affectant les régions étudiées. Les indicateurs disponibles incluent :

- **Type d'Événements** : Classification des différents types d'événements dangereux.
- **Nombre d'Événements** : Comptage total des événements recensés.

Ces indicateurs permettent de suivre et d'analyser la fréquence et la répartition des événements dangereux, contribuant ainsi à la gestion des risques et à la planification des interventions.

## Documentation sur les Événements

La base de données utilisée contient un total de **87 223 événements** enregistrés. Parmi eux, **12 489 événements** concernent le couple de pays (Sénégal, Burkina Faso).

### 1. Résumé des Données par Niveau Administratif

L'application génère un résumé statistique des événements en fonction du niveau administratif sélectionné par l'utilisateur.

**Procédure de résumé :**
1. Identification de la colonne correspondant au niveau administratif choisi (pays, région, département, commune).
2. Agrégation des événements par type et par niveau administratif.
3. Calcul du nombre total d'événements pour chaque entité administrative.
4. Tri des résultats pour afficher les zones les plus touchées en premier.

### 2. Analyse Temporelle des Événements

L'application génère une visualisation des tendances temporelles pour suivre l'évolution des événements au fil du temps.

**Procédure d'analyse temporelle :**
1. Regroupement des événements par année.
2. Décompte du nombre total d'événements pour chaque année.
3. Affichage d’une série chronologique montrant l'évolution des événements.
4. Ajout de points et d'une courbe pour visualiser les tendances.

### 3. Présentation de la Base de Données Utilisée

Cette base de données regroupe des informations sur différents événements qui se sont déroulés dans seize (16) pays dont le Sénégal et le Burkina Faso. Les différents événements qui figurent dans la base de données sont les suivants : violences à distance, affrontements, développements stratégiques, émeutes, protestations et violences contre les civils. Tous ces événements sont présents au Sénégal et au Burkina Faso.

Les troubles enregistrés dans cette base sont regroupés en trois grandes catégories :
- **Violences Politiques**
- **Développements Stratégiques**
- **Manifestations**

### 4. Avantages des Indicateurs Calculés

#### 4.1. Nombre d'Événements

L’affichage du nombre d'événements permet entre autres :

- **Identification des zones à risque** : Cela permet aux utilisateurs de repérer facilement les niveaux administratifs où se concentrent le plus grand nombre d'événements.
- **Surveillance des tendances locales** : Cela permet de suivre le nombre d'événements au fil du temps dans une zone spécifique et de détecter des tendances.

#### 4.2. Types d'Événements

L’affichage du type d'événements pour un niveau administratif choisi permet :

- **Identification des défis spécifiques** : Cela permet de comprendre les problèmes particuliers auxquels fait face le niveau administratif choisi.
- **Identification des acteurs impliqués** : Les types d'événements peuvent révéler des informations importantes sur les groupes en activité dans une zone, comme des groupes rebelles, des manifestants ou des forces de sécurité.

## Sources de Données

Les données utilisées proviennent principalement de la plateforme Google Earth Engine et des données partagées par M. Aboubacar HEMA.

## Contribution

Ce projet est le fruit du travail collectif des élèves :

- [**Papa Amadou NIANG**](https://github.com/PapaAmad/)
- [**Mame Balla BOUSSO**](https://github.com/MameBallaBousso)
- [**Ameth FAYE**](https://github.com/ameth08faye)
- [**Edima BIYENDA HILEDEGARDE**](https://github.com/HildaEDIMA)

Vous pourrez trouver dans [**ce dépôt GitHub central**](https://github.com/Abson-dev/Statistique-Exploratoire-Spatiale/tree/main/Projet) le travail des autres groupes.

---

*Ce README a été conçu pour fournir une vue d'ensemble complète de la Plateforme de Statistique Exploratoire Spatiale, incluant des détails techniques sur l'intégration des applications Shiny, des exemples de liens, ainsi que des informations détaillées sur les groupes d'indices, la documentation des événements et les sources de données.*