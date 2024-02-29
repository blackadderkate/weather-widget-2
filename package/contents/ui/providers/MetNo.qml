import QtQuick 2.15
import "../../code/model-utils.js" as ModelUtils
import "../../code/data-loader.js" as DataLoader
import "../../code/unit-utils.js" as UnitUtils

Item {
    id: metno




    property var locale: Qt.locale()
    property string providerId: 'metno'
    property string urlPrefix: 'https://api.met.no/weatherapi/locationforecast/2.0/compact?'
    property string forecastPrefix: 'https://www.yr.no/en/forecast/daily-table/'

    property bool weatherDataFlag: false
    property bool sunRiseSetFlag: false

    function getCreditLabel(placeIdentifier) {
        return i18n("Weather forecast data provided by The Norwegian Meteorological Institute.")
    }

    function extLongLat(placeIdentifier) {
        dbgprint(placeIdentifier)
        return placeIdentifier.substr(placeIdentifier.indexOf("lat=" ) + 4,placeIdentifier.indexOf("&lon=")-4) + "," +
        placeIdentifier.substr(placeIdentifier.indexOf("&lon=") + 5,placeIdentifier.indexOf("&altitude=") - placeIdentifier.indexOf("&lon=") - 5)
    }

    function getCreditLink(placeIdentifier) {
        return forecastPrefix + extLongLat(placeIdentifier)
    }

    function parseDate(dateString) {
        return new Date(dateString + '.000Z')
    }

    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        main.debugLogging = 1
        dbgprint2("loadDataFromInternet" + currentPlace.alias)

        var placeIdentifier = locationObject.placeIdentifier

        function successWeather(jsonString) {
            var readingsArray = JSON.parse(jsonString)
            updatecurrentWeather(readingsArray)
            updateNextDaysModel(readingsArray)
            buildMetogramData(readingsArray)
            refreshTooltipSubText()
            loadCompleted()
        }

        function parseISOString(s) {
            var b = s.split(/\D+/)
            return new Date(Date.UTC(b[0], --b[1], b[2], b[3], b[4], b[5], b[6]))
        }

        function updatecurrentWeather(readingsArray) {
            dbgprint2("Build Current Weather")

            var currentWeather = readingsArray.properties.timeseries[0]
            var futureWeather = readingsArray.properties.timeseries[1]
            currentWeatherModel.iconName = geticonNumber(currentWeather.data.next_1_hours.summary.symbol_code)
            currentWeatherModel.windDirection = currentWeather.data.instant.details["wind_from_direction"]
            currentWeatherModel.windSpeedMps = currentWeather.data.instant.details["wind_speed"]
            currentWeatherModel.pressureHpa = currentWeather.data.instant.details["air_pressure_at_sea_level"]
            currentWeatherModel.humidity = currentWeather.data.instant.details["relative_humidity"]
            currentWeatherModel.cloudiness = currentWeather.data.instant.details["cloud_area_fraction"]
            currentWeatherModel.temperature = currentWeather.data.instant.details["air_temperature"]
            currentWeatherModel.nearFutureWeather.temperature = futureWeather.data.instant.details["air_temperature"]
            currentWeatherModel.nearFutureWeather.iconName = geticonNumber(futureWeather.data.next_1_hours.summary.symbol_code)

            let sunRise = UnitUtils.convertDate(currentWeatherModel.sunRise,2,currentPlace.timezoneOffset)
            let sunSet = UnitUtils.convertDate(currentWeatherModel.sunSet,2,currentPlace.timezoneOffset)
            let updated = UnitUtils.convertDate(new Date(readingsArray.properties.timeseries[0].time) , 2 , currentPlace.timezoneOffset)

            dbgprint("Updated=" + readingsArray.properties.timeseries[0].time + "\t" + currentWeatherModel.sunRise + "\t" + currentWeatherModel.sunSet)
            dbgprint("Updated=" + updated/1000 + "\t" + sunRise/1000 + "\t" + sunSet/1000)
            dbgprint("Updated=" + updated/1000 + "\t" + (updated > sunRise) + "\t" + (updated < sunSet))
            currentWeatherModel.isDay = ((updated > sunRise) && (updated < sunSet)) ? 0 : 1

            dbgprint(JSON.stringify(currentWeatherModel))
        }

        function createDate(t) {
            let arr = t.split(":")
            return Date.parse(new Date(1970, 1, 1, arr[0], arr[1], 0))/1000
        }

        function updateNextDaysModel(readingsArray) {
            main.debugLogging = 0
            dbgprint2("updateNextDaysModel")
            nextDaysModel.clear()

            function blankObject() {
                const myblankObject = {}
                for(let f = 0; f < 4; f++) {
                    myblankObject["temperature" + f] = -999
                    myblankObject["iconName" + f] = ""
                    myblankObject['hidden' + f] = true
                }
                return myblankObject
            }

            let offset = 0
            switch (main.timezoneType) {
                case (0):
                    offset = dataSource.data["Local"]["timezoneOffset"]
                    break;
                case (1):
                    offset = 0
                    break;
                case (2):
                    offset = currentPlace.timezoneOffset
                    break;
            }

            let wd = readingsArray.properties.timeseries
            let wdPtr = 0
            var localTime =  UnitUtils.convertDate(new Date(wd[wdPtr].time), 2, currentPlace.timezoneOffset)
            var displayTime = UnitUtils.convertDate(new Date(wd[wdPtr].time), main.timezoneType, offset)
            while ((wdPtr < wd.length) && ((displayTime.getHours() - 3) % 6 ) != 0) {

                wdPtr++
                displayTime = UnitUtils.convertDate(new Date(wd[wdPtr].time), main.timezoneType, offset)
            }
            let x = 0
            let y = 0
            let nextDaysData = blankObject()
            let airTemp = -999

            var sunrise1 = UnitUtils.convertDate(currentWeatherModel.sunRise,2,currentPlace.timezoneOffset)
            var sunset1 = UnitUtils.convertDate(currentWeatherModel.sunSet,2,currentPlace.timezoneOffset)
            dbgprint("**********************")
            dbgprint(sunrise1 + "\t" + sunset1)
            var ss = Date.parse(sunset1) / 1000
            var sr = Date.parse(sunrise1) / 1000

            while (wd[wdPtr].data.next_1_hours !== undefined) {
                localTime = UnitUtils.convertDate(new Date(wd[wdPtr].time), 2, currentPlace.timezoneOffset)
                displayTime = UnitUtils.convertDate(new Date(wd[wdPtr].time), main.timezoneType, offset)
                let lt = Date.parse(localTime) / 1000

                while (lt > (sr + 86400)) {
                    dbgprint("+")
                    sr = sr + 86400
                    ss = ss + 86400
                }
                if (displayTime.getHours() % 6 === 3) {
                    let isDayTime =  ((lt >= sr ) && (lt <= ss)) ? 0 : 1
                    y = Math.trunc(displayTime.getHours() / 6,0)
                    dbgprint("wdPtr:" + wdPtr + "\t" + wd[wdPtr].time + "\t x = " + x + "\t y = " + y)
                    dbgprint(isDayTime + "\t\t" + displayTime + "\t" + localTime+ "\t" + new Date(sr * 1000) + "\t" + new Date(ss * 1000) )
                    nextDaysData['dayTitle'] = composeNextDayTitle(displayTime)
                    nextDaysData['temperature' + y] = wd[wdPtr].data.instant.details["air_temperature"]
                    nextDaysData['hidden' + y] = false
                    let obj = wd[wdPtr].data.next_1_hours.summary["symbol_code"]
                    nextDaysData['iconName' + y] = geticonNumber(obj)
                    nextDaysData['partOfDay' + y] = isDayTime
                    if (y == 3) {
                        nextDaysModel.append(nextDaysData)
                        nextDaysData=blankObject()
                        x++
                    }

                }
                wdPtr++
            }

            while ((wdPtr < wd.length) && (wd[wdPtr].data.next_6_hours !== undefined))
            {
                let t = new Date(wd[wdPtr].time)
                t.setHours(t.getHours() + 3)
                localTime = UnitUtils.convertDate(t, 2, currentPlace.timezoneOffset)
                displayTime = UnitUtils.convertDate(t, main.timezoneType, offset)
                let lt = Date.parse(localTime) / 1000

                while (lt > (sr + 86400)) {
                    dbgprint("+")
                    sr = sr + 86400
                    ss = ss + 86400
                }
                dbgprint("****\t" + displayTime.getHours())
                {
                    let isDayTime =  ((lt >= sr ) && (lt <= ss)) ? 0 : 1
                    y = Math.trunc(displayTime.getHours() / 6,0)
                    dbgprint("wdPtr:" + wdPtr + "\t" + wd[wdPtr].time + "\t x = " + x + "\t y = " + y)
                    dbgprint(isDayTime + "\t\t" + displayTime + "\t" + localTime+ "\t" + new Date(sr * 1000) + "\t" + new Date(ss * 1000) )
                    dbgprint("\t\t" + displayTime + "\t" + lt+ "\t" + (sr) + "\t" + (ss) )
                    nextDaysData['dayTitle'] = composeNextDayTitle(displayTime)
                    nextDaysData['temperature' + y] = wd[wdPtr].data.instant.details["air_temperature"]
                    nextDaysData['hidden' + y] = false
                    let obj = wd[wdPtr].data.next_6_hours.summary["symbol_code"]
                    nextDaysData['iconName' + y] = geticonNumber(obj)
                    nextDaysData['partOfDay' + y] = isDayTime
                    if (y == 3) {
                        nextDaysModel.append(nextDaysData)
                        nextDaysData=blankObject()
                        x++
                    }
                }
                wdPtr++
            }
            if ((y < 3) && (x < 8)) {
                nextDaysModel.append(nextDaysData)
            }
            dbgprint("nextDaysModel Count:" + nextDaysModel.count)
            main.debugLogging = 0
        }

        function buildMetogramData(readingsArray) {
            main.debugLogging = 0
            dbgprint2("buildMetogramData (MetNo)" + currentPlace.identifier)
            meteogramModel.clear()
            var readingsLength = (readingsArray.properties.timeseries.length)
            var dateFrom = parseISOString(readingsArray.properties.timeseries[0].time)
            var sunrise1 = UnitUtils.convertDate(currentWeatherModel.sunRise,2,currentPlace.timezoneOffset)
            var sunset1 = UnitUtils.convertDate(currentWeatherModel.sunSet,2,currentPlace.timezoneOffset)
            dbgprint("Sunrise \t(GMT)" + new Date(currentWeatherModel.sunRise).toTimeString() + "\t(LOCAL)" + sunrise1.toTimeString())
            dbgprint("Sunset \t(GMT)" + new Date(currentWeatherModel.sunSet).toTimeString() + "\t(LOCAL)" + sunset1.toTimeString())
            var isDaytime = (dateFrom > sunrise1) && (dateFrom < sunset1)

            var precipitation_unit = readingsArray.properties.meta.units["precipitation_amount"]
            var counter = 0
            var i = 1
            while (readingsArray.properties.timeseries[i].data.next_1_hours) {
                var obj = readingsArray.properties.timeseries[i]
                var dateTo = parseISOString(obj.time)
                var wd = obj.data.instant.details["wind_from_direction"]
                var ws = obj.data.instant.details["wind_speed"]
                var ap = obj.data.instant.details["air_pressure_at_sea_level"]
                var airtmp = parseFloat(obj.data.instant.details["air_temperature"])
                var icon = obj.data.next_1_hours.summary["symbol_code"]
                var prec = obj.data.next_1_hours.details["precipitation_amount"]
                counter = (prec > 0) ? counter + 1 : 0
                let localtimestamp = UnitUtils.convertDate(dateFrom, 2 , currentPlace.timezoneOffset)
                if (localtimestamp >= sunrise1) {
                    if (localtimestamp < sunset1) {
                        isDaytime = true
                    } else {
                        sunrise1.setDate(sunrise1.getDate() + 1)
                        sunset1.setDate(sunset1.getDate() + 1)
                        isDaytime = false
                    }
                }
                dbgprint("DateFrom=" + dateFrom.toISOString() + "\tLocal Time=" + UnitUtils.convertDate(dateFrom,2,currentPlace.timezoneOffset).toTimeString() + "\t Sunrise=" + sunrise1.toTimeString() + "\tSunset=" + sunset1.toTimeString() + "\t" + (isDaytime ? "isDay\n" : "isNight\n"))
                meteogramModel.append({
                    from: dateFrom,
                    to: dateTo,
                    isDaytime: isDaytime,
                    temperature: parseFloat(airtmp),
                                      precipitationAvg: parseFloat(prec),
                                      precipitationMax: parseFloat(prec),
                                      precipitationLabel: (counter === 1) ? "mm" : "",
                                      windDirection: parseFloat(wd),
                                      windSpeedMps: parseFloat(ws),
                                      pressureHpa: parseFloat(ap),
                                      iconName: geticonNumber(icon)
                })
                dateFrom = dateTo
                i++
            }
            main.loadingDataComplete = true
            main.debugLogging = 0
        }

        function formatTime(ISOdate) {
            return ISOdate.substr(11,5)
        }

        function formatDate(ISOdate) {
            return ISOdate.substr(0,10)
        }

        function composeNextDayTitle(date) {
            return Qt.locale().dayName(date.getDay(), Locale.ShortFormat) + ' ' + date.getDate() + '/' + (date.getMonth() + 1)
        }

        function successSRAS(jsonString) {
            main.debugLogging = 0
            dbgprint2("successSRAS")
            var readingsArray = JSON.parse(jsonString)
            dbgprint("Sunrise:" + JSON.stringify(readingsArray.properties.sunrise))
            let offset = 0
            switch (main.timezoneType) {
                case (0):
                    offset = dataSource.data["Local"]["timezoneOffset"]
                    break;
                case (1):
                    offset = 0
                    break;
                case (2):
                    offset = currentPlace.timezoneOffset
                    break;
            }

            if ((readingsArray.properties !== undefined)) {
                currentWeatherModel.sunRise = new Date(readingsArray.properties.sunrise.time)
                currentWeatherModel.sunSet = new Date(readingsArray.properties.sunset.time)

                currentWeatherModel.sunRiseTime = UnitUtils.convertDate(currentWeatherModel.sunRise, main.timezoneType, offset).toTimeString()
                currentWeatherModel.sunSetTime = UnitUtils.convertDate(currentWeatherModel.sunSet, main.timezoneType, offset).toTimeString()
            }
            dbgprint(JSON.stringify(currentWeatherModel))
            sunRiseSetFlag = true
            var weatherURL = urlPrefix + placeIdentifier
            if (! useOnlineWeatherData) {
                weatherURL = Qt.resolvedUrl('../../code/weather/weather.json')
            }
            dbgprint("Downloading Weather Data from: " + weatherURL)
            main.debugLogging = 0
            var xhr2 = DataLoader.fetchJsonFromInternet(weatherURL, successWeather, failureCallback)
        }

        function failureCallback() {
            dbgprint("DOH!")
            currentWeatherModel = emptyWeatherModel()
            // loadingData.loadingDatainProgress=false
            main.loadingDataComplete = true
        }

        function loadCompleted() {
            successCallback()
        }

        function calculateOffset(seconds) {
            let hrs = String("0" + Math.floor(Math.abs(seconds) / 3600)).slice(-2)
            let mins = String("0" + (seconds % 3600)).slice(-2)
            let sign = (seconds >= 0) ? "+" : "-"
            return(sign + hrs + ":" + mins)
        }

        weatherDataFlag = false
        sunRiseSetFlag = false
        var TZURL = ""

        if (currentPlace.timezoneID === -1) {
            console.log("[weatherWidget] Timezone Data not available - using sunrise-sunset.org API")
            TZURL = "https://api.sunrise-sunset.org/json?formatted=0&" + placeIdentifier
        } else {
            dbgprint("Timezone Data is available - using met.no API")

            TZURL = 'https://api.met.no/weatherapi/sunrise/3.0/sun?' + placeIdentifier.replace(/&altitude=[^&]+/,"") + "&date=" + formatDate(new Date().toISOString())
//            TZURL += "&offset=" + calculateOffset(currentPlace.timezoneOffset)
        }
        if (! useOnlineWeatherData) {
            TZURL = Qt.resolvedUrl('../../code/weather/sun.json')
        }
        dbgprint("Downloading Sunrise / Sunset Data from: " + TZURL)
        main.debugLogging = 0
        var xhr1 = DataLoader.fetchJsonFromInternet(TZURL, successSRAS, failureCallback)
        return [xhr1]
    }

    function reloadMeteogramImage(placeIdentifier) {
        main.overviewImageSource = ""
    }

    function geticonNumber(text) {
        var codes = {
            "clearsky":    "1",
            "cloudy":    "4",
            "fair":    "2",
            "fog":    "15",
            "heavyrain":    "10",
            "heavyrainandthunder":    "11",
            "heavyrainshowers":    "41",
            "heavyrainshowersandthunder":    "25",
            "heavysleet":    "48",
            "heavysleetandthunder":    "32",
            "heavysleetshowers":    "43",
            "heavysleetshowersandthunder":    "27",
            "heavysnow":    "50",
            "heavysnowandthunder":    "34",
            "heavysnowshowers":    "45",
            "heavysnowshowersandthunder":    "29",
            "lightrain":    "46",
            "lightrainandthunder":    "30",
            "lightrainshowers":    "40",
            "lightrainshowersandthunder":    "24",
            "lightsleet":    "47",
            "lightsleetandthunder":    "31",
            "lightsleetshowers":    "42",
            "lightsnow":    "49",
            "lightsnowandthunder":    "33",
            "lightsnowshowers":    "44",
            "lightssleetshowersandthunder":    "26",
            "lightssnowshowersandthunder":    "28",
            "partlycloudy":    "3",
            "rain":    "9",
            "rainandthunder":    "22",
            "rainshowers":    "5",
            "rainshowersandthunder":    "6",
            "sleet":    "12",
            "sleetandthunder":    "23",
            "sleetshowers":    "7",
            "sleetshowersandthunder":    "20",
            "snow":    "13",
            "snowandthunder":    "14",
            "snowshowers":    "8",
            "snowshowersandthunder":    "21"
        }
        var underscore = text.indexOf("_")
        if (underscore > -1) {
            text = text.substr(0,underscore)
        }
        var num = codes[text]
        return num
    }

    function windDirection(bearing) {
        var Directions = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW','N']
        var brg = Math.round((bearing + 11.25) / 22.5)
        return(Directions[brg])
    }
}
