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
/*
        XmlRole {
            name: 'date'
            elementName: 'day/string()'
        }
        XmlRole {
            name: 'temperatureMorning'
            elementName: 'temperature/@morn/number()'
        }
        XmlRole {
            name: 'temperatureDay'
            elementName: 'temperature/@day/number()'
        }
        XmlRole {
            name: 'temperatureEvening'
            elementName: 'temperature/@eve/number()'
        }
        XmlRole {
            name: 'temperatureNight'
            elementName: 'temperature/@night/number()'
        }
        XmlRole {
            name: 'iconName'
            elementName: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            elementName: 'windDirection/@deg/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            elementName: 'windSpeed/@mps/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            elementName: 'pressure/@value/number()'
        }
        */
    }


    XmlListModel {
        id: xmlModelHourByHour
        query: '/weatherdata/forecast/time'
/*
        XmlRole {
            name: 'from'
            elementName: 'from/string()'
        }
        XmlRole {
            name: 'to'
            elementName: 'to/string()'
        }
        XmlRole {
            name: 'temperature'
            elementName: 'temperature/@value/number()'
        }
        XmlRole {
            name: 'iconName'
            elementName: 'symbol/@number/string()'
        }
        XmlRole {
            name: 'windDirection'
            elementName: 'windDirection/@deg/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            elementName: 'windSpeed/@mps/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            elementName: 'pressure/@value/number()'
        }
        XmlRole {
            name: 'precipitationAvg'
            elementName: 'precipitation/@value/number()'
        }
*/
    }

    XmlListModel {
        id: xmlModelCurrent
        query: '/current'
/*
        XmlRole {
            name: 'temperature'
            elementName: 'temperature/@value/number()'
        }
        XmlRole {
            name: 'iconName'
            elementName: 'weather/@number/string()'
        }
        XmlRole {
            name: 'humidity'
            elementName: 'humidity/@value/number()'
        }
        XmlRole {
            name: 'pressureHpa'
            elementName: 'pressure/@value/number()'
        }
        XmlRole {
            name: 'windSpeedMps'
            elementName: 'wind/speed/@value/number()'
        }
        XmlRole {
            name: 'windDirection'
            elementName: 'wind/direction/@value/number()'
        }
        XmlRole {
            name: 'cloudiness'
            elementName: 'clouds/@value/number()'
        }
        XmlRole {
            name: 'updated'
            elementName: 'lastupdate/@value/string()'
        }
        XmlRole {
            name: 'rise'
            elementName: 'city/sun/@rise/string()'
        }
        XmlRole {
            name: 'set'
            elementName: 'city/sun/@set/string()'
        }
        XmlRole {
            name: 'timezoneOffset'
            elementName: 'city/timezone/number()'
        }
*/
    }

    function loadDataFromInternet(successCallback, failureCallback, locationObject) {
        var placeIdentifier = locationObject.placeIdentifier

        var loadedCounter = 0

        var loadedData = {
            current: null,
            hourByHour: null,
            longTerm: null
        }

        var versionParam = '&v=' + new Date().getTime()
console.log(urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam)
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
dbgprint(urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam)
        var xhr1 = DataLoader.fetchXmlFromInternet(urlPrefix + '/weather?id=' + placeIdentifier + appIdAndModeSuffix + versionParam, successCurrent, failureCallback)

        return [xhr1]
    }


    function setWeatherContents(cacheContent) {
        if (!cacheContent.longTerm || !cacheContent.hourByHour || !cacheContent.current) {
            return false
        }
        /*
        xmlModelCurrent.xml = ''
        xmlModelCurrent.xml = cacheContent.current
        xmlModelLongTerm.xml = ''
        xmlModelLongTerm.xml = cacheContent.longTerm
        xmlModelHourByHour.xml = ''
        xmlModelHourByHour.xml = cacheContent.hourByHour
        return true
        */
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

}
