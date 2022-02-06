function getPlacesArray() {
    var cfgPlaces = plasmoid.configuration.places
//     print('Reading places from configuration: ' + cfgPlaces)
    return JSON.parse(cfgPlaces)
}
