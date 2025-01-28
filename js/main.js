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
    description: "L’indice de végétation par différence normalisée (NDVI) est un indicateur de la densité et de la santé de la végétation. Il est calculé à partir des bandes spectrales du proche infrarouge (NIR) et du rouge (RED) d’une image satellite (ici Copernicus).",
    advantages: [
      "Évaluation de la santé de la végétation : Le NDVI permet d’estimer la densité chlorophyllienne et la vitalité des plantes, utile pour surveiller les cultures ou les forêts.1",
      "Suivi des changements environnementaux : Il aide à détecter les zones de déforestation ou les effets de la sécheresse.",
      "Planification agricole : Il offre des informations cruciales pour optimiser l’utilisation des terres agricoles et anticiper les récoltes."
    ]
  },
  MNDWI: {
    description: "L’indice de différence normalisée d’eau modifié (MNDWI) est utilisé pour détecter les zones couvertes par l’eau et est particulièrement efficace pour différencier les surfaces aquatiques des sols ou de la végétation. Il est calculé en utilisant les bandes du vert (GREEN) et du moyen infrarouge (SWIR).",
    advantages: [
      "Détection précise des étendues d'eau : Le MNDWI améliore la distinction entre l'eau et d'autres surfaces comme la végétation ou les sols nus, réduisant ainsi les erreurs de classification.",
      "Cartographie des ressources hydriques : Il permet de créer des cartes détaillées des plans d'eau, utiles pour la gestion des ressources en eau et la planification urbaine.",
      "Surveillance des inondations et des changements hydrologiques : Le MNDWI est efficace pour détecter les zones inondées et suivre les variations des niveaux d'eau au fil du temps.",
    ]
  },
  BSI_1: {
    description: "L’indice de stabilité du sol (BSI_1) mesure les caractéristiques du sol en fonction de sa teneur en matières organiques et de son exposition. Il est calculé à partir des bandes du rouge (RED), du proche infrarouge (NIR), du bleu (BLUE) et du moyen infrarouge (SWIR) d’une image satellite de Copernicus.",
    advantages: [
      "Analyse des sols dénudés : Le BSI_1 identifie les sols exposés, permettant de surveiller l’érosion et les risques de dégradation des terres.",
      "Aménagement du territoire : Il aide à identifier les zones vulnérables nécessitant des interventions pour stabiliser les sols.",
      "Suivi des changements environnementaux : Il permet de surveiller l’impact des activités humaines sur la stabilité des sols (urbanisation, agriculture intensive)."
    ]
  },
  NDBI: {
    description: "L’indice de développement urbain par différence normalisée (NDBI) permet d’identifier les zones urbanisées. Il est basé sur les bandes du moyen infrarouge (SWIR) et du proche infrarouge (NIR).",
    advantages: [
      "Détection précise des zones urbaines grâce aux bandes SWIR et NIR",
      "Compatibilité avec diverses données satellitaires pour une large application",
      "Outil efficace pour le suivi et la planification de l'expansion urbaine"
    ]
  },
  EVI: {
    description: "L’indice amélioré de végétation (EVI) est utilisé pour une évaluation précise de la végétation, en tenant compte des corrections liées à l’effet de l’atmosphère et des sols.",
    advantages: [
      "Précision accrue sur la végétation : L’EVI corrige les effets atmosphériques et les interférences des sols, fournissant une estimation plus fiable de la santé végétale.",
      "Suivi des écosystèmes : Il est particulièrement adapté pour surveiller les forêts tropicales et les zones densément végétalisées.",
      "Aide à la gestion agricole : Il permet de mieux comprendre les conditions de croissance des cultures, améliorant ainsi la gestion agricole."
    ]
  },
  event_type: {
    description: "Cet indicateur permet de visualiser entre autres les types d'événement depuis 1997. Vous pourrez suivre l'évolution de la carte dans les différents onglets.",
    advantages: [
      "Une identification des défis spécifiques auxquels fait face le niveau administratif choisi.",
      "Une identification des acteurs impliqués : les types d'événements peuvent révéler des informations importantes sur les groupes en activité dans une zone, comme des groupes rebelles, des manifestants, ou des forces de sécurité."
    ]
  },
  event_count: {
    description: "Cet indicateur permet de visualiser entre autres le nombre d'évenement politique ainsi que d'autres événements à caractère dangereux depuis 1997. Vous pourrez suivre l'évolution de la carte dans les différents onglets.",
    advantages: [
      "Une identification des zones à risque : cela permet aux utilisateurs de repérer facilement les niveaux administratifs où se concentrent le plus grand nombre d’événements. ",
      "Une surveillance des tendances locales : cela permet de suivre le nombre d'événements au fil du temps dans une zone spécifique et permet de détecter des tendances."
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
