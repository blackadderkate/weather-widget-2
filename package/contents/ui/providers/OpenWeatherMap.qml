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

        updatecurrentWeather()
        updateNextDaysModel()
        buildMetogramData()
        loadCompleted()
    }

    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        var loadedData = {
            current: null,
            hourByHour: null,
            longTerm: null
        }

        var placeIdentifier = locationObject.placeIdentifier
        var versionParam = '&v=' + new Date().getTime()
        if (! useOnlineWeatherData) {
            xmlModelCurrent.source=Qt.resolvedUrl('../../code/weather/current.xml')
            xmlModelLongTerm.source=Qt.resolvedUrl('../../code/weather/daily.xml')
            xmlModelHourByHour.source=Qt.resolvedUrl('../../code/weather/forecast.xml')
        } else {

            xmlModelCurrent.source=urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
            xmlModelLongTerm.source=urlPrefix + '/forecast/daily?id=' + placeIdentifier + '&cnt=8' + appIdAndModeSuffix + versionParam
            xmlModelHourByHour.source=urlPrefix + '/forecast?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
        }
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
        currentWeatherModel.sunRise = parseDate(obj.rise)
        currentWeatherModel.sunSet = parseDate(obj.set)
        currentWeatherModel.sunRiseTime=formatTime(UnitUtils.convertDate(currentWeatherModel.sunRise,main.timezoneType,main.currentPlace.timezoneOffset).toISOString())
        currentWeatherModel.sunSetTime=formatTime(UnitUtils.convertDate(currentWeatherModel.sunSet,main.timezoneType,main.currentPlace.timezoneOffset).toISOString())
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
        dbgprint2("updateNextDaysModel")
        dbgprint(xmlModelHourByHour.count)
        let wdPtr = 0
        let x = 0
        while ((wdPtr < xmlModelHourByHour.count) && (((new Date(xmlModelHourByHour.get(wdPtr).from).getHours() - 3) % 6 ) != 0)) { wdPtr++; dbgprint(wdPtr) }
        let t = 0
        let y = 0
        let myOffset = 3
        let nextDaysData=blankObject()
        let airTemp = -999

        while (x < 5 && y < 3 && wdPtr < xmlModelHourByHour.count) {
            let tm1 = new Date(xmlModelHourByHour.get(wdPtr).from)
            if (wdPtr < 64) {myOffset = 3} else {myOffset = 0}
            let tm2 = tm1.getHours() - myOffset
            t = (tm2 % 6)
            if (t == 0) {
                let y = (tm2) / 6
                airTemp=parseInt(xmlModelHourByHour.get(wdPtr).temperature)
                nextDaysData['dayTitle']=composeNextDayTitle(new Date(xmlModelHourByHour.get(wdPtr).from))
                nextDaysData['temperature' + y] = airTemp
                nextDaysData['hidden' + y] = false
                let obj = ""
                nextDaysData['iconName' + y] = xmlModelHourByHour.get(wdPtr).iconName

                if (y==3) {
                    nextDaysModel.append(nextDaysData)
                    nextDaysData = blankObject()
                    x++
                }
            }
            wdPtr++
        }
        dbgprint("nextDaysModel Count:" + nextDaysModel.count)
        dbgprint2("EXIT updateNextDaysModel")
    }


    function buildMetogramData() {
        dbgprint('updating meteogram models')

        meteogramModel.clear()

        var firstFromMs = null
        var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days
        var now = new Date()
        now = parseDate(xmlModelHourByHour.get(0).from)
        var dateFrom = parseDate(xmlModelHourByHour.get(0).from)
        var sunrise1 = (currentWeatherModel.sunRise)
        var sunset1 = (currentWeatherModel.sunSet)
        var isDaytime = (dateFrom > sunrise1) && (dateFrom < sunset1)
        dbgprint("dateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))

        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var obj = xmlModelHourByHour.get(i)
            dateFrom = parseDate(obj.from)
            var dateTo = parseDate(obj.to)
            if (now > dateTo) {
                continue
            }

            if (dateFrom <= now && now <= dateTo) {
                dbgprint('foundNow')
                dateFrom = now
            }

            var prec = obj.precipitationAvg
            if ((typeof(prec) === "string")  && (prec === "")) {
                prec = 0
            }
            dbgprint("dateFrom = " + dateFrom.toUTCString())
            dbgprint("Sunrise = " + sunrise1.toUTCString())
            dbgprint("Sunset = " + sunset1.toUTCString())

            if (dateFrom >= sunrise1) {
                if (dateFrom < sunset1) {
                    isDaytime = true
                } else {
                    sunrise1.setDate(sunrise1.getDate() + 1)
                    sunset1.setDate(sunset1.getDate() + 1)
                    isDaytime = false
                }
            }
            dbgprint(isDaytime ? "isDay\n" : "isNight\n")
            meteogramModel.append({
                                      from: dateFrom,
                                      to: dateTo,
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
                firstFromMs = dateFrom.getTime()
            }

            if (dateTo.getTime() - firstFromMs > limitMsDifference) {
                dbgprint('breaking')
                break
            }
        }

        dbgprint('meteogramModel.count = ' + meteogramModel.count)
    }

    function composeNextDayTitle(date) {
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

    function parseDate(dateString) {
        return new Date(dateString + '.000Z')
    }

    function formatTime(ISOdate) {
        return ISOdate.substr(11,5)
    }

    function createTodayTimeObj() {
        dbgprint2("createTodayTimeObj")
        function formatTime(ISOdate) {
            return ISOdate.substr(11,5)
        }

        var currentTimeObj = xmlModelCurrent.get(0)
        dbgprint(JSON.stringify(currentTimeObj))


        dbgprint(new Date(Date.parse(currentTimeObj.rise)))

        currentWeatherModel.sunRise = new Date(Date.parse(currentTimeObj.rise))
        currentWeatherModel.sunSet = new Date(Date.parse(currentTimeObj.set))

        dbgprint('sunRise 1: ' + (currentWeatherModel.sunRise))
        dbgprint('sunSet  1: ' + (currentWeatherModel.sunSet))


        currentWeatherModel.sunRiseTime=new Date(UnitUtils.localTime(currentWeatherModel.sunRise,currentTimeObj.timezoneOffset))
        currentWeatherModel.sunSetTime=new Date(UnitUtils.localTime(currentWeatherModel.sunSet,currentTimeObj.timezoneOffset))

        dbgprint('sunRiseTime 1: ' + parseDate(currentWeatherModel.sunRiseTime))
        dbgprint('sunSetTime  1: ' + parseDate(currentWeatherModel.sunSetTime))

        currentPlace.timezoneOffset=currentTimeObj.timezoneOffset

        getTimeZoneName()

        dbgprint('setting actual weather from current xml model')
        dbgprint('current: ' + currentTimeObj.temperature)
        return currentTimeObj
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
