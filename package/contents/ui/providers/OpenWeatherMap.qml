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
import QtQuick 2.2
import QtQuick.XmlListModel 2.0
import "../../code/model-utils.js" as ModelUtils
import "../../code/data-loader.js" as DataLoader
import "../../code/unit-utils.js" as UnitUtils

Item {
    id: owm

    property string providerId: 'owm'

    property string urlPrefix: 'http://api.openweathermap.org/data/2.5'
    property string appIdAndModeSuffix: '&units=metric&mode=xml&appid=5819a34c58f8f07bc282820ca08948f1'

// DEBUGGING URLs
//     property string urlPrefix: 'http://localhost/forecast'
//     property string appIdAndModeSuffix: ''

    XmlListModel {
        id: xmlModelLongTerm
        query: '/weatherdata/forecast/time'

        XmlRole {
            name: 'date'
            query: '@day/string()'
        }
        XmlRole {
            name: 'temperatureMorning'
            query: 'temperature/@morn/number()'
        }
        XmlRole {
            name: 'temperatureDay'
            query: 'temperature/@day/number()'
        }
        XmlRole {
            name: 'temperatureEvening'
            query: 'temperature/@eve/number()'
        }
        XmlRole {
            name: 'temperatureNight'
            query: 'temperature/@night/number()'
        }
        XmlRole {
            name: 'iconName'
            query: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            query: 'windDirection/@deg/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            query: 'windSpeed/@mps/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            query: 'pressure/@value/number()'
        }
    }

    XmlListModel {
        id: xmlModelHourByHour
        query: '/weatherdata/forecast/time'

        XmlRole {
            name: 'from'
            query: '@from/string()'
        }
        XmlRole {
            name: 'to'
            query: '@to/string()'
        }
        XmlRole {
            name: 'temperature'
            query: 'temperature/@value/number()'
        }
        XmlRole {
            name: 'iconName'
            query: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            query: 'windDirection/@deg/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            query: 'windSpeed/@mps/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            query: 'pressure/@value/number()'
        }
        XmlRole {
            name: 'precipitationAvg'
            query: 'precipitation/@value/number()'
        }
    }

    XmlListModel {
        id: xmlModelCurrent
        query: '/current'

        XmlRole {
            name: 'temperature'
            query: 'temperature/@value/number()'
        }
        XmlRole {
            name: 'iconName'
            query: 'weather/@number/string()'
        }
        XmlRole {
            name: 'humidity'
            query: 'humidity/@value/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            query: 'pressure/@value/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            query: 'wind/speed/@value/number()'
        }
        XmlRole {
            name: 'windDirection'
            query: 'wind/direction/@value/number()'
        }
        XmlRole {
            name: 'cloudiness'
            query: 'clouds/@value/string()'
        }
        XmlRole {
            name: 'updated'
            query: 'lastupdate/@value/string()'
        }
        XmlRole {
            name: 'rise'
            query: 'city/sun/@rise/string()'
        }
        XmlRole {
            name: 'set'
            query: 'city/sun/@set/string()'
        }
    }

    property var xmlModelLongTermStatus: xmlModelLongTerm.status
    property var xmlModelCurrentStatus: xmlModelCurrent.status
    property var xmlModelHourByHourStatus: xmlModelHourByHour.status

    function parseDate(dateString) {
        return new Date(dateString + '.000Z')
    }

    onXmlModelCurrentStatusChanged: {
        if (xmlModelCurrent.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelCurrent ready')
        xmlModelReady()
    }

    onXmlModelHourByHourStatusChanged: {
        if (xmlModelHourByHour.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelHourByHour ready')
        xmlModelReady()
    }

    onXmlModelLongTermStatusChanged: {
        if (xmlModelLongTerm.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelLongTerm ready')
        xmlModelReady()
    }

    function xmlModelReady() {
        if (xmlModelCurrent.status != XmlListModel.Ready) {
            return
        }
        if (xmlModelHourByHour.status != XmlListModel.Ready) {
            return
        }
        if (xmlModelLongTerm.status != XmlListModel.Ready) {
            return
        }
        dbgprint('all xml models ready')
        var todayTimeObj = createTodayTimeObj()
        updateTodayModels(todayTimeObj)
        updateMeteogramModel()
        updateNextDaysModel()
        updateAdditionalWeatherInfoText()
    }

    function createTodayTimeObj() {
        var currentTimeObj = xmlModelCurrent.get(0)
        additionalWeatherInfo.sunRise = parseDate(currentTimeObj.rise)
        additionalWeatherInfo.sunSet = parseDate(currentTimeObj.set)
        dbgprint('setting actual weather from current xml model')
        dbgprint('sunRise: ' + additionalWeatherInfo.sunRise)
        dbgprint('sunSet:  ' + additionalWeatherInfo.sunSet)
        dbgprint('current: ' + currentTimeObj.temperature)
        return currentTimeObj;
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
            var timeObj = xmlModelLongTerm.get(i)
            var dateFrom = Date.fromLocaleString(xmlLocale, timeObj.date, 'yyyy-MM-dd')
            var dateTo = new Date(dateFrom.getTime())
            dateTo.setDate(dateTo.getDate() + 1);
            dateTo = new Date(dateTo.getTime() - 1)
            dbgprint('LONG TERM: dateFrom=' + dateFrom + ', dateTo=' + dateTo + ', now=' + now + ', i=' + i)

            // encountered old data -> continue to next
            if (lastDateToSet > dateTo) {
                dbgprint('skipping this day')
                continue
            }

            var lastObject
            if (lastObjectHourByHour !== null) {
                lastObject = lastObjectHourByHour
                lastObjectHourByHour = null
            } else {
                lastObject = ModelUtils.createEmptyNextDaysObject()
                newObjectArray.push(lastObject)
            }

            var isToday = false
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
        for (var i = 0; i < (nextDaysFixedCount - nextDaysModel.count); i++) {
            nextDaysModel.append(ModelUtils.createEmptyNextDaysObject())
        }

        dbgprint('result nextDaysModel count: ' + nextDaysModel.count)
    }

    function updateMeteogramModel() {

        meteogramModel.clear()

        var firstFromMs = null
        var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days
        var now = new Date()

        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var obj = xmlModelHourByHour.get(i)
            var dateFrom = parseDate(obj.from)
            var dateTo = parseDate(obj.to)
//             dbgprint('meteo fill: i=' + i + ', from=' + obj.from + ', to=' + obj.to)
//             dbgprint('parsed: from=' + dateFrom + ', to=' + dateTo)
            if (now > dateTo) {
                continue;
            }

            if (dateFrom <= now && now <= dateTo) {
                dbgprint('foundNow')
                dateFrom = now
            }

            var prec = obj.precipitationAvg
            if (typeof(prec)==="string"  && prec==="") {
              prec = 0
            }

            meteogramModel.append({
                from: dateFrom,
                to: dateTo,
                temperature: parseInt(obj.temperature),
                precipitationAvg: prec,
                precipitationMin: '',
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

    /**
     * successCallback(contentToCache)
     * failureCallback()
     */
    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        var placeIdentifier = locationObject.placeIdentifier

        var loadedCounter = 0

        var loadedData = {
            current: null,
            hourByHour: null,
            longTerm: null
        }

        var versionParam = '&v=' + new Date().getTime()

        function successLongTerm(xmlString) {
            loadedData.longTerm = xmlString
            successCallback(loadedData)
        }

        function successHourByHour(xmlString) {
            loadedData.hourByHour = xmlString
            DataLoader.fetchXmlFromInternet(urlPrefix + '/forecast/daily?id=' + placeIdentifier + '&cnt=8' + appIdAndModeSuffix + versionParam, successLongTerm, failureCallback)
        }

        function successCurrent(xmlString) {
            loadedData.current = xmlString
            DataLoader.fetchXmlFromInternet(urlPrefix + '/forecast?id=' + placeIdentifier + appIdAndModeSuffix + versionParam, successHourByHour, failureCallback)
        }

        var xhr1 = DataLoader.fetchXmlFromInternet(urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam, successCurrent, failureCallback)

        return [xhr1]
    }

    function setWeatherContents(cacheContent) {
        if (!cacheContent.longTerm || !cacheContent.hourByHour || !cacheContent.current) {
            return false
        }
        xmlModelCurrent.xml = ''
        xmlModelCurrent.xml = cacheContent.current
        xmlModelLongTerm.xml = ''
        xmlModelLongTerm.xml = cacheContent.longTerm
        xmlModelHourByHour.xml = ''
        xmlModelHourByHour.xml = cacheContent.hourByHour
        return true
    }

    function getCreditLabel(placeIdentifier) {
        return 'Weather forecast data provided by OpenWeather.'
    }

    function getCreditLink(placeIdentifier) {
        return 'http://openweathermap.org/city/' + placeIdentifier
    }

    function reloadMeteogramImage(placeIdentifier) {
        main.overviewImageSource = ''
    }

}
