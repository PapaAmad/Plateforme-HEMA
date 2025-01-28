/* main.js */

// Éléments HTML
const countrySelect  = document.getElementById('countrySelect');
const indexSelect    = document.getElementById('indexSelect');
const indexSelection = document.querySelector('.index-selection');
const indexInfo      = document.getElementById('indexInfo');
const indexDesc      = document.getElementById('indexDescription');
const indexAdv       = document.getElementById('indexAdvantages');
const shinyContainer = document.getElementById('shinyContainer');
const shinyFrame     = document.getElementById('shinyFrame');

// Descriptions par indice
const indexDescriptions = {
  Mean: {
    description: "Le taux moyen de malaria représente la moyenne arithmétique des valeurs observées entre 2000 et 2022 pour chaque niveau administratif. Il fournit une vue d'ensemble du niveau moyen sur toute la période. Cliquer sur un polygone pour visualiser l'évolution temporelle des valeurs de 2000 à 2022, offrant ainsi une perspective plus détaillée.",
    advantages: [
      "Permet une compréhension rapide des tendances globales",
      "Utile pour comparer les niveaux moyens entre différentes régions",
      "Facilement interprétable pour des analyses générales"
    ]
  },
  Median: {
    description: "Le taux médian de malaria représente la valeur centrale qui divise les données en deux parties égales lorsqu'elles sont triées. Cliquer sur un polygone pour visualiser l'évolution temporelle des valeurs de 2000 à 2022, permettant une meilleure compréhension de la distribution au fil du temps.",
    advantages: [
      "Robuste face aux valeurs aberrantes",
      "Reflète efficacement la tendance centrale",
      "Utile pour comprendre la répartition des valeurs"
    ]
  },
  Min: {
    description: "Le taux minimal de malaria représente la mesure la plus basse observée entre 2000 et 2022 pour chaque niveau administratif. Elle sert à identifier les conditions extrêmes inférieures. Cliquer sur un polygone pour explorer les valeurs minimales au fil du temps et voir leur évolution entre 2000 et 2022.",
    advantages: [
      "Met en évidence les valeurs limites les plus faibles",
      "Facile à interpréter pour les analyses de seuil",
      "Utile pour repérer les périodes ou zones de faibles valeurs"
    ]
  },
  Max: {
    description: "Le taux maximal de malaria représente la mesure la plus élevée observée entre 2000 et 2022 pour chaque niveau administratif. Elle indique les conditions extrêmes supérieures. Cliquer sur un polygone pour explorer les valeurs maximales et suivre leur évolution temporelle de 2000 à 2022.",
    advantages: [
      "Permet d'identifier les valeurs les plus élevées atteintes",
      "Facile à comprendre pour les analyses des pics",
      "Utile pour mettre en évidence les périodes ou zones de performances maximales"
    ]
  },
  Children_Malaria: {
    description: "Le nombre d'enfants malades représente le total des cas recensés entre 2000 et 2022 pour chaque niveau administratif. Cet indice permet d'évaluer la charge absolue de la maladie sur une région donnée. Cliquer sur un polygone pour visualiser l'évolution temporelle du nombre d'enfants malades entre 2000 et 2022, offrant une perspective dynamique de la situation.",
    advantages: [
      "Permet de mesurer directement la gravité et l'ampleur de l'impact",
      "Facile à interpréter pour quantifier les cas",
      "Utile pour cibler les régions nécessitant des interventions prioritaires"
    ]
  },
  Children_Rate: {
    description: "Le taux d'enfants malades représente la proportion des enfants touchés par rapport à la population totale d'enfants entre 2000 et 2022 pour chaque niveau administratif. Il fournit une mesure standardisée pour comparer les régions. Cliquer sur un polygone pour explorer l'évolution temporelle du taux d'enfants malades de 2000 à 2022, permettant une analyse approfondie des tendances.",
    advantages: [
      "Facilite la comparaison entre les zones indépendamment de la taille de leur population",
      "Indique les régions avec des proportions élevées d'enfants malades",
      "Utile pour identifier les disparités sanitaires entre les régions"
    ]
  },  
  NDVI: {
    description: "Description for NDVI...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  MNDWI: {
    description: "Description for MNDWI...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  BSI_1: {
    description: "Description for BSI_1...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  NDBI: {
    description: "Description for NDBI...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  EVI: {
    description: "Description for EVI...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  event_type: {
    description: "Description for event_type...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  },
  event_count: {
    description: "Description for event_count...",
    advantages: [
      "Advantage 1",
      "Advantage 2",
      "Advantage 3"
    ]
  }
};

// Mapping des groupes d'indices aux URLs Shiny correspondantes
const shinyURLs = {
  "Taux de malaria": "https://papaamad.shinyapps.io/SES_Shiny/",
  "Indices spectraux": "https://papaamad.shinyapps.io/SES_Shiny_Spectral/",
  "Evenements dangereux": "https://papaamad.shinyapps.io/SES_Shiny_event/"
};

// 1) Choix du pays
countrySelect.addEventListener('change', function () {
  if (this.value) {
    // On affiche la box index-selection (par défaut, display:none dans le CSS)
    indexSelection.style.display = 'block';

    // On active le select index
    indexSelect.disabled = false;

    // On peut reset l'indice
    indexSelect.value = indexSelect.options[0].value;
    indexInfo.style.display = 'none';
    shinyContainer.style.display = 'none';

    // Petit effet slideIn
    indexSelection.style.animation = 'slideIn 0.5s ease-out';
  } else {
    // Pas de pays => on cache
    indexSelection.style.display = 'none';
    indexSelect.disabled = true;
    indexInfo.style.display = 'none';
    shinyContainer.style.display = 'none';
  }
});

// 2) Choix de l'indice
indexSelect.addEventListener('change', function () {
  if (this.value && countrySelect.value) {
    // Afficher "About this Index"
    const info = indexDescriptions[this.value];
    if (info) {
      indexDesc.textContent = info.description;
      indexAdv.innerHTML = info.advantages
        .map(a => `<li>${a}</li>`)
        .join('');
      indexInfo.style.display = 'block';
    } else {
      indexInfo.style.display = 'none';
    }
    // Afficher l'iframe Shiny
    showShinyApp();
  } else {
    indexInfo.style.display = 'none';
    shinyContainer.style.display = 'none';
  }
});

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
