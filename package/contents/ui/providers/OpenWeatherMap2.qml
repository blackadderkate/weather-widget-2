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

    property var locale: Qt.locale()

    property string urlPrefix: 'http://localhost'
    property string appIdAndModeSuffix: '&units=metric&appid=ef8d2ddfd28e7a591d4cc9da28e78500'

    // DEBUGGING URLs
    //     property string urlPrefix: 'http://localhost/forecast'
    //     property string appIdAndModeSuffix: ''


    function parseDate(dateString) {
        return new Date(dateString + '.000Z')
    }

    function timestampToISODate(ts) {
        return new Date(ts * 1000).toISOString()
    }

    function parseISOString(s) {
        var b = s.split(/\D+/);
        return new Date(Date.UTC(b[0], --b[1], b[2], b[3], b[4], b[5], b[6]));
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



    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        function formatTime(ISOdate) {
            return ISOdate.substr(11,5)
        }

        function successWeather() {
            var readingsArray = (loadedData.oneShot)
            actualWeatherModel.clear()
            var currentWeather=readingsArray.current
            var futureWeather=readingsArray.hourly
            var iconnumber=(currentWeather.weather[0].id).toString()
            var tp=currentWeather["temp"]
            var wd=currentWeather["wind_deg"]
            var ws=currentWeather["wind_speed"]
            var ap=currentWeather["pressure"]
            var hm=parseInt(currentWeather["humidity"])
            var cd=parseInt(currentWeather["clouds"])
            actualWeatherModel.append({"temperature": tp, "iconName": iconnumber, "windDirection": wd,"windSpeedMps": ws, "pressureHpa": ap, "humidity": hm, "cloudiness": cd})
            additionalWeatherInfo.nearFutureWeather.temperature=futureWeather[0].temp
            additionalWeatherInfo.nearFutureWeather.iconName=(futureWeather[0].weather[0].id)
            var sr=formatTime(timestampToISODate(currentWeather["sunrise"]))
            var ss=formatTime(timestampToISODate(currentWeather["sunset"]))
            additionalWeatherInfo.sunRiseTime=sr
            additionalWeatherInfo.sunSetTime=ss
            updateMeteogramModel(futureWeather)
            updateNextDaysModel()
            weatherDataFlag = true
            updateAdditionalWeatherInfoText()
            refreshTooltipSubText()
            successCallback(readingsArray)
        }

        function updateMeteogramModel(weather) {
            dbgprint("**************************************")
            // dbgprint(JSON.stringify(weather))
            meteogramModel.clear()

            var firstFromMs = null
            var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days
            var now = new Date()
            var counter=0
            for (var i = 0; i < weather.length; i++) {
                var obj = weather[i]
                dbgprint(JSON.stringify(obj.rain))
                var dateFrom = new Date(obj.dt * 1000)
                var dateTo = new Date((obj.dt + 3600)*1000)
                //             dbgprint('meteo fill: i=' + i + ', from=' + obj.from + ', to=' + obj.to)
                dbgprint('parsed: from=' + dateFrom + ', to=' + dateTo)
                //             if (now > dateTo) {
                //                 continue;
                //             }

                //             if (dateFrom <= now && now <= dateTo) {
                //                 dbgprint('foundNow')
                //                 dateFrom = now
                //             }
                var prec = (obj.rain === undefined) ? 0: obj.rain["1h"]
                dbgprint("***" + prec)
                if (typeof(prec)==="string"  && prec==="") {
                    prec = 0
                }

                counter = (prec > 0) ? counter+1 : 0
                meteogramModel.append({
                                          from: dateFrom,
                                          to: dateTo,
                                          temperature: (obj.temp),
                                          precipitationAvg: prec,
                                          precipitationLabel:  (counter === 1) ? "mm" : "",
                                          precipitationMax: prec,
                                          windDirection: obj.wind_deg,
                                          windSpeedMps: parseFloat(obj.wind_speed),
                                          pressureHpa: parseFloat(obj.pressure),
                                          iconName: (obj.weather[0].id).toString()
                                      })

                //             if (firstFromMs === null) {
                //                 firstFromMs = dateFrom.getTime()
                //             }

                //             if (dateTo.getTime() - firstFromMs > limitMsDifference) {
                //                 dbgprint('breaking')
                //                 break
                //             }
            }

            dbgprint('meteogramModel.count = ' + meteogramModel.count)

            main.meteogramModelChanged = !main.meteogramModelChanged
        }

        function updateNextDaysModel() {

            function resetobj() {
                var obj={}
                obj.hidden0=true
                obj.isPast0=true
                obj.hidden1=true
                obj.isPast1=true
                obj.hidden2=true
                obj.isPast2=true
                obj.hidden3=true
                obj.isPast3=true
                obj.dayTitle=""
            return obj
            }

            dbgprint('updating NEXT DAYS MODEL...')

            var readingsArray=loadedData.fiveDay
            var nextDaysFixedCount = nextDaysCount
            var readingsLength=(readingsArray.cnt)-1
            var dateNow=new Date()
            nextDaysModel.clear()
            var obj=resetobj()
            nextDaysModel.append(obj)
            for (var i=0; i<readingsLength; i++) {
                var reading=readingsArray.list[i]
                var readingDate=new Date(reading.dt * 1000).toLocaleDateString(locale, 'ddd d MMM')
                var readingTime=formatTime(new Date(reading.dt * 1000).toISOString())

                if (reading.weather[0] !== undefined) {
                    var iconnumber=(reading.weather[0].id).toString()
                }
                else {
                    var iconnumber=0
                }
                var temperature=reading.main.temp

                if (readingTime === "00:00") {
                    if ( !(obj.isPast0 && obj.isPast1 && obj.isPast2 && obj.isPast3) && (nextDaysModel.count < 8)) {
                        nextDaysModel.append(obj) }
                    obj=resetobj()
                    obj.dayTitle=readingDate
                }

                if ((readingTime === "00:00") ||  (readingTime === "03:00")) {
                    obj.temperature0=temperature
                    obj.iconName0=iconnumber
                    obj.hidden0=false
                    obj.isPast0=false
                }

                if  ((readingTime === "06:00") ||  (readingTime === "09:00")) {
                    obj.temperature1=temperature
                    obj.iconName1=iconnumber
                    obj.hidden1=false
                    obj.isPast1=false
                }

                if  ((readingTime === "12:00") ||  (readingTime === "15:00")) {
                    obj.temperature2=temperature
                    obj.iconName2=iconnumber
                    obj.hidden2=false
                    obj.isPast2=false
                }

                if  ((readingTime === "18:00") ||  (readingTime === "21:00")) {
                    obj.temperature3=temperature
                    obj.iconName3=iconnumber
                    obj.hidden3=false
                    obj.isPast3=false
                    if (! obj.dayTitle) {
                        obj.dayTitle=readingDate
                    }
                }
            }
            nextDaysModel.append(obj)
            var obj=resetobj()
            nextDaysModel.append(obj)
            dbgprint('result nextDaysModel count: ' + nextDaysModel.count)
        }

        function successFiveDay(jsonString) {
            loadedData.fiveDay = JSON.parse(jsonString)
            successWeather()
            successCallback(loadedData)
        }

        function successOneShot(jsonString) {
            var readingsArray = JSON.parse(jsonString)
            loadedData.oneShot = readingsArray
            let URL=urlPrefix + '/fiveday.json?id=' + placeIdentifier + appIdAndModeSuffix
            DataLoader.fetchJsonFromInternet(URL, successFiveDay, failureCallback)
        }

        var placeIdentifier = locationObject.placeIdentifier
        var loadedCounter = 0
        var loadedData = {
            fiveDay: null,
            oneShot: null
        }
        let URL=urlPrefix + '/onecall.json?' + placeIdentifier + appIdAndModeSuffix
        var xhr1 = DataLoader.fetchJsonFromInternet(URL, successOneShot, failureCallback)

        return [xhr1]
    }

    function setWeatherContents(cacheContent) {
        if (!cacheContent.longTerm || !cacheContent.hourByHour || !cacheContent.current) {
            return false
        }
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
