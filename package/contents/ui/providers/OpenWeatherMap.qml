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

    // onTimezoneTypeChanged: {
        // getTimeZoneName()
    // }

    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        var loadedData = {
            current: null,
            hourByHour: null,
            longTerm: null
        }

        var placeIdentifier = locationObject.placeIdentifier
        var versionParam = '&v=' + new Date().getTime()

        // xmlModelCurrent.source=Qt.resolvedUrl('../../code/weather/current.xml')
        // xmlModelLongTerm.source=Qt.resolvedUrl('../../code/weather/daily.xml')
        // xmlModelHourByHour.source=Qt.resolvedUrl('../../code/weather/forecast.xml')

        xmlModelCurrent.source=urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
        xmlModelLongTerm.source=urlPrefix + '/forecast/daily?id=' + placeIdentifier + '&cnt=8' + appIdAndModeSuffix + versionParam
        xmlModelHourByHour.source=urlPrefix + '/forecast?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
        dbgprint(successCallback)
        successCallback(xmlModelComplete)
    }

    function updateTodayModels(todayTimeObj) {

        dbgprint('updating today models')

        var now = new Date()
        dbgprint('now: ' + now)
        var tooOldCurrentDataLimit = new Date(now.getTime() - (2 * 60 * 60 * 1000))
        var nearFutureWeather = additionalWeatherInfo.nearFutureWeather

        actualWeatherModel.clear()
        actualWeatherModel.append(todayTimeObj)

        // set current models
        nearFutureWeather.iconName = null
        nearFutureWeather.temperature = null
        var foundNow = false
        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var timeObj = xmlModelHourByHour.get(i)
            var dateFrom = parseDate(timeObj.from)
            var dateTo = parseDate(timeObj.to)
            dbgprint('HOUR BY HOUR: dateFrom=' + dateFrom + ', dateTo=' + dateTo + ', i=' + i)

            if (!foundNow && dateFrom <= now && now <= dateTo) {
                dbgprint('foundNow setting to true')
                foundNow = true
                if (actualWeatherModel.count === 0) {
                    dbgprint('adding to actualWeatherModel - temperature: ' + timeObj.temperature + ', iconName: ' + timeObj.iconName)
                    actualWeatherModel.append(timeObj)
                }
                continue
            }

            if (foundNow) {
                nearFutureWeather.iconName = timeObj.iconName
                nearFutureWeather.temperature = timeObj.temperature
                dbgprint('setting near future - ' + nearFutureWeather.iconName + ', temp: ' + nearFutureWeather.temperature)
                break
            }
        }

        dbgprint('result actualWeatherModel count: ' + actualWeatherModel.count)
        dbgprint('result nearFutureWeather.iconName: ' + nearFutureWeather.iconName)

    }

    function updateMeteogramModel() {
        dbgprint('updating meteogram models')

        meteogramModel.clear()

        var firstFromMs = null
        var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days
        var now = new Date()

        var dateFrom = parseDate(xmlModelHourByHour.get(0).from)
        var sunrise1 = (additionalWeatherInfo.sunRise)
        var sunset1 = (additionalWeatherInfo.sunSet)
        var isDaytime = (dateFrom > sunrise1) && (dateFrom < sunset1)
        dbgprint("dateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))

        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var obj = xmlModelHourByHour.get(i)
            var dateFrom = parseDate(obj.from)
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
                temperature: parseInt(obj.temperature),
                                  precipitationAvg: prec,
                                  precipitationLabel: "",
                                  precipitationMax: prec,
                                  windDirection: obj.windDirection,
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

        main.meteogramModelChanged = !main.meteogramModelChanged
    }

    function updateNextDaysModel() {
        var nextDaysFixedCount = nextDaysCount

        dbgprint('updating NEXT DAYS MODEL...')

        var now = new Date()
        dbgprint('now: ' + now)

        dbgprint('orig hourByHour model count: ' + xmlModelHourByHour.count)
        dbgprint('orig long term model count: ' + xmlModelLongTerm.count)

        var newObjectArray = []

        var today0000 = new Date(new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime())
        var today0600 = new Date(today0000.getTime() + ModelUtils.hourDurationMs * 6)
        var today1200 = new Date(today0000.getTime() + ModelUtils.hourDurationMs * 12)
        var today1800 = new Date(today0000.getTime() + ModelUtils.hourDurationMs * 18)

        function composeNextDayTitle(date) {
            return Qt.locale().dayName(date.getDay(), Locale.ShortFormat) + ' ' + date.getDate() + '/' + (date.getMonth() + 1)
        }

        var lastObjectHourByHour = null
        var lastDateNumber = now.getDate()
        var lastDateToSet = today0000
        var current0000 = today0000
        var current0600 = today0600
        var current1200 = today1200
        var current1800 = today1800
        var next0000 = new Date(current1800.getTime() + ModelUtils.hourDurationMs * 6)
        var isToday = false

        dbgprint('current0000: ' + current0000)
        dbgprint('current0600: ' + current0600)
        dbgprint('current1200: ' + current1200)
        dbgprint('current1800: ' + current1800)
        dbgprint('next0000: ' + next0000)

        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var timeObj = xmlModelHourByHour.get(i)
            var dateFrom = parseDate(timeObj.from)
            var dateTo = parseDate(timeObj.to)
            dbgprint('HOUR BY HOUR: dateFrom=' + dateFrom + ', dateTo=' + dateTo + ', i=' + i)

            // encountered old data -> continue to next
            if (today0000 >= dateFrom) {
                dbgprint('skipping this timeObj')
                continue
            }

            if (next0000 < dateFrom) {
                current0000 = next0000
                current0600 = new Date(current0000.getTime() + ModelUtils.hourDurationMs * 6)
                current1200 = new Date(current0000.getTime() + ModelUtils.hourDurationMs * 12)
                current1800 = new Date(current0000.getTime() + ModelUtils.hourDurationMs * 18)
                next0000 = new Date(current1800.getTime() + ModelUtils.hourDurationMs * 6)
                dbgprint('current0000: ' + current0000)
                dbgprint('current0600: ' + current0600)
                dbgprint('current1200: ' + current1200)
                dbgprint('current1800: ' + current1800)
                dbgprint('next0000: ' + next0000)
            }

            if (lastObjectHourByHour === null && current0000 < dateFrom && dateFrom < next0000) {
                dbgprint('HBH creating new empty next object')
                lastObjectHourByHour = ModelUtils.createEmptyNextDaysObject()
                newObjectArray.push(lastObjectHourByHour)

                // today?
                if (dateFrom <= now && now <= dateTo) {
                    dbgprint('setting today')
                    lastObjectHourByHour.dayTitle = i18n("today")
                    isToday = true
                } else {
                    lastObjectHourByHour.dayTitle = composeNextDayTitle(dateTo)
                }
            }

            if (current0000 < dateFrom && dateTo <= current0600) {
                dbgprint('found Q1 temp')

                lastObjectHourByHour.tempInfoArray.push({
                    temperature: timeObj.temperature,
                    iconName: timeObj.iconName,
                    isPast: now > current0600
                })

            } else if (current0600 < dateFrom && dateTo <= current1200) {
                dbgprint('found Q2 temp')

                lastObjectHourByHour.tempInfoArray.push({
                    temperature: timeObj.temperature,
                    iconName: timeObj.iconName,
                    isPast: now > current1200
                })

            } else if (current1200 < dateFrom && dateTo <= current1800) {
                dbgprint('found Q3 temp')

                lastObjectHourByHour.tempInfoArray.push({
                    temperature: timeObj.temperature,
                    iconName: timeObj.iconName,
                    isPast: now > current1800
                })

            } else if (current1800 < dateFrom && dateTo <= next0000) {
                dbgprint('found Q4 temp')

                lastObjectHourByHour.tempInfoArray.push({
                    temperature: timeObj.temperature,
                    iconName: timeObj.iconName,
                    isPast: now > next0000
                })

                lastObjectHourByHour = null

            } else {
                dbgprint('skipping')
                continue
            }

            lastDateToSet = dateTo
            dbgprint('lastDateToSet: ' + lastDateToSet)

        }
        dbgprint('setting next days from LONG TERM XML')

        for (var i = 0; i < xmlModelLongTerm.count; i++) {
            let timeObj = xmlModelLongTerm.get(i)
            let dateFrom = Date.fromLocaleString(xmlLocale, timeObj.date, 'yyyy-MM-dd')
            let dateTo = new Date(dateFrom.getTime())
            dateTo.setDate(dateTo.getDate() + 1)
            dateTo = new Date(dateTo.getTime() - 1)
            dbgprint('LONG TERM: dateFrom=' + dateFrom + ', dateTo=' + dateTo + ', now=' + now + ', i=' + i)

            // encountered old data -> continue to next
            if (lastDateToSet > dateTo) {
                dbgprint('skipping this day')
                continue
            }
            isToday = false

            var lastObject
            if (lastObjectHourByHour !== null) {
                lastObject = lastObjectHourByHour
                lastObjectHourByHour = null
            } else {
                lastObject = ModelUtils.createEmptyNextDaysObject()
                newObjectArray.push(lastObject)
            }

            if (dateFrom <= now && now <= dateTo) {
                dbgprint('setting today')
                lastObject.dayTitle = i18n("today")
                isToday = true
            } else {
                lastObject.dayTitle = composeNextDayTitle(dateTo)
            }

            if (lastObject.tempInfoArray.length === 0) {
                dbgprint('setting temperatureMorning')
                lastObject.tempInfoArray.push({
                    temperature: timeObj.temperatureMorning,
                    iconName: timeObj.iconName,
                    isPast: isToday && now > today0600
                })
            }
            if (lastObject.tempInfoArray.length === 1) {
                dbgprint('setting temperatureDay')
                lastObject.tempInfoArray.push({
                    temperature: timeObj.temperatureDay,
                    iconName: timeObj.iconName,
                    isPast: isToday && now > today1200
                })
            }
            if (lastObject.tempInfoArray.length === 2) {
                dbgprint('setting temperatureEvening')
                lastObject.tempInfoArray.push({
                    temperature: timeObj.temperatureEvening,
                    iconName: timeObj.iconName,
                    isPast: isToday && now > today1800
                })
            }
            if (lastObject.tempInfoArray.length === 3) {
                dbgprint('setting temperatureNight')
                lastObject.tempInfoArray.push({
                    temperature: timeObj.temperatureNight,
                    iconName: timeObj.iconName,
                    isPast: false
                })
            }

        }

        dbgprint('done setting next days from all models, now polishing created newObjectArray')

        //
        // set next days model
        //
        nextDaysModel.clear()
        newObjectArray.forEach(function (objToAdd) {
            if (nextDaysModel.count >= nextDaysFixedCount) {
                return
            }
            while (objToAdd.tempInfoArray.length < 4) {
                objToAdd.tempInfoArray.unshift(null)
            }
            ModelUtils.populateNextDaysObject(objToAdd)
            nextDaysModel.append(objToAdd)
        })
        for (let i = 0; i < (nextDaysFixedCount - nextDaysModel.count); i++) {
            nextDaysModel.append(ModelUtils.createEmptyNextDaysObject())
        }

        dbgprint('result nextDaysModel count: ' + nextDaysModel.count)
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
                timezoneShortName = getLocalTimeZone()
                break
            case 1:
                timezoneShortName =  i18n("UTC")
                break
            case 2:
                timezoneShortName="LOCAL"
                break
        }
        dbgprint("timezoneName changed to:" + timezoneShortName)
    }

    function parseDate(dateString) {
        return new Date(dateString + '.000Z')
    }

    function createTodayTimeObj() {
        function formatTime(ISOdate) {
            return ISOdate.substr(11,5)
        }

        var currentTimeObj = xmlModelCurrent.get(0)
        dbgprint(JSON.stringify(currentTimeObj))


        dbgprint(new Date(Date.parse(currentTimeObj.rise)))

        additionalWeatherInfo.sunRise = new Date(Date.parse(currentTimeObj.rise))
        additionalWeatherInfo.sunSet = new Date(Date.parse(currentTimeObj.set))

        dbgprint('sunRise 1: ' + (additionalWeatherInfo.sunRise))
        dbgprint('sunSet  1: ' + (additionalWeatherInfo.sunSet))


        additionalWeatherInfo.sunRiseTime=new Date(UnitUtils.localTime(additionalWeatherInfo.sunRise,currentTimeObj.timezoneOffset))
        additionalWeatherInfo.sunSetTime=new Date(UnitUtils.localTime(additionalWeatherInfo.sunSet,currentTimeObj.timezoneOffset))

        dbgprint('sunRiseTime 1: ' + parseDate(additionalWeatherInfo.sunRiseTime))
        dbgprint('sunSetTime  1: ' + parseDate(additionalWeatherInfo.sunSetTime))

        main.timezoneOffset=currentTimeObj.timezoneOffset

        getTimeZoneName()

        dbgprint('setting actual weather from current xml model')
        dbgprint('current: ' + currentTimeObj.temperature)
        return currentTimeObj
    }

    onXmlModelCompleteChanged: {
        if (xmlModelComplete == false) {
            return
        }

        var todayTimeObj = createTodayTimeObj()
        dbgprint("************************************************************")

        updateTodayModels(todayTimeObj)
        dbgprint("************************************************************")
        updateMeteogramModel()
        dbgprint("************************************************************")
        updateNextDaysModel()
        dbgprint("************************************************************")
        refreshTooltipSubText()
        dbgprint("************************************************************")
    }

    XmlListModel {
        id: xmlModelCurrent
        // source: Qt.resolvedUrl('../weather/current.xml')
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
                dbgprint(data(index(i,0), Qt.UserRole + j))
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
        // source: Qt.resolvedUrl('../weather/daily.xml')
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
