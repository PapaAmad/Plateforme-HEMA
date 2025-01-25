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
    description: "The mean is the arithmetic average of the observed values...",
    advantages: [
      "Simple to interpret",
      "Commonly used statistic",
      "Good for overall level"
    ]
  },
  Median: {
    description: "The median is the middle value that divides the data in half...",
    advantages: [
      "Robust to outliers",
      "Reflects central tendency well"
    ]
  },
  Min: {
    description: "Minimum value indicates the lowest observed measure...",
    advantages: [
      "Shows boundary condition",
      "Simple to understand"
    ]
  },
  Max: {
    description: "Maximum value indicates the highest observed measure...",
    advantages: [
      "Shows extreme condition",
      "Easy to interpret"
    ]
  },
  Children_Malaria: {
    description: "Maximum value indicates the highest observed measure...",
    advantages: [
      "Shows extreme condition",
      "Easy to interpret"
    ]
  },
  Children_Rate: {
    description: "Maximum value indicates the highest observed measure...",
    advantages: [
      "Shows extreme condition",
      "Easy to interpret"
    ]
  }
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

  // Par exemple, on fixe display_type = aggregated_poly
  const displayType = 'aggregated_poly';

  // URL de base de votre app Shiny (à adapter)
  const baseURL = "https://papaamad.shinyapps.io/SES_Shiny/";

  // Construire la query string
  const queryString = `?pays=${encodeURIComponent(paysVal)}`
                    + `&stat=${encodeURIComponent(statVal)}`
                    + `&display_type=${encodeURIComponent(displayType)}`;

  const finalURL = baseURL + queryString;

  // Mettre à jour la source de l'iframe
  shinyFrame.src = finalURL;

  // Afficher le conteneur
  shinyContainer.style.display = 'block';
}

