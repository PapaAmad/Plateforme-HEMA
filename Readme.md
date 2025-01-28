# Plateforme de Statistique Exploratoire Spatiale

Bienvenue sur la **Plateforme de Statistique Exploratoire Spatiale**, développée dans le cadre du cours de Statistique Exploratoire Spatiale à l'École Nationale de la Statistique et de l'Analyse Économique Pierre NDIAYE de Dakar.

![Image de la Plateforme](assets\img\image_plateforme.png)

## Table des Matières

1. [Introduction](#introduction)
2. [Accès à la Plateforme et aux Applications Shiny](#accès-à-la-plateforme-et-aux-applications-shiny)
3. [Intégration des Applications Shiny](#intégration-des-applications-shiny)
    - [Structure HTML](#structure-html)
    - [Script JavaScript](#script-javascript)
    - [Lecture et Extraction des Paramètres URL dans Shiny](#lecture-et-extraction-des-paramètres-url-dans-shiny)
    - [Exemples de Liens Shiny](#exemples-de-liens-shiny)
4. [Groupes d'Indices](#groupes-dindices)
5. [Sources de Données](#sources-de-données)
6. [Contribution](#contribution)
7. [Contact](#contact)

## Introduction

Cette plateforme web présente un résumé des indicateurs statistiques spatiaux calculés au niveau administratif pour le **Sénégal** et le **Burkina Faso**. Elle offre une visualisation interactive des indicateurs tels que le taux de malaria, les indices spectraux comme le NDVI, ainsi que des indicateurs liés aux événements dangereux.

L'objectif principal de ce projet est de rassembler et de présenter tous les travaux pratiques (TP) réalisés lors du cours dispensé par [**M. Aboubacar HEMA**](https://github.com/). Vous trouverez l'ensemble de ces TP dans ce dépôt GitHub, offrant ainsi une ressource complète pour les étudiants et les chercheurs intéressés par l'analyse spatiale des données statistiques.

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
  "Taux de malaria": "https://papaamad.shinyapps.io/SES_Shiny/",
  "Indices spectraux": "https://papaamad.shinyapps.io/SES_Shiny_Spectral/",
  "Evenements dangereux": "https://papaamad.shinyapps.io/SES_Shiny_event/"
};

// 3) Fonction pour construire l'URL Shiny et l'afficher dans l'iframe
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
                       "Children_Malaria", "Children_Rate")
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

2. **Indices Spectraux au Burkina Faso avec NDVI** :
   ```
   https://papaamad.shinyapps.io/SES_Shiny_Spectral/?pays=BFA&stat=NDVI
   ```

3. **Événements Dangereux au Sénégal avec Type d'Événements** :
   ```
   https://papaamad.shinyapps.io/SES_Shiny_event/?pays=SEN&stat=event_type
   ```

**Explications :**

- **Paramètres de Requête** :
  - `pays` : Code du pays sélectionné (`SEN` pour Sénégal, `BFA` pour Burkina Faso).
  - `stat` : Indice ou statistique sélectionnée (par exemple, `Mean` pour le taux moyen de malaria).

Ces liens permettent de personnaliser les applications Shiny en fonction des choix de l'utilisateur, offrant ainsi une expérience interactive et adaptée.

## Groupes d'Indices

### 1. Taux de Malaria

Les indicateurs relatifs au taux de malaria fournissent des informations cruciales sur l'impact de cette maladie au niveau administratif. Les indices disponibles incluent :

- **Taux Moyen (2000 à 2022)** : Moyenne arithmétique des valeurs observées.
- **Taux Médian (2000 à 2022)** : Valeur centrale divisant les données en deux parties égales.
- **Taux Minimal (2000 à 2022)** : Mesure la plus basse observée.
- **Taux Maximal (2000 à 2022)** : Mesure la plus élevée observée.
- **Nombre d'Enfants Malades (2000 à 2022)** : Total des cas recensés.
- **Taux d'Enfants Malades (2000 à 2022)** : Proportion des enfants touchés par rapport à la population totale.

Ces indicateurs permettent d'évaluer la charge de la malaria et d'identifier les tendances et les zones les plus affectées.

### 2. Indices Spectraux

Les indices spectraux sont des indicateurs dérivés de l'analyse d'images satellites, utiles pour évaluer divers aspects environnementaux et urbains. Les indices disponibles incluent :

- **NDVI (2023)** : Indice de végétation par différence normalisée.
- **MNDWI (2023)** : Indice de différence normalisée d'eau modifié.
- **BSI_1 (2023)** : Indice de stabilité du sol.
- **NDBI (2023)** : Indice de développement urbain par différence normalisée.
- **EVI (2023)** : Indice amélioré de végétation.

Ces indices facilitent l'analyse de la couverture terrestre, de l'urbanisation et des ressources en eau.

### 3. Événements Dangereux

Ce groupe d'indices se concentre sur les événements potentiellement dangereux affectant les régions étudiées. Les indicateurs disponibles incluent :

- **Type d'Événements** : Classification des différents types d'événements dangereux.
- **Nombre d'Événements** : Comptage total des événements recensés.

Ces indicateurs permettent de suivre et d'analyser la fréquence et la répartition des événements dangereux, contribuant ainsi à la gestion des risques et à la planification des interventions.

## Sources de Données

Les données utilisées pour alimenter cette plateforme proviennent de diverses sources fiables, assurant la qualité et la pertinence des analyses. Voici un aperçu des principales sources de données :

- **Ministère de la Santé** : Données sur les taux et le nombre de cas de malaria.
- **Agence Spatiale** : Images satellites pour le calcul des indices spectraux.
- **Office National des Statistiques** : Données démographiques et administratives.
- **Bases de Données Climatiques** : Informations sur les événements météorologiques et autres phénomènes naturels dangereux.

Toutes les données utilisées sont mises à jour régulièrement pour garantir l'actualité des analyses et des visualisations proposées sur la plateforme.

## Contribution

Ce projet est le fruit du travail collectif des étudiants du cours de Statistique Exploratoire Spatiale sous la supervision de **M. Aboubacar HEMA**. Les contributions sous forme de rapports de TP, de codes et de visualisations peuvent être effectuées via ce dépôt GitHub. N'hésitez pas à soumettre des issues ou des pull requests pour améliorer la plateforme.

## Licence

Ce projet est sous licence [MIT](LICENSE).

## Contact

Pour toute question ou suggestion, veuillez contacter :

- **Nom** : [Votre Nom]
- **Email** : [votre.email@example.com]
- **GitHub** : [https://github.com/PapaAmad/Plateforme-HEMA](https://github.com/PapaAmad/Plateforme-HEMA)

---

*Ce README a été conçu pour fournir une vue d'ensemble complète de la Plateforme de Statistique Exploratoire Spatiale, incluant des détails techniques sur l'intégration des applications Shiny, des exemples de liens, ainsi que des informations sur les groupes d'indices et les sources de données.*

# Licence

Ce projet est sous licence [MIT](LICENSE).

# Contact

Pour toute question ou suggestion, veuillez contacter :

- **Nom** : [Votre Nom]
- **Email** : [votre.email@example.com]
- **GitHub** : [https://github.com/PapaAmad/Plateforme-HEMA](https://github.com/PapaAmad/Plateforme-HEMA)

---

*Ce README a été conçu pour fournir une vue d'ensemble complète de la Plateforme de Statistique Exploratoire Spatiale, incluant des détails techniques sur l'intégration des applications Shiny, des exemples de liens, ainsi que des informations sur les groupes d'indices et les sources de données.*


## All GitHub Alert Types

> [!NOTE]
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.

## Installation

```bash
# Installer 
npm install --global @pan