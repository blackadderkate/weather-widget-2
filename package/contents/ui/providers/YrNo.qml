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

Item {
    id: yrno

    property string providerId: 'yrno'

    property string urlPrefix: 'https://www.yr.no/place/'

    XmlListModel {
        id: xmlModelLongTerm
        query: '/weatherdata/forecast/tabular/time'

        XmlRole {
            name: 'from'
            query: '@from/string()'
        }
        XmlRole {
            name: 'to'
            query: '@to/string()'
        }
        XmlRole {
            name: 'period'
            query: '@period/string()'
        }
        XmlRole {
            name: 'temperature'
            query: 'temperature/@value/string()'
        }
        XmlRole {
            name: 'iconName'
            query: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            query: 'windDirection/@code/string()'
        }
        XmlRole {
            name: 'windSpeedMps'
            query: 'windSpeed/@mps/string()'
        }
        XmlRole {
            name: 'pressureHpa'
            query: 'pressure/@value/string()'
        }
    }

    XmlListModel {
        id: xmlModelHourByHour
        query: '/weatherdata/forecast/tabular/time'

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
            query: 'temperature/@value/string()'
        }
        XmlRole {
            name: 'iconNumber'
            query: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            query: 'windDirection/@code/string()'
        }
        XmlRole {
            name: 'windSpeedMps'
            query: 'windSpeed/@mps/string()'
        }
        XmlRole {
            name: 'pressureHpa'
            query: 'pressure/@value/string()'
        }
        XmlRole {
            name: 'precipitationAvg'
            query: 'precipitation/@value/string()'
        }
        XmlRole {
            name: 'precipitationMin'
            query: 'precipitation/@minvalue/string()'
        }
        XmlRole {
            name: 'precipitationMax'
            query: 'precipitation/@maxvalue/string()'
        }
    }

    XmlListModel {
        id: xmlModelSunRiseSet
        query: '/weatherdata'

        XmlRole {
            name: 'utcOffsetMinutes'
            query: 'location/timezone/@utcoffsetMinutes/string()'
        }
        XmlRole {
            name: 'rise'
            query: 'sun/@rise/string()'
        }
        XmlRole {
            name: 'set'
            query: 'sun/@set/string()'
        }
    }

    property var xmlModelLongTermStatus: xmlModelLongTerm.status
    property var xmlModelSunRiseSetStatus: xmlModelSunRiseSet.status
    property var xmlModelHourByHourStatus: xmlModelHourByHour.status

    property int utcOffsetMinutes: 0

    function parseDate(dateString) {
        var minutes = utcOffsetMinutes % 60
        var hours = (utcOffsetMinutes - minutes) / 60
        var preparedDateString = dateString + '.000' + (utcOffsetMinutes < 0 ? '-' : '+') + ('0' + Math.abs(hours)).slice(-2) + ':' + ('0' + Math.abs(minutes)).slice(-2)
        dbgprint('prepared date string: ' + preparedDateString)
        return new Date(preparedDateString)
    }

    onXmlModelLongTermStatusChanged: {
        if (xmlModelLongTerm.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelLongTerm ready')
        updateWeatherModels(actualWeatherModel, additionalWeatherInfo.nearFutureWeather, nextDaysModel, xmlModelLongTerm)
        refreshTooltipSubText()
        dbgprint('xmlModelLongTerm all set up')
    }

    onXmlModelSunRiseSetStatusChanged: {
        if (xmlModelSunRiseSet.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelSunRiseSet ready')
        utcOffsetMinutes = xmlModelSunRiseSet.get(0).utcOffsetMinutes
        additionalWeatherInfo.sunRise = parseDate(xmlModelSunRiseSet.get(0).rise)
        additionalWeatherInfo.sunSet = parseDate(xmlModelSunRiseSet.get(0).set)
        updateAdditionalWeatherInfoText()
        dbgprint('xmlModelSunRiseSet all set up')
    }

    onXmlModelHourByHourStatusChanged: {
        if (xmlModelHourByHour.status != XmlListModel.Ready) {
            return
        }
        dbgprint('xmlModelHourByHour ready')
        updateMeteogramModel(meteogramModel, xmlModelHourByHour)
        dbgprint('xmlModelHourByHour all set up')
    }

    function updateMeteogramModel(meteogramModel, originalXmlModel) {

        meteogramModel.clear()
        var now = new Date()

        for (var i = 0; i < originalXmlModel.count; i++) {
            var obj = originalXmlModel.get(i)
            var dateFrom = parseDate(obj.from)
            dbgprint('yr meteogram from adding: ' + dateFrom)
            var dateTo = parseDate(obj.to)

            if (now > dateTo) {
                continue;
            }

            if (dateFrom <= now && now <= dateTo) {
                dbgprint('foundNow')
                dateFrom = now
            }

            meteogramModel.append({
                from: dateFrom,
                to: dateTo,
                temperature: parseInt(obj.temperature),
                precipitationAvg: obj.precipitationAvg,
                precipitationMin: obj.precipitationMin,
                precipitationMax: obj.precipitationMax,
                windDirection: obj.windDirection,
                windSpeedMps: parseFloat(obj.windSpeedMps),
                pressureHpa: parseFloat(obj.pressureHpa),
                iconName: obj.iconNumber
            })
        }

        dbgprint('meteogramModel.count = ' + meteogramModel.count)

        main.meteogramModelChanged = !main.meteogramModelChanged
    }

    function updateWeatherModels(currentWeatherModel, nearFutureWeather, nextDaysWeatherModel, originalXmlModel) {
      dbgprint("****** updateWeatherModels ******")

        var nextDaysFixedCount = nextDaysCount

        var now = new Date()
        var nextDayStart = new Date(new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() + ModelUtils.wholeDayDurationMs)
        dbgprint('next day start: ' + nextDayStart)

        dbgprint('orig: ' + originalXmlModel.count)

        var todayObject = null
        var newObjectArray = []
        var lastObject = null
        var addingStarted = false

        var interestingTimeObj = null
        var nextInterestingTimeObj = null
        var currentWeatherModelsSet = false

        for (var i = 0; i < originalXmlModel.count; i++) {
            var timeObj = originalXmlModel.get(i)
            var dateFrom = parseDate(timeObj.from)
            var dateTo = parseDate(timeObj.to)


            // prepare current models
            if (!currentWeatherModelsSet
                && ((i === 0 && now < dateFrom) || (dateFrom < now && now < dateTo))) {

                interestingTimeObj = timeObj
                if (i + 1 < originalXmlModel.count) {
                    nextInterestingTimeObj = originalXmlModel.get(i + 1)
                }
                currentWeatherModelsSet = true
            }

            if (!addingStarted) {
                addingStarted = dateTo >= nextDayStart && timeObj.period === '0'

                if (!addingStarted) {

                    // add today object
                    if (todayObject === null) {
                        todayObject = ModelUtils.createEmptyNextDaysObject()
                        todayObject.dayTitle = i18n('today')
                    }
                    todayObject.tempInfoArray.push({
                        temperature: timeObj.temperature,
                        iconName: timeObj.iconName,
                        isPast: false
                    })

                    continue
                }
                dbgprint('found start!')
            }

            var periodNo = parseInt(timeObj.period)
            if (periodNo === 0) {
//                dbgprint('period 0, array: ' + newObjectArray.length + ', nextDaysCount: ' + nextDaysFixedCount)
                if (newObjectArray.length === nextDaysFixedCount) {
                    dbgprint('breaking')
                    break
                }
                lastObject = ModelUtils.createEmptyNextDaysObject()
                lastObject.dayTitle = Qt.locale().dayName(dateTo.getDay(), Locale.ShortFormat) + ' ' + dateTo.getDate() + '/' + (dateTo.getMonth() + 1)
                newObjectArray.push(lastObject)
            }

            lastObject.tempInfoArray.push({
                temperature: timeObj.temperature,
                iconName: timeObj.iconName,
                isPast: false
            })
        }

        // set current models
        currentWeatherModel.clear()
        if (interestingTimeObj !== null) {
            currentWeatherModel.append(interestingTimeObj)
//DUMP
      Object.keys(interestingTimeObj).forEach(key => {
      })        }
        nearFutureWeather.iconName = null
        nearFutureWeather.temperature = null
        if (nextInterestingTimeObj !== null) {
            nearFutureWeather.iconName = nextInterestingTimeObj.iconName
            nearFutureWeather.temperature = nextInterestingTimeObj.temperature
        }

        //
        // set next days model
        //
        nextDaysWeatherModel.clear()

        // prepend today object
        if (todayObject !== null) {
            while (todayObject.tempInfoArray.length < 4) {
                todayObject.tempInfoArray.unshift(null)
            }
            ModelUtils.populateNextDaysObject(todayObject)
            nextDaysWeatherModel.append(todayObject)
        }

        newObjectArray.forEach(function (objToAdd) {
            if (nextDaysWeatherModel.count >= nextDaysFixedCount) {
                return
            }
            ModelUtils.populateNextDaysObject(objToAdd)
            nextDaysWeatherModel.append(objToAdd)
        })
        for (var i = 0; i < (nextDaysFixedCount - nextDaysWeatherModel.count); i++) {
            nextDaysWeatherModel.append(ModelUtils.createEmptyNextDaysObject())
        }
        dbgprint('result currentWeatherModel count: ', currentWeatherModel.get(0).count)
        dbgprint('result nearFutureWeather.iconName: ', nearFutureWeather.iconName)
        dbgprint('result nextDaysWeatherModel count: ', nextDaysWeatherModel.count)
        dbgprint(JSON.stringify(nextDaysWeatherModel))
    }

    /**
     * successCallback(contentToCache)
     * failureCallback()
     */
    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        var placeIdentifier = locationObject.placeIdentifier

        var loadedCounter = 0

        var loadedData = {
            longTerm: null,
            hourByHour: null
        }

        function successLongTerm(xmlString) {
            loadedData.longTerm = xmlString
            loadedCounter++
            if (loadedCounter === 2) {
                successCallback(loadedData)
            }
        }

        function successHourByHour(xmlString) {
            loadedData.hourByHour = xmlString
            loadedCounter++
            if (loadedCounter === 2) {
                successCallback(loadedData)
            }
        }

        var xhr1 = DataLoader.fetchXmlFromInternet(urlPrefix + placeIdentifier + '/forecast.xml', successLongTerm, failureCallback)
        var xhr2 = DataLoader.fetchXmlFromInternet(urlPrefix + placeIdentifier + '/forecast_hour_by_hour.xml', successHourByHour, failureCallback)

        return [xhr1, xhr2]
    }

    function setWeatherContents(cacheContent) {
        if (!cacheContent.longTerm || !cacheContent.hourByHour) {
            return false
        }
        xmlModelSunRiseSet.xml = ''
        xmlModelSunRiseSet.xml = cacheContent.longTerm
        xmlModelLongTerm.xml = ''
        xmlModelLongTerm.xml = cacheContent.longTerm
        xmlModelHourByHour.xml = ''
        xmlModelHourByHour.xml = cacheContent.hourByHour
        return true
    }

    function getCreditLabel(placeIdentifier) {
        return 'Weather forecast from yr.no, delivered by the Norwegian Meteorological Institute and the NRK'
    }

    function getCreditLink(placeIdentifier) {
        return urlPrefix + placeIdentifier + '/'
    }

    function reloadMeteogramImage(placeIdentifier) {
        dbgprint('reloading image')
        main.overviewImageSource = ''
        main.overviewImageSource = urlPrefix + placeIdentifier + '/avansert_meteogram.png'
    }

}
