var map = L.map('map').setView([20, 0], 2);

L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap contributors'
}).addTo(map);

const countrySelect = document.getElementById('countrySelect');
const indexSelect = document.getElementById('indexSelect');
const indexSelection = document.querySelector('.index-selection');
const mapElement = document.getElementById('map');

countrySelect.addEventListener('change', function() {
    if (this.value) {
        indexSelection.style.display = 'block';
        indexSelect.disabled = false;
        indexSelect.value = indexSelect.options[0].value; 
        mapElement.style.display = 'none'; 
    } else {
        indexSelection.style.display = 'none';
        indexSelect.disabled = true;
        mapElement.style.display = 'none';
    }
});

indexSelect.addEventListener('change', function() {
    if (this.value && countrySelect.value) {
        mapElement.style.display = 'block';
        updateMap();
    }
});

function updateMap() {
    var country = countrySelect.value;
    var index = indexSelect.value;

    map.eachLayer((layer) => {
        if (layer instanceof L.Marker) {
            map.removeLayer(layer);
        }
    });

    const countryData = {
        france: { lat: 46.2276, lng: 2.2137 },
        germany: { lat: 51.1657, lng: 10.4515 },
        usa: { lat: 37.0902, lng: -95.7129 }
    };

    const selectedCountry = countryData[country];
    
    if (selectedCountry) {
        map.setView([selectedCountry.lat, selectedCountry.lng], 5);
        L.marker([selectedCountry.lat, selectedCountry.lng])
            .addTo(map)
            .bindPopup(`<b>${country.charAt(0).toUpperCase() + country.slice(1)}</b><br>${index}`)
            .openPopup();
    }
    
    setTimeout(() => {
        map.invalidateSize();
    }, 100);
}