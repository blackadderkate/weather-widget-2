function getWindDirectionIconCode(angle) {
    const iconCodes = ['\uf060', '\uf05e', '\uf061', '\uf05b', '\uf05c', '\uf05a', '\uf059', '\uf05d']
    let n = Math.round((angle + 22.5) / 45) - 1
    var iconCode = iconCodes[n]
    if (!iconCode) {
        iconCode = '\uf073'
    }
    return iconCode
}

var WeatherFont = {

    // https://erikflowers.github.io/weather-icons/
    codeByName: {
        'wi-day-sunny': '\uf00d',
        'wi-night-clear': '\uf02e',
        'wi-day-sunny-overcast': '\uf00c',
        'wi-night-partly-cloudy': '\uf083',
        'wi-day-cloudy': '\uf002',
        'wi-night-cloudy': '\uf031',
        'wi-cloudy': '\uf013',
        'wi-day-showers': '\uf009',
        'wi-night-showers': '\uf037',
        'wi-day-storm-showers': '\uf00e',
        'wi-night-storm-showers': '\uf03a',
        'wi-day-rain-mix': '\uf006',
        'wi-night-rain-mix': '\uf034',
        'wi-day-snow': '\uf00a',
        'wi-night-snow': '\uf038',
        'wi-showers': '\uf01a',
        'wi-rain': '\uf019',
        'wi-thunderstorm': '\uf01e',
        'wi-rain-mix': '\uf017',
        'wi-snow': '\uf01b',
        'wi-day-snow-thunderstorm': '\uf06b',
        'wi-night-snow-thunderstorm': '\uf06c',
        'wi-dust': '\uf063',
        'wi-day-sleet-storm': '\uf068',
        'wi-night-sleet-storm': '\uf069',
        'wi-storm-showers': '\uf01d',
        'wi-day-sprinkle': '\uf00b',
        'wi-night-sprinkle': '\uf039',
        'wi-day-thunderstorm': '\uf010',
        'wi-night-thunderstorm': '\uf03b',
        'wi-sprinkle': '\uf01c',
        'wi-day-rain': '\uf008',
        'wi-night-rain': '\uf036',
        'wi-lightning': '\uf016',
        'wi-sleet': '\uf0b5',
        'wi-fog': '\uf014',
        'wi-smoke': '\uf062',
        'wi-volcano': '\uf0c8',
        'wi-strong-wind': '\uf050',
        'wi-tornado': '\uf056',
        'wi-windy': '\uf021',
        'wi-hurricane': '\uf073',
        'wi-snowflake-cold': '\uf076',
        'wi-hot': '\uf072',
        'wi-hail': '\uf015',
        'wi-sunset': '\uf052'
    },

    iconNameByYrNoCode: {
        '1':  ['wi-day-sunny', 'wi-night-clear'],
        '2':  ['wi-day-sunny-overcast', 'wi-night-partly-cloudy'],
        '3':  ['wi-day-cloudy', 'wi-night-cloudy'],
        '4':  ['wi-cloudy', 'wi-cloudy'],
        '5':  ['wi-day-showers', 'wi-night-showers'],
        '6':  ['wi-day-storm-showers', 'wi-night-storm-showers'],
        '7':  ['wi-day-rain-mix', 'wi-night-rain-mix'],
        '8':  ['wi-day-snow', 'wi-night-snow'],
        '9':  ['wi-showers', 'wi-showers'],
        '10': ['wi-rain', 'wi-rain'],
        '11': ['wi-thunderstorm', 'wi-thunderstorm'],
        '12': ['wi-rain-mix', 'wi-rain-mix'],
        '13': ['wi-snow', 'wi-snow'],
        '14': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'], //TODO no icon in fonts! using SnowSunThunder
        '15': ['wi-dust', 'wi-dust'],
        '20': ['wi-day-sleet-storm', 'wi-night-sleet-storm'],
        '21': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'],
        '22': ['wi-storm-showers', 'wi-storm-showers'],
        '23': ['wi-storm-showers', 'wi-storm-showers'], //TODO used LightRainThunder
        '24': ['wi-day-sprinkle', 'wi-night-sprinkle'], //TODO used DrizzleSun
        '25': ['wi-day-thunderstorm', 'wi-night-thunderstorm'],
        '26': ['wi-day-sleet-storm', 'wi-night-sleet-storm'], //TODO used SleetSunThunder
        '27': ['wi-day-sleet-storm', 'wi-night-sleet-storm'], //TODO used SleetSunThunder
        '28': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'], //TODO no icon in fonts! using SnowSunThunder
        '29': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'], //TODO no icon in fonts! using SnowSunThunder
        '30': ['wi-sprinkle', 'wi-sprinkle'], //TODO used Drizzle
        '31': ['wi-storm-showers', 'wi-storm-showers'], //TODO used LightRainThunder
        '32': ['wi-storm-showers', 'wi-storm-showers'], //TODO used LightRainThunder
        '33': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'], //TODO no icon in fonts! using SnowSunThunder
        '34': ['wi-day-snow-thunderstorm', 'wi-night-snow-thunderstorm'], //TODO no icon in fonts! using SnowSunThunder
        '40': ['wi-day-sprinkle', 'wi-night-sprinkle'],
        '41': ['wi-day-rain', 'wi-night-rain'],
        '42': ['wi-day-rain-mix', 'wi-night-rain-mix'], //TODO used SleetSun
        '43': ['wi-day-rain-mix', 'wi-night-rain-mix'], //TODO used SleetSun
        '44': ['wi-day-snow', 'wi-night-snow'], //TODO used SnowSun
        '45': ['wi-day-snow', 'wi-night-snow'], //TODO used SnowSun
        '46': ['wi-sprinkle', 'wi-sprinkle'],
        '47': ['wi-rain-mix', 'wi-rain-mix'], //TODO same as Sleet for now
        '48': ['wi-rain-mix', 'wi-rain-mix'], //TODO same as Sleet for now
        '49': ['wi-snow', 'wi-snow'], //TODO used Snow
        '50': ['wi-snow', 'wi-snow']  //TODO used Snow
    },

    // http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes
    iconNameByOwmCode: {
        '200': ['wi-storm-showers', 'wi-storm-showers'],
        '201': ['wi-thunderstorm', 'wi-thunderstorm'],
        '202': ['wi-storm-showers', 'wi-storm-showers'],
        '210': ['wi-lightning', 'wi-lightning'],
        '211': ['wi-lightning', 'wi-lightning'],
        '212': ['wi-lightning', 'wi-lightning'],
        '221': ['wi-lightning', 'wi-lightning'],
        '230': ['wi-storm-showers', 'wi-storm-showers'],
        '231': ['wi-storm-showers', 'wi-storm-showers'],
        '232': ['wi-storm-showers', 'wi-storm-showers'],

        '300': ['wi-sprinkle', 'wi-sprinkle'],
        '301': ['wi-sprinkle', 'wi-sprinkle'],
        '302': ['wi-sprinkle', 'wi-sprinkle'],
        '310': ['wi-sprinkle', 'wi-sprinkle'],
        '311': ['wi-sprinkle', 'wi-sprinkle'],
        '312': ['wi-sprinkle', 'wi-sprinkle'],
        '313': ['wi-sprinkle', 'wi-sprinkle'],
        '314': ['wi-sprinkle', 'wi-sprinkle'],
        '321': ['wi-sprinkle', 'wi-sprinkle'],

        '500': ['wi-showers', 'wi-showers'],
        '501': ['wi-rain', 'wi-rain'],
        '502': ['wi-rain', 'wi-rain'],
        '503': ['wi-rain', 'wi-rain'],
        '504': ['wi-rain', 'wi-rain'],
        '511': ['wi-rain', 'wi-rain'],
        '520': ['wi-rain', 'wi-rain'],
        '521': ['wi-rain', 'wi-rain'],
        '522': ['wi-rain', 'wi-rain'],
        '531': ['wi-rain', 'wi-rain'],

        '600': ['wi-snow', 'wi-snow'],
        '601': ['wi-snow', 'wi-snow'],
        '602': ['wi-snow', 'wi-snow'],
        '611': ['wi-sleet', 'wi-sleet'],
        '612': ['wi-sleet', 'wi-sleet'],
        '615': ['wi-rain-mix', 'wi-rain-mix'],
        '616': ['wi-rain-mix', 'wi-rain-mix'],
        '620': ['wi-rain-mix', 'wi-rain-mix'],
        '621': ['wi-rain-mix', 'wi-rain-mix'],
        '622': ['wi-rain-mix', 'wi-rain-mix'],

        '701': ['wi-fog', 'wi-fog'],
        '711': ['wi-smoke', 'wi-smoke'],
        '721': ['wi-fog', 'wi-fog'],
        '731': ['wi-dust', 'wi-dust'],
        '741': ['wi-fog', 'wi-fog'],
        '751': ['wi-dust', 'wi-dust'],
        '761': ['wi-dust', 'wi-dust'],
        '762': ['wi-volcano', 'wi-volcano'],
        '771': ['wi-strong-wind', 'wi-strong-wind'],
        '781': ['wi-tornado', 'wi-tornado'],

        '800': ['wi-day-sunny', 'wi-night-clear'],
        '801': ['wi-day-sunny-overcast', 'wi-night-partly-cloudy'],
        '802': ['wi-day-cloudy', 'wi-night-cloudy'],
        '803': ['wi-cloudy', 'wi-cloudy'],
        '804': ['wi-cloudy', 'wi-cloudy'],

        '900': ['wi-tornado', 'wi-tornado'],
        '901': ['wi-windy', 'wi-windy'],
        '902': ['wi-hurricane', 'wi-hurricane'],
        '903': ['wi-snowflake-cold', 'wi-snowflake-cold'],
        '904': ['wi-hot', 'wi-hot'],
        '905': ['wi-windy', 'wi-windy'],
        '906': ['wi-hail', 'wi-hail'],

        // TODO better understand and fill proper icons
        '950': ['wi-sunset', 'wi-sunset'],
        '951': ['wi-day-sunny', 'wi-night-clear'],
        '952': ['wi-windy', 'wi-windy'],
        '953': ['wi-windy', 'wi-windy'],
        '954': ['wi-windy', 'wi-windy'],
        '955': ['wi-windy', 'wi-windy'],
        '956': ['wi-windy', 'wi-windy'],
        '957': ['wi-windy', 'wi-windy'],
        '958': ['wi-windy', 'wi-windy'],
        '959': ['wi-windy', 'wi-windy'],
        '960': ['wi-windy', 'wi-windy'],
        '961': ['wi-windy', 'wi-windy'],
        '962': ['wi-windy', 'wi-windy']
    }
}

function getIconCode(iconName, providerId, partOfDay) {
    var iconCodeParts = null
    if (providerId === 'yrno') {
        iconCodeParts = WeatherFont.iconNameByYrNoCode[iconName]
    } else if (providerId === 'owm') {
        iconCodeParts = WeatherFont.iconNameByOwmCode[iconName]
    } else if (providerId === 'metno') {
        iconCodeParts = WeatherFont.iconNameByYrNoCode[iconName]
    }
    if (!iconCodeParts) {
        return '\uf07b'
    }
    return WeatherFont.codeByName[iconCodeParts[partOfDay]]
}

function getSunriseIcon() {
    return '\uf052'
}

function getSunsetIcon() {
    return '\uf051'
}
