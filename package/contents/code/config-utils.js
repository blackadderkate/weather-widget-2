function getPlacesArray() {
    var cfgPlaces = plasmoid.configuration.places
//     print('Reading places from configuration: ' + cfgPlaces)
    return JSON.parse(cfgPlaces)
}

function collapseZeroes(numStr) {
    if (numStr.indexOf('.') !== -1) {
        while (numStr.slice(-1) === '0') {
            numStr = numStr.slice(0, -1)
        }
        if (numStr.slice(-1) === '.') {
            numStr = numStr.slice(0, -1)
        }
    }
    return numStr
}

function metNoPlaceToData(placeIdentifier, collapse) {
    var placeFragments = placeIdentifier.split('&')
    var placeData = {}

    for (var i = 0; i < placeFragments.length; i++) {
        var fragment = placeFragments[i].split('=')
        if (fragment.length <= 1) {
            continue
        }

        fragment[1] = Number(fragment[1])
        if (!Number.isNaN(fragment[1])) {
            placeData[fragment[0]] = fragment[1].toFixed(fragment[0] === 'altitude' ? 0 : 4)
        } else {
            continue
        }

        if (collapse === undefined || collapse === true) {
            placeData[fragment[0]] = collapseZeroes(placeData[fragment[0]])
        }
    }

    return placeData
}

function metNoDataToPlace(placeData) {
    var placeIdentifier = ''
    var keys = Object.keys(placeData)

    for (var i = 0; i < keys.length; i++) {
        placeIdentifier += keys[i] + '=' + placeData[keys[i]] + '&'
    }

    return placeIdentifier.slice(0, -1)
}

function metNoRebuildPlace(placeIdentifier, collapse) {
    return metNoDataToPlace(metNoPlaceToData(placeIdentifier, collapse))
}
