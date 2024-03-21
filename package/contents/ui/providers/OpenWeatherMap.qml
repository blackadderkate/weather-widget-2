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

    function parseISOString(s) {
        var b = s.split(/\D+/)
        return new Date(Date.UTC(b[0], --b[1], b[2], b[3], b[4], b[5], b[6]))
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
            url1 = Qt.resolvedUrl('../../code/weather/current.' + placeIdentifier + '.xml')
            url2 = Qt.resolvedUrl('../../code/weather/daily.' + placeIdentifier + '.xml')
            url3 = Qt.resolvedUrl('../../code/weather/forecast.' + placeIdentifier + '.xml')
        } else {

            url1 = urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
            url2 = urlPrefix + '/forecast/daily?id=' + placeIdentifier + '&cnt=8' + appIdAndModeSuffix + versionParam
            url3 = urlPrefix + '/forecast?id=' + placeIdentifier + appIdAndModeSuffix + versionParam
        }
        main.debugLogging = 0
        dbgprint("xmlModelCurrent = " + url1)
        dbgprint("xmlModelLongTerm = " + url2)
        dbgprint("xmlModelHourByHour = " + url3)
        main.debugLogging = 0
        xmlModelCurrent.source = url1
        xmlModelLongTerm.source = url2
        xmlModelHourByHour.source = url3
    }

    function updatecurrentWeather() {
        main.debugLogging = 0
        dbgprint2('updatecurrentWeather (OWM)')

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
        let updated = Date.parse(obj.updated)
        let tzms = parseInt(obj.timezoneOffset) * 1000
        currentPlace.timezoneOffset = parseInt(obj.timezoneOffset)
        currentWeatherModel.sunRise = new Date (sunRise)
        currentWeatherModel.sunSet= new Date (sunSet)
        currentWeatherModel.sunRiseTime = new Date (sunRise + tzms).toTimeString()
        currentWeatherModel.sunSetTime = new Date (sunSet + tzms).toTimeString()
        dbgprint("Updated=" + updated/1000 + "\t" + sunRise/1000 + "\t" + sunSet/1000)
        dbgprint("Updated=" + updated/1000 + "\t" + (updated > sunRise) + "\t" + (updated < sunSet))
        currentWeatherModel.isDay = ((updated > sunRise) && (updated < sunSet)) ? 0 : 1
        dbgprint(
            "Updated=" + new Date(updated).toTimeString() +
            "\t Sunrise=" + currentWeatherModel.sunRiseTime +
            "\tSunset=" + currentWeatherModel.sunSetTime + "\t" +
            ((currentWeatherModel.isDay === 0) ? "isDay\n" : "isNight\n"))

        dbgprint2('EXIT updatecurrentWeather')
        main.debugLogging = 0
    }

    function updateNextDaysModel() {
        function blankObject() {
            const myblankObject={}
            for (let f = 0; f < 4; f++) {
                myblankObject["temperature" + f] = -999
                myblankObject["iconName" + f] = ''
                myblankObject['hidden' + f] = true
                myblankObject['partOfDay' + f] = 0

            }
            return myblankObject
        }

        main.debugLogging = 0
        dbgprint2("updateNextDaysModel")
        nextDaysModel.clear()

        var offset = 0
        switch (timezoneType) {
            case (0):
                offset = dataSource.data["Local"]["Offset"]
                break;
            case (1):
                offset = 0
                break;
            case (2):
                offset = currentPlace.timezoneOffset
                break;
        }
        let updatedDateTime = xmlModelCurrent.get(0).updated
        let timezoneOffset = xmlModelCurrent.get(0).timezoneOffset

        let updatedDateTimeStamp = Date.parse(updatedDateTime)
        // let updatedDateTimeStampLocal = convertToLocalTime(Date.parse(updatedDateTime),timezoneOffset * 1000)
        let updatedDateTimeStampLocal = new Date(convertToLocalTime(updatedDateTime + "Z", offset))
        let hr = new Date(updatedDateTimeStampLocal).getHours()
        let y = parseInt((hr + 3) / 6)
dbgprint("main.timezoneType= " + timezoneType + "\t= " + offset)
        let dataTime = new Date(updatedDateTimeStamp)
        dbgprint("XML Updated At:\t"+ updatedDateTime + "\t" + new Date(updatedDateTimeStamp) + "\t" + new Date(updatedDateTimeStampLocal))
        // dbgprint("XML Updated At:\t"+ t1 + "Z" + militaryGMTOffsetFromNumeric(tz1))
        // let t2 = Date.parse(t1 + "Z" + militaryGMTOffsetFromNumeric(tz1))
        // let t3 = new Date(t2)
        // dbgprint("XML Updated At:\t" + t3 + " (local)")
        // let timeArray = t1.split(/[T:-]/)
        // let hr = parseInt(timeArray[3])
        // let x = 0
        // let y = parseInt((hr + 3) / 6)

        dbgprint2("HR = " + hr + "\tY = " + y)



        let ptr = 0
        let x = 0
        dbgprint("*********************************************************************")
        dbgprint("Parsing Data starting at Row " + ptr + " of xmlModelLongTerm")

        let t = 0
        switch (timezoneType) {
            case (0):
                t =  (dataSource.data["Local"]["Offset"] * 1000) - (timezoneOffset * 1000)
                break;
            case (1):
                t = 0
                break;
            case (2):
                t = (timezoneOffset * 1000)
                break;
        }
        let timeArray=["T03:00:00Z","T09:00:00Z","T15:00:00Z","T21:00:00Z"]
        dbgprint2(t / 3600000)
        let nextDaysData = blankObject()
        while (ptr < xmlModelLongTerm.count) {
            let obj = xmlModelLongTerm.get(ptr)

            for (var i = 0; i < 4; i++) {
                let str=timeArray[i]
                let localtime = convertToLocalTime(obj.date + str,  t)
                let hr = new Date(localtime).getUTCHours()
                let y = parseInt((hr) / 6)
                dbgprint(new Date(localtime) + "\t" + new Date(localtime).toUTCString() + "\tt=" + t + "\thr=" + hr + "\ty=" + y)
                dbgprint("***" + new Date(updatedDateTimeStamp) + "\t" + localtime)
                if (localtime >= new Date(updatedDateTimeStamp)) {
                    if (y === 0) {
                        nextDaysData['temperature0'] = parseInt(obj.temperatureMorning)
                        nextDaysData['iconName0'] = obj.iconName
                        dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                        nextDaysData['hidden0'] = false
                    }
                    if (y === 1) {
                        nextDaysData['temperature1'] = parseInt(obj.temperatureDay)
                        nextDaysData['iconName1'] = obj.iconName
                        dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                        nextDaysData['hidden1'] = false
                    }
                    if (y === 2) {
                        nextDaysData['temperature2'] = parseInt(obj.temperatureEvening)
                        nextDaysData['iconName2'] = obj.iconName
                        dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                        nextDaysData['hidden2'] = false
                    }
                    if (y === 3) {
                        // dbgprint2(obj.date)
                    nextDaysData['dayTitle'] =  composeNextDayTitle(dataTime)
                                dataTime.setDate(dataTime.getDate() + 1)

                        nextDaysData['temperature3'] = parseInt(obj.temperatureEvening)
                        nextDaysData['iconName3'] = obj.iconName
                        dbgprint("Added data for Row " + (x + 1) + " Column " + (y + 1))
                        nextDaysData['hidden3'] = false
                        nextDaysModel.append(nextDaysData)
                        // for(const [key,value] of Object.entries(nextDaysData)) { console.log(`  ${key}: ${value}`) }
                        nextDaysData = blankObject()
                        x++
                    }
                }
            }

/*


            let fred =  ((dataSource.data["Local"]["Offset"] * 1000) - (timezoneOffset * 1000)) / 3600000



            let t = Date.parse(obj.date + "T03:00:00Z")

            switch (timezoneType) {
                case (0):
                    t = new Date(t - (timezoneOffset * 1000))
                    break;
                case (1):
                    t = new Date(t)
                    break;
                case (2):
                    t = new Date(t + (dataSource.data["Local"]["Offset"] * 1000))
                    break;
            }
            dbgprint(new Date(t).toUTCString())
            // dbgprint(new Date(t))
            // dbgprint(obj.date + "\t0 = " + "\tt=" + new Date(t - (timezoneOffset * 1000)).toUTCString())
            // dbgprint(obj.date + "\t1 = " + "\tt=" + new Date(t).toUTCString())
            // dbgprint(obj.date + "\t2 = " + "\tt=" + new Date(t + (offset * 1000)).toUTCString())


*/


            // + "\t" + UnitUtils.convertDate(t, main.timezoneType, -currentPlace.timezoneOffset))
// dbgprint(obj.date + "T03:00:00" + "\t" + convertToLocalTime(obj.date + "T03:00:00Z", 0))
// + "\t" + convertToLocalTime(obj.date + "T03:00:00Z", offset * 1000))
/*
            let y1 = convertToLocalTime(obj.date + "T03:00:00Z", offset * 1000)
            let y2 = convertToLocalTime(obj.date + "T09:00:00Z", offset * 1000)
            let y3 = convertToLocalTime(obj.date + "T15:00:00Z", offset * 1000)
            let y4 = convertToLocalTime(obj.date + "T21:00:00Z", offset * 1000)
            dbgprint2(y1.getHours())
            dbgprint2(y2.getHours())
            dbgprint2(y3.getHours())
            dbgprint2(y4.getHours())
*/
/*

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
            */
            ptr++
        }

        /* Overwrite nextDaysModel with more accurate data from Daily XML Model where available */
        x = 0
        y = 0
        ptr = 0
        nextDaysData=blankObject()
        var offset = 0
        switch (timezoneType) {
            case (0):
                offset = dataSource.data["Local"]["Offset"]
                break;
            case (1):
                offset = 0
                break;
            case (2):
                offset = currentPlace.timezoneOffset
                break;
        }

dbgprint2("***************************************************")
        while (ptr < xmlModelHourByHour.count) {
            let obj = xmlModelHourByHour.get(ptr)
            dbgprint(obj.from)
            let t = convertToLocalTime(obj.from, offset * 1000)
            let h = 3 + (parseInt(t.getHours() / 6) * 6)
            y = parseInt(h / 6)
            dbgprint("GetHours=" + t.getHours() + "\th=" + h + "\ty=" +y)
             nextDaysData['dayTitle'] = nextDaysModel.get(x).dayTitle
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

        var offset = 0
        switch (timezoneType) {
            case (0):
                offset = dataSource.data["Local"]["Offset"]
                break;
            case (1):
                offset = 0
                break;
            case (2):
                offset = currentPlace.timezoneOffset
                break;
        }

        dbgprint2("DEBUG:" + timezoneType + "    " + offset)
        meteogramModel.clear()

        var now = new Date(convertToLocalTime(xmlModelHourByHour.get(0).from, offset))

        var limitMsDifference = 1000 * 60 * 60 * 54 // 2.25 days

        var dateFrom = now
        var dateTo = now
        var sunrise1 = (currentWeatherModel.sunRise)
        var sunset1 = (currentWeatherModel.sunSet)
        var isDaytime = (dateFrom > sunrise1) && (dateFrom < sunset1)


        for (var i = 0; i < xmlModelHourByHour.count; i++) {
        var obj = xmlModelHourByHour.get(i)
        dateFrom = new Date(convertToLocalTime(xmlModelHourByHour.get(i).from + "Z", offset))
        dateTo = new Date(convertToLocalTime(xmlModelHourByHour.get(i).to + "Z", offset))
        if (i === 0) {
            var firstFromMs = dateFrom.getTime()
        }
        dbgprint("DATEFROM\t" + obj.from + "\t\t" + dateFrom  + "\t\t" +  dateFrom.toUTCString())
        dbgprint("DATETO\t" + obj.to + "\t\t" + dateTo  + "\t\t" +  dateTo.toUTCString())
        dbgprint(dateTo + "\t\t" + new Date(dateTo).getTime()  + "\t\t" + firstFromMs  + "\t\t" + (new Date(dateTo).getTime() - firstFromMs)  + "\t\t" + limitMsDifference )
        // dbgprint("dateFrom = " + dateFrom.toUTCString()  + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))
        var prec = obj.precipitationAvg
        if ((typeof(prec) === "string")  && (prec === "")) {
            prec = 0
        }

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
        if (new Date(dateTo).getTime() - firstFromMs > limitMsDifference) {
            dbgprint('breaking')
            break
        }
        }
        /*





        dbgprint2(now +"        " + offset +"        " + currentPlace.timezoneOffset)



        dbgprint(obj.from + "\t" + UnitUtils.convertDate(new Date(obj.from), main.timezoneType, offset) + "\t" + dateFrom + "\t" + UnitUtils.convertDate(dateFrom, main.timezoneType, offset))



        if (dateFrom >= sunrise1) {
            if (dateFrom < sunset1) {
                isDaytime = true
            } else {
                sunrise1.setDate(sunrise1.getDate() + 1)
                sunset1.setDate(sunset1.getDate() + 1)
                isDaytime = false
            }
        }

        }


        /*
        for (var i = 0; i < xmlModelHourByHour.count; i++) {
            var obj = xmlModelHourByHour.get(i)
            //dateFrom = convertToLocalTime(obj.from, currentPlace.timezoneOffset)
            // dateTo = convertToLocalTime(obj.to, currentPlace.timezoneOffset)

            dateFrom = UnitUtils.convertDate(new Date(obj.from), main.timezoneType, offset)
            dateTo = UnitUtils.convertDate(new Date(obj.to), main.timezoneType, offset)

            dbgprint("obj.from=" + obj.from + "\tobj.to=" + obj.to + "\tdateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString() + "\t" + (isDaytime ? "isDay" : "isNight"))

            if (now > dateTo) {
                continue
            }

            if (dateFrom <= now && now <= dateTo) {
                // dbgprint('foundNow')
                dateFrom = now
            }


            // dbgprint("dateFrom = " + dateFrom.toUTCString() + "\tSunrise = " + sunrise1.toUTCString() + "\tSunset = " + sunset1.toUTCString())


            // dbgprint(isDaytime ? "isDay\n" : "isNight\n")
            // dbgprint2(new Date(Date.parse(obj.from)))
            dbgprint("DateFrom=" + dateFrom.toISOString() + "\tLocal Time=" + UnitUtils.convertDate(dateFrom,2,currentPlace.timezoneOffset).toTimeString() + "\t Sunrise=" + sunrise1.toTimeString() + "\tSunset=" + sunset1.toTimeString())

            if (firstFromMs === null) {
                firstFromMs = new Date(dateFrom).getTime()
            }


        }
*/
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
        main.debugLogging = 0
        dbgprint2("composeNextDayTitle    " + date)
        main.debugLogging = 0
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
