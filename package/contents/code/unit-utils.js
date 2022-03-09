/*
 * TEMPERATURE
 */
var TemperatureType = {
    CELSIUS: 0,
    FAHRENHEIT: 1,
    KELVIN: 2
}

function toFahrenheit(celsia) {
    return celsia * (9 / 5) + 32
}

function toKelvin(celsia) {
    return celsia + 273.15
}

function getTemperatureNumberExt(temperatureStr, temperatureType) {
    return getTemperatureNumber(temperatureStr, temperatureType) + (temperatureType === TemperatureType.CELSIUS || temperatureType === TemperatureType.FAHRENHEIT ? '°' : '')
}

function getTemperatureNumber(temperatureStr, temperatureType) {
    var fl = parseFloat(temperatureStr)
    if (temperatureType === TemperatureType.FAHRENHEIT) {
        fl = toFahrenheit(fl)
    } else if (temperatureType === TemperatureType.KELVIN) {
        fl = toKelvin(fl)
    }
    return Math.round(fl)
}

function kelvinToCelsia(kelvin) {
    return kelvin - 273.15
}

function getTemperatureEnding(temperatureType) {
    if (temperatureType === TemperatureType.CELSIUS) {
        return i18n("°C")
    } else if (temperatureType === TemperatureType.FAHRENHEIT) {
        return i18n("°F")
    } else if (temperatureType === TemperatureType.KELVIN) {
        return i18n("K")
    }
    return ''
}

/*
 * PRESSURE
 */
var PressureType = {
    HPA: 0,
    INHG: 1,
    MMHG: 2
}

function getPressureNumber(hpa, pressureType) {
    if (pressureType === PressureType.INHG) {
        return Math.round(hpa * 0.0295299830714 * 10) / 10
    }
    if (pressureType === PressureType.MMHG) {
        return Math.round(hpa * 0.750061683)
    }
    return hpa
}

function getPressureText(hpa, pressureType) {
    return getPressureNumber(hpa, pressureType) + ' ' + getPressureEnding(pressureType)
}

function getPressureEnding(pressureType) {
    if (pressureType === PressureType.INHG) {
        return i18n("inHg")
    }
    if (pressureType === PressureType.MMHG) {
        return i18n("mmHg")
    }
    return i18n("hPa")
}

/*
 * WIND SPEED
 */
var WindSpeedType = {
    MPS: 0,
    MPH: 1,
    KMH: 2
}

function getWindSpeedNumber(mps, windSpeedType) {
    if (windSpeedType === WindSpeedType.MPH) {
        return Math.round(mps * 2.2369362920544 * 10) / 10
    } else if (windSpeedType === WindSpeedType.KMH) {
        return Math.round(mps * 3.6 * 10) / 10
    }
    return mps
}

function getWindSpeedText(mps, windSpeedType) {
    return getWindSpeedNumber(mps, windSpeedType) + ' ' + getWindSpeedEnding(windSpeedType)
}

function getWindSpeedEnding(windSpeedType) {
    if (windSpeedType === WindSpeedType.MPH) {
        return i18n("mph")
    } else if (windSpeedType === WindSpeedType.KMH) {
        return i18n("km/h")
    }
    return i18n("m/s")
}

function getHourText(hourNumber, twelveHourClockEnabled) {
    var result = hourNumber
    if (twelveHourClockEnabled) {
        if (hourNumber === 0) {
            result = 12
        } else {
            result = hourNumber > 12 ? hourNumber - 12 : hourNumber
        }
    }
    return result < 10 ? '0' + result : result
}

function getAmOrPm(hourNumber) {
    if (hourNumber === 0) {
        return 'AM'
    }
    return hourNumber > 11 ? 'PM' : 'AM'
}


/*
 * TIMEZONE
 */
var TimezoneType = {
    USER_LOCAL_TIME: 0,
    UTC: 1
}

function convertDate(date, timezoneType) {
    if (timezoneType === TimezoneType.UTC) {
        return new Date(date.getTime() + (date.getTimezoneOffset() * 60000))
    }
    return date
}
