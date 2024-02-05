/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick
import QtQml.XmlListModel
import org.kde.plasma.plasma5support as Plasma5Support
import "../../code/model-utils.js" as ModelUtils
import "../../code/data-loader.js" as DataLoader
import "../../code/unit-utils.js" as UnitUtils

Item {
    id: owm

    property string providerId: 'owm'
    property string urlPrefix: 'http://api.openweathermap.org/data/2.5'
    property string appIdAndModeSuffix: '&units=metric&mode=xml&appid=5819a34c58f8f07bc282820ca08948f1'
    property int xmlModelCurrentStatus: xmlModelCurrent.status
    property int xmlModelLongTermStatus: xmlModelLongTerm.status
    property int xmlModelHourByHourStatus: xmlModelHourByHour.status
    property bool xmlModelComplete: (xmlModelCurrent.status === XmlListModel.Ready) && (xmlModelHourByHour.status === XmlListModel.Ready) && (xmlModelLongTerm.status  === XmlListModel.Ready)

    onXmlModelCompleteChanged: {
        if (xmlModelComplete == false) {
            return
        }
        getTimeZoneName()
        updatecurrentWeather()
        updateNextDaysModel()
        buildMetogramData()
        loadCompleted()
    }

    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        dbgprint2("OWM loadDataFromInternet")
        var loadedData = {
            current: null,
            hourByHour: null,
            longTerm: null
        }
        let url1 = ""
        let url2 = ""
        let url3 = ""

        var placeIdentifier = locationObject.placeIdentifier
        var versionParam = '&v=' + new Date().getTime()
        if (! useOnlineWeatherData) {
            url1 = Qt.resolvedUrl('../../code/weather/current.xml')
            url2 = Qt.resolvedUrl('../../code/weather/daily.xml')
            url3 = Qt.resolvedUrl('../../code/weather/forecast.xml')
        } else {

            url1 = urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
            url2 = urlPrefix + '/forecast/daily?id=' + placeIdentifier + '&cnt=8' + appIdAndModeSuffix + versionParam
            url3 = urlPrefix + '/forecast?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
        }
        main.debugLogging = 1
        dbgprint("xmlModelCurrent = " + url1)
        dbgprint("xmlModelLongTerm = " + url2)
        dbgprint("xmlModelHourByHour = " + url3)
        main.debugLogging = 0
        xmlModelCurrent.source = url1
        xmlModelLongTerm.source = url2
        xmlModelHourByHour.source = url3
    }

    function updatecurrentWeather() {
        dbgprint2('updatecurrentWeather')

        var now = new Date()
        dbgprint('now: ' + now)

        var tooOldCurrentDataLimit = new Date(now.getTime() - (2 * 60 * 60 * 1000))
        var nearFutureWeather = currentWeatherModel.nearFutureWeather
        let obj=xmlModelCurrent.get(0)
        let obj2=xmlModelHourByHour.get(1)
        currentWeatherModel.temperature = obj.temperature
        currentWeatherModel.iconName = obj.iconName
        currentWeatherModel.nearFutureWeather.iconName = obj2.iconName
        currentWeatherModel.nearFutureWeather.temperature = obj2.temperature
        currentWeatherModel.humidity = obj.humidity
        currentWeatherModel.pressureHpa = obj.pressureHpa
        currentWeatherModel.windSpeedMps = obj.windSpeedMps
        currentWeatherModel.windDirection = parseFloat(obj.windDirection)
        currentWeatherModel.cloudiness = obj.cloudiness
        currentWeatherModel.updated = obj.updated
        let sunRise = Date.parse(obj.rise)
        let sunSet = Date.parse(obj.set)
        let tz = parseInt(obj.timezoneOffset) * 1000
        currentPlace.timezoneOffset = tz
        currentWeatherModel.sunRise = new Date (sunRise)
        currentWeatherModel.sunSet= new Date (sunSet)
        currentWeatherModel.sunRiseTime = new Date (sunRise + tz).toTimeString()
        currentWeatherModel.sunSetTime = new Date (sunSet + tz).toTimeString()
        dbgprint2('EXIT updatecurrentWeather')
    }

    function updateNextDaysModel() {
        function blankObject() {
            const myblankObject={}
            for (let f = 0; f < 4; f++) {
                myblankObject["temperature" + f] = -999
                myblankObject["iconName" + f] = ''
                myblankObject['hidden' + f] = true

            }
            return myblankObject
        }

        main.debugLogging = 1
        dbgprint2("updateNextDaysModel")

        let updatedDateTime = xmlModelCurrent.get(0).updated
        let timezoneOffset = xmlModelCurrent.get(0).timezoneOffset

        let updatedDateTimeStamp = Date.parse(updatedDateTime)
        let updatedDateTimeStampLocal = convertToLocalTime(Date.parse(updatedDateTime),timezoneOffset * 1000)
        let hr = new Date(updatedDateTimeStampLocal).getHours()
        let y = parseInt((hr + 3) / 6)

        let dataTime = new Date(updatedDateTimeStampLocal)
        // dbgprint2(militaryGMTOffsetFromNumeric(tz1))
        dbgprint("XML Updated At:\t"+ updatedDateTime + "\t" + new Date(updatedDateTimeStamp) + "\t" + new Date(updatedDateTimeStampLocal))
        // dbgprint("XML Updated At:\t"+ t1 + "Z" + militaryGMTOffsetFromNumeric(tz1))
        // let t2 = Date.parse(t1 + "Z" + militaryGMTOffsetFromNumeric(tz1))
        // let t3 = new Date(t2)
        // dbgprint("XML Updated At:\t" + t3 + " (local)")
        // let timeArray = t1.split(/[T:-]/)
        // let hr = parseInt(timeArray[3])
        // let x = 0
        // let y = parseInt((hr + 3) / 6)
        let nextDaysData = blankObject()
        dbgprint2("HR = " + hr + "\tY = " + y)



        let ptr = 0
        dbgprint("*********************************************************************")
        dbgprint("Parsing Data starting at Row " + ptr + " of xmlModelLongTerm")

        while (ptr < xmlModelLongTerm.count) {
            let obj = xmlModelLongTerm.get(ptr)
            if (y === 0) {
                nextDaysData['temperature0'] = parseInt(obj.temperatureMorning)
                nextDaysData['iconName0'] = obj.iconName
                dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                nextDaysData['hidden0'] = false
                y++
            }
            if (y === 1) {
                nextDaysData['temperature1'] = parseInt(obj.temperatureDay)
                nextDaysData['iconName1'] = obj.iconName
                dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                nextDaysData['hidden1'] = false
                y++
            }
            if (y === 2) {
                nextDaysData['temperature2'] = parseInt(obj.temperatureEvening)
                nextDaysData['iconName2'] = obj.iconName
                dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                nextDaysData['hidden2'] = false
                y++
            }
            nextDaysData['temperature3'] = parseInt(obj.temperatureNight)
            nextDaysData['iconName3'] = obj.iconName
            dbgprint("Added data for Row " + (x + 1) + " Column 4")
            nextDaysData['hidden3'] = false
            nextDaysData['dayTitle'] =  composeNextDayTitle(dataTime)
            dataTime.setDate(dataTime.getDate() + 1)
            dbgprint("*** PUSHED ROW " + x + "\t" + nextDaysData['dayTitle'])

            nextDaysModel.append(nextDaysData)
            // for(const [key,value] of Object.entries(nextDaysData)) { console.log(`  ${key}: ${value}`) }

            x++
            y = 0
            nextDaysData = blankObject()
            ptr++
        }

/* Overwrite nextDaysModel with more accurate data from Daily XML Model where available */
        x = 0
        y = 0
        ptr = 0
        nextDaysData=blankObject()

        while (ptr < xmlModelHourByHour.count) {
            let obj = xmlModelHourByHour.get(ptr)
            let t = convertToLocalTime(obj.from, timezoneOffset * 1000)
            let h = 3 + (parseInt(t.getHours() / 6) * 6)
            y = parseInt(h / 6)
            dbgprint("GetHours=" + t.getHours() + "\th=" + h + "\ty=" +y)
            nextDaysData['dayTitle'] = composeNextDayTitle(t)
            nextDaysData['temperature' + y] = parseInt(obj.temperature)
            nextDaysData['hidden' + y] = false
            nextDaysData['iconName' + y] = obj.iconName
            if (y === 3) {
                dbgprint("*** Replaced ROW " + x + "\t" + nextDaysData['dayTitle'])
                nextDaysModel.remove(x,1)
                nextDaysModel.insert(x,nextDaysData)
                nextDaysData=blankObject()
                x++
                y = 0
            }
            ptr = ptr + 2
        }

        dbgprint("nextDaysModel Count:" + nextDaysModel.count)
        dbgprint2("EXIT updateNextDaysModel")
        main.debugLogging = 0
    }


    function buildMetogramData() {
        main.debugLogging = 0
        dbgprint2("buildMetogramData (OWM)" + currentPlace.identifier)

        meteogramModel.clear()

        var firstFromMs = null
        var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days
        var now = new Date(convertToLocalTime(xmlModelHourByHour.get(0).from, currentPlace.timezoneOffset))


        var dateFrom = now
        var dateTo = now
        var sunrise1 = (currentWeatherModel.sunRise)
        var sunset1 = (currentWeatherModel.sunSet)
        var isDaytime = (dateFrom > sunrise1) && (dateFrom < sunset1)
        // dbgprint("dateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))

        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var obj = xmlModelHourByHour.get(i)
            dateFrom = convertToLocalTime(obj.from, currentPlace.timezoneOffset)
            dateTo = convertToLocalTime(obj.to, currentPlace.timezoneOffset)
            // dbgprint("obj.from=" + obj.from + "\tobj.to=" + obj.to + "\tdateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))

            if (now > dateTo) {
                continue
            }

            if (dateFrom <= now && now <= dateTo) {
                // dbgprint('foundNow')
                dateFrom = now
            }

            var prec = obj.precipitationAvg
            if ((typeof(prec) === "string")  && (prec === "")) {
                prec = 0
            }
            // dbgprint("dateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString())

            if (dateFrom >= sunrise1) {
                if (dateFrom < sunset1) {
                    isDaytime = true
                } else {
                    sunrise1.setDate(sunrise1.getDate() + 1)
                    sunset1.setDate(sunset1.getDate() + 1)
                    isDaytime = false
                }
            }
            // dbgprint(isDaytime ? "isDay\n" : "isNight\n")
            // dbgprint2(new Date(Date.parse(obj.from)))
            dbgprint("DateFrom=" + dateFrom.toISOString() + "\tLocal Time=" + UnitUtils.convertDate(dateFrom,2,currentPlace.timezoneOffset).toTimeString() + "\t Sunrise=" + sunrise1.toTimeString() + "\tSunset=" + sunset1.toTimeString())
            meteogramModel.append({
                                      from: new Date(Date.parse(obj.from)),
                                      to:new Date(Date.parse(obj.to)),
                                      isDaytime: isDaytime,
                                      temperature: parseFloat(obj.temperature),
                                      precipitationAvg: parseFloat(prec),
                                      precipitationLabel: "",
                                      precipitationMax: parseFloat(prec),
                                      windDirection: parseFloat(obj.windDirection),
                                      windSpeedMps: parseFloat(obj.windSpeedMps),
                                      pressureHpa: parseFloat(obj.pressureHpa),
                                      iconName: obj.iconName
                                  })
            if (firstFromMs === null) {
                firstFromMs = new Date(dateFrom).getTime()
            }

            if (new Date(dateTo).getTime() - firstFromMs > limitMsDifference) {
                dbgprint('breaking')
                break
            }
        }

        dbgprint('meteogramModel.count = ' + meteogramModel.count)
        main.debugLogging = 0

    }

    function convertToLocalTime(dateString, timezoneOffset) {
        if ((dateString instanceof Date) || (typeof dateString === 'string'))  {
            dateString = Date.parse(dateString)
        }

        return new Date(dateString + timezoneOffset)
    }
    function composeNextDayTitle(date) {
        dbgprint2("composeNextDayTitle    " + date)
        return Qt.locale().dayName(date.getDay(), Locale.ShortFormat) + ' ' + date.getDate() + '/' + (date.getMonth() + 1)
    }

    function getCreditLabel(placeIdentifier) {
        return i18n("Weather forecast data provided by OpenWeather.")
    }

    function getCreditLink(placeIdentifier) {
        return 'http://openweathermap.org/city/' + placeIdentifier
    }

    function reloadMeteogramImage(placeIdentifier) {
        main.overviewImageSource = ''
    }

    function getTimeZoneName() {
        dbgprint2("getTimeZoneName")
        switch (timezoneType) {
        case 0:
            currentPlace.timezoneShortName = getLocalTimeZone()
            break
        case 1:
            currentPlace.timezoneShortName =  i18n("UTC")
            break
        case 2:
            currentPlace.timezoneShortName="LOCAL"
            break
        }
        dbgprint("timezoneName changed to:" + currentPlace.timezoneShortName)
    }

    function localTime(date){
        let t = Date.parse(date) + parseInt(currentPlace.timezoneOffset)
        return new Date(t)
    }
    function formatTime(ISOdate) {
        return ISOdate.substr(11,5)
    }

    function loadCompleted() {
        main.loadingDataComplete = true
        dataLoadedFromInternet()
    }

    XmlListModel {
        id: xmlModelCurrent
        query: "/current"

        XmlListModelRole { name: "temperature"; elementName: "temperature"; attributeName: "value" }
        XmlListModelRole { name: "iconName"; elementName: "weather"; attributeName: "number" }
        XmlListModelRole { name: "humidity"; elementName: "humidity"; attributeName: "value" }
        XmlListModelRole { name: "pressureHpa"; elementName: "pressure"; attributeName: "value" }
        XmlListModelRole { name: "windSpeedMps"; elementName: "wind/speed"; attributeName: "value" }
        XmlListModelRole { name: "windDirection"; elementName: "wind/direction"; attributeName: "value" }
        XmlListModelRole { name: "cloudiness"; elementName: "clouds"; attributeName: "value" }
        XmlListModelRole { name: "updated"; elementName: "lastupdate"; attributeName: "value" }
        XmlListModelRole { name: "rise"; elementName: "city/sun"; attributeName: "rise" }
        XmlListModelRole { name: "set"; elementName: "city/sun"; attributeName: "set" }
        XmlListModelRole { name: "cityName"; elementName: "city"; attributeName: "name"  }
        XmlListModelRole { name: "timezoneOffset"; elementName: "city/timezone" }

        function get(i) {
            var o = {}
            for (var j = 0; j < roles.length; ++j)
            {
                o[roles[j].name] = data(index(i,0), Qt.UserRole + j)
            }
            return o
        }
    }
    onXmlModelCurrentStatusChanged: {
        if (xmlModelCurrent.status == XmlListModel.Error) {
            dbgprint(xmlModelCurrent.errorString())
        }
        if (xmlModelCurrent.status != XmlListModel.Ready) {
            return
        } else {
            dbgprint("***xmlModelCurrent Done***")
        }
    }


    XmlListModel {
        id: xmlModelLongTerm
        query: '/weatherdata/forecast/time'
        XmlListModelRole { name: "date"; elementName: ""; attributeName: "day"  }
        XmlListModelRole { name: "temperatureMorning"; elementName: "temperature"; attributeName: "morn"  }
        XmlListModelRole { name: "temperatureDay"; elementName: "temperature"; attributeName: "day"  }
        XmlListModelRole { name: "temperatureEvening"; elementName: "temperature"; attributeName: "eve"  }
        XmlListModelRole { name: "temperatureNight"; elementName: "temperature"; attributeName: "night"  }
        XmlListModelRole { name: "iconName"; elementName: "symbol"; attributeName: "number"  }
        XmlListModelRole { name: "windDirection"; elementName: "windDirection"; attributeName: "deg"  }
        XmlListModelRole { name: "windSpeedMps"; elementName: "windSpeed"; attributeName: "mps"  }
        XmlListModelRole { name: "pressureHpa"; elementName: "pressure"; attributeName: "value"  }

        function get(i) {
            var o = {}
            for (var j = 0; j < roles.length; ++j)
            {
                o[roles[j].name] = data(index(i,0), Qt.UserRole + j)
            }
            return o
        }
    }
    onXmlModelLongTermStatusChanged: {
        if (xmlModelLongTerm.status == XmlListModel.Error) {
            dbgprint(xmlModelLongTerm.errorString())
        }
        if (xmlModelLongTerm.status != XmlListModel.Ready) {
            return
        } else {
            dbgprint("***xmlModelLongTerm Done***")
        }
    }

    XmlListModel {
        id: xmlModelHourByHour
        query: '/weatherdata/forecast/time'
        XmlListModelRole { name: "from"; elementName: ""; attributeName: "from"  }
        XmlListModelRole { name: "to"; elementName: ""; attributeName: "to"  }
        XmlListModelRole { name: "temperature"; elementName: "temperature"; attributeName: "value"  }
        XmlListModelRole { name: "iconName"; elementName: "symbol"; attributeName: "number"  }
        XmlListModelRole { name: "windDirection"; elementName: "windDirection"; attributeName: "deg"  }
        XmlListModelRole { name: "windSpeedMps"; elementName: "windSpeed"; attributeName: "mps"  }
        XmlListModelRole { name: "pressureHpa"; elementName: "pressure"; attributeName: "value"  }
        XmlListModelRole { name: "precipitationAvg"; elementName: "precipitation"; attributeName: "value"  }

        function get(i) {
            var o = {}
            for (var j = 0; j < roles.length; ++j)
            {
                o[roles[j].name] = data(index(i,0), Qt.UserRole + j)
            }
            return o
        }
    }
    onXmlModelHourByHourStatusChanged: {
        dbgprint("xmlModelHourByHour: " + xmlModelHourByHour.status)
        if (xmlModelHourByHour.status == XmlListModel.Error) {
            dbgprint(xmlModelHourByHour.errorString())
        }
        if (xmlModelHourByHour.status != XmlListModel.Ready) {
            return
        } else {
            dbgprint("***xmlModelHourByHour Done***")
        }
    }
}
