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
import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "providers"
import "../code/data-loader.js" as DataLoader
import "../code/config-utils.js" as ConfigUtils
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils
import "../code/timezoneData.js" as TZ

PlasmoidItem {
    id: main

    /* Includes */
    WeatherCache {
        id: weatherCache
        cacheId: cacheData.plasmoidCacheId
    }
    Plasma5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 0
    }
    FontLoader {
        source: "../fonts/weathericons-regular-webfont-2.0.10.ttf"
    }
    MetNo {
        id: metnoProvider
    }
    OpenWeatherMap {
        id: owmProvider
    }
    property bool loadingDataComplete: false

    /* GUI layout stuff */
    property Component fr: FullRepresentation { }
    property Component cr: CompactRepresentation { }
    property Component frInTray: FullRepresentationInTray { }
    property Component crInTray: CompactRepresentationInTray { }

    compactRepresentation: inTray ? crInTray : cr
    fullRepresentation: inTray ? frInTray : fr

    switchWidth: inTray ? 256 : undefined
    switchHeight: inTray ? 128 : undefined

    preferredRepresentation: inTray ? undefined: compactRepresentation

    property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    property bool onDesktop: (plasmoid.location === PlasmaCore.Types.Desktop || plasmoid.location === PlasmaCore.Types.Floating)


    toolTipTextFormat: Text.RichText

    // User Preferences
    property int layoutType: plasmoid.configuration.layoutType
    property bool debugLogging: plasmoid.configuration.debugLogging
    property int inTrayActiveTimeoutSec: plasmoid.configuration.inTrayActiveTimeoutSec
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "") ? Kirigami.Theme.defaultFont : plasmoid.configuration.widgetFontName
    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property int temperatureType: plasmoid.configuration.temperatureType
    property int timezoneType: plasmoid.configuration.timezoneType
    property int pressureType: plasmoid.configuration.pressureType
    property int windSpeedType: plasmoid.configuration.windSpeedType
    property bool twelveHourClockEnabled: Qt.locale().timeFormat(Locale.ShortFormat).toString().indexOf('AP') > -1
    property bool env_QML_XHR_ALLOW_FILE_READ: plasmoid.configuration.qml_XHR_ALLOW_FILE_READ
    property bool inTray: (plasmoid.containment.containmentType === 129) && ((plasmoid.formFactor === 2) || (plasmoid.formFactor === 3))
    readonly property string placesStr: plasmoid.configuration.places

    // Cache, Last Load Time, Widget Status
    property string fullRepresentationAlias
    property string iconNameStr
    property string temperatureStr
    property bool meteogramModelChanged: false
    property int nextDaysCount

    property var loadingData: ({
                                   loadingDatainProgress: false,            // Download Attempt in progress Flag.
                                   loadingDataTimeoutMs: 15000,             // Download Timeout in ms.
                                   loadingXhrs: [],                         // Array of Download Attempt Objects
                                   loadingError: false,                     // Whether the last Download Attempt was successful
                                   lastloadingStartTime: 0,                 // Time download last attempted.
                                   lastloadingSuccessTime: 0,               // Time download last successful.
                                   failedAttemptCount: 0
                               })
    property string lastReloadedText: "⬇ " + i18n("%1 ago", "?? m")

    property var cacheData: ({
                                 plasmoidCacheId: plasmoid.id,
                                 cacheKey: "",
                                 cacheMap: ({})
                             })

    // Current Place Data
    property var currentPlace: ({
                                    alias: "",
                                    identifier: "",
                                    provider: "",
                                    providerId:"",
                                    timezoneID: 0,
                                    timezoneShortName: "",
                                    timezoneOffset: 0,
                                    creditLink: "",
                                    creditLabel: "",
                                    cacheID: "",
                                    nextReload: 0
                                })

    property int placesCount

    property var timerData: ({
                                 reloadIntervalMin: 0 ,   // Download Attempt Frequency in minutes
                                 reloadIntervalMs: 0,               // Download Attempt Frequency in milliseconds
                                 nextReload: 0                 // Time next download is due.
                             })



    property bool useOnlineWeatherData: true


    /* Data Models */
    property var currentWeatherModel
    ListModel {
        id: nextDaysModel
    }
    ListModel {
        id: meteogramModel
    }



    onLoadingDataCompleteChanged: {
        dbgprint2("loadingDataComplete:" + loadingDataComplete)
    }

    onEnv_QML_XHR_ALLOW_FILE_READChanged: {
        plasmoid.configuration.qml_XHR_ALLOW_FILE_READ = env_QML_XHR_ALLOW_FILE_READ
        dbgprint("QML_XHR_ALLOW_FILE_READ Enabled: " + env_QML_XHR_ALLOW_FILE_READ)
    }

    onPlacesStrChanged: {
        let places = ConfigUtils.getPlacesArray()
        let placesCount = places.length - 1
        let i = Math.min(plasmoid.configuration.placeIndex, placesCount)
        if (currentPlace != places[i].placeAlias) {
            setNextPlace(true)
        }

    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }

        print("[kate weatherWidget] " + msg)
    }
    function dbgprint2(msg) {
        if (!debugLogging) {
            return
        }
        console.log("\n\n")
        console.log("*".repeat(msg.length + 4))
        console.log("* " + msg +" *")
        console.log("*".repeat(msg.length + 4))
    }

    function getLocalTimeZone() {
        return dataSource.data["Local"]["Timezone Abbreviation"]
    }
    function dateNow() {
        var now=new Date().getTime()
        return now
    }

    function setCurrentProviderAccordingId(providerId) {
        currentPlace.providerId = providerId
        if (providerId === "owm") {
            dbgprint("setting provider OpenWeatherMap")
            return owmProvider
        }
        if (providerId === "metno") {
            dbgprint("setting provider metno")
            return metnoProvider
        }
    }
    function emptyWeatherModel() {
        return {
            temperature: -9999,
            iconName: 0,
            windDirection: 0,
            windSpeedMps: 0,
            pressureHpa: 0,
            humidity: 0,
            cloudiness: 0,
            sunRise: new Date("2000-01-01T00:00:00"),
            sunSet: new Date("2000-01-01T00:00:00"),
            sunRiseTime: "0:00",
            sunSetTime: "0:00",
            isDay: false,
            nearFutureWeather: {
                iconName: null,
                temperature: null
            }
        }
    }
    function setNextPlace(initial,direction) {
        if (direction === undefined) {
            direction = "+"
        }
        currentWeatherModel=emptyWeatherModel()
        nextDaysModel.clear()
        meteogramModel.clear()


        var places = ConfigUtils.getPlacesArray()
        placesCount = places.length
        var placeIndex = plasmoid.configuration.placeIndex
        dbgprint("places count=" + placesCount + ", placeIndex=" + plasmoid.configuration.placeIndex)
        if (!initial) {
            (direction === "+") ? placeIndex++ : placeIndex--
        }
        if (placeIndex > places.length - 1) {
            placeIndex = 0
        }
        if (placeIndex < 0 ) {
            placeIndex = places.length - 1
        }
        plasmoid.configuration.placeIndex = placeIndex
        dbgprint("placeIndex now: " + plasmoid.configuration.placeIndex)
        var placeObject = places[placeIndex]

        currentPlace.identifier = placeObject.placeIdentifier
        currentPlace.alias = placeObject.placeAlias
        currentPlace.timezoneID = placeObject.timezoneID
        currentPlace.providerId = placeObject.providerId
        currentPlace.provider = setCurrentProviderAccordingId(placeObject.providerId)

        if (placeObject.timezoneID === undefined) {
            currentPlace.timezoneID = -1
        } else {
            currentPlace.timezoneID = parseInt(placeObject.timezoneID)
        }


        let tzData = TZ.TZData[currentPlace.timezoneID]
        currentPlace.timezoneShortName = "LOCAL"
        if (currentPlace.providerId === "metno") {
            if (TZ.isDST(tzData.DSTData)){
                currentPlace.timezoneShortName = tzData.DSTName
                currentPlace.timezoneOffset = parseInt(tzData.DSTOffset)
            } else {
                currentPlace.timezoneShortName = tzData.TZName
                currentPlace.timezoneOffset = parseInt(tzData.Offset)
            }
        }

        fullRepresentationAlias = currentPlace.alias


        cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
        currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)
        dbgprint("cacheKey for " + currentPlace.identifier + " is: " + currentPlace.cacheID)
        cacheData.alreadyLoadedFromCache = false

        var ok = loadFromCache()
        dbgprint("CACHE " + ok)
        if (!ok) {
            loadDataFromInternet()
        }
    }
    function loadDataFromInternet() {
        dbgprint2("loadDataFromInternet")

        if (loadingData.loadingDatainProgress) {
            dbgprint("still loading")
            return
        }
        loadingDataComplete = false
        loadingData.loadingDatainProgress = true
        loadingData.lastloadingStartTime = dateNow()
        loadingData.nextReload = -1
        currentPlace.provider = setCurrentProviderAccordingId(currentPlace.providerId)
        currentPlace.creditLink = currentPlace.provider.getCreditLink(currentPlace.identifier)
        currentPlace.creditLabel = currentPlace.provider.getCreditLabel(currentPlace.identifier)
        loadingData.loadingXhrs = currentPlace.provider.loadDataFromInternet(
                    dataLoadedFromInternet,
                    reloadDataFailureCallback,
                    { placeIdentifier: currentPlace.identifier, timezoneID: currentPlace.timezoneID })

    }
    function dataLoadedFromInternet() {
        dbgprint2("dataLoadedFromInternet")
        dbgprint("Data Loaded From Internet successfully.")

        loadingData.lastloadingSuccessTime = dateNow()
        loadingData.loadingDatainProgress = false
        loadingData.nextReload = dateNow() + timerData.reloadIntervalMs
        loadingData.failedAttemptCount = 0
        currentPlace.nextReload = dateNow() + timerData.reloadIntervalMs
        dbgprint(dateNow() + " + " +  timerData.reloadIntervalMs + " = " + loadingData.nextReload)

        nextDaysCount = nextDaysModel.count

        updateLastReloadedText()
        updateCompactItem()
        refreshTooltipSubText()
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)
        meteogramModelChanged = !meteogramModelChanged
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)

        saveToCache()
    }
    function reloadDataFailureCallback() {
        dbgprint("Failed to Load Data successfully.")
        cacheData.loadingDatainProgress = false
        dbgprint("Error getting weather data. Scheduling data reload...")
        loadingData.nextReload = dateNow()
        loadFromCache()
    }
    function updateLastReloadedText() {
        dbgprint("updateLastReloadedText: " + loadingData.lastloadingSuccessTime)
        if (loadingData.lastloadingSuccessTime > 0) {
            lastReloadedText = '⬇ ' + i18n("%1 ago", DataLoader.getLastReloadedTimeText(dateNow() - loadingData.lastloadingSuccessTime))
        }
        plasmoid.status = DataLoader.getPlasmoidStatus(loadingData.lastloadingSuccessTime, inTrayActiveTimeoutSec)
        dbgprint(plasmoid.status)
    }
    function updateCompactItem(){
        dbgprint2("updateCompactItem")
        dbgprint(JSON.stringify(currentWeatherModel))
        let icon = currentWeatherModel.iconName
        iconNameStr = (icon > 0) ? IconTools.getIconCode(icon, currentPlace.providerId, currentWeatherModel.isDay) : '\uf07b'
        temperatureStr = currentWeatherModel.temperature !== 9999 ? UnitUtils.getTemperatureNumberExt(currentWeatherModel.temperature, temperatureType) : '--'
    }

    function refreshTooltipSubText() {
        // dbgprint(JSON.stringify(currentWeatherModel))
        dbgprint2("refreshTooltipSubText")
        if (currentWeatherModel === undefined || currentWeatherModel.nearFutureWeather.iconName === null || currentWeatherModel.count === 0) {
            dbgprint("model not yet ready")
            return
        }
        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }
        // for(const [key,value] of Object.entries(currentWeatherModel)) { console.log(`  ${key}: ${value}`) }

        var nearFutureWeather = currentWeatherModel.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentPlace.providerId, (currentWeatherModel.isDay ? 0 : 1))
        var wind1=Math.round(currentWeatherModel.windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var subText = ""
        subText += "<br /><font size=\"4\" style=\"font-family: weathericons;\">" + windDirectionIcon + "</font><font size=\"4\"> " + wind1 + "\u00B0 &nbsp; @ " + UnitUtils.getWindSpeedText(currentWeatherModel.windSpeedMps, windSpeedType) + "</font>"
        subText += "<br /><font size=\"4\">" + UnitUtils.getPressureText(currentWeatherModel.pressureHpa, pressureType) + "</font>"
        subText += "<br /><table>"
        if ((currentWeatherModel.humidity !== undefined) && (currentWeatherModel.cloudiness !== undefined)) {
            subText += "<tr>"
            subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf07a</font>&nbsp;" + currentWeatherModel.humidity + "%</font></td>"
            subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf013</font>&nbsp;" + currentWeatherModel.cloudiness + "%</font></td>"
            subText += "</tr>"
            subText += "<tr><td>&nbsp;</td><td></td></tr>"
        }
        subText += "<tr>"
        let tzName = "GMT"
        if (timezoneType === 0) { tzName = getLocalTimeZone() }
        if (timezoneType === 1) { tzName = "GMT" }
        if (timezoneType === 2) { tzName = currentPlace.timezoneShortName }
        subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf051</font>&nbsp;" + currentWeatherModel.sunRiseTime + " " + tzName + "&nbsp;&nbsp;&nbsp;</font></td>"
        subText += "</tr>"
        subText += "<tr>"
        subText += "<td><font size=\"4\"><font style=\"font-family: weathericons\">\uf052</font>&nbsp;" + currentWeatherModel.sunSetTime + " " + tzName + "</font></td>"
        subText += "</tr>"
        subText += "</table>"

        subText += "<br /><br />"
        subText += "<font size=\"3\">" + i18n("near future") + "</font>"
        subText += "<b>"
        subText += "<font size=\"6\">&nbsp;&nbsp;&nbsp;" + UnitUtils.getTemperatureNumber(nearFutureWeather.temperature, temperatureType) + UnitUtils.getTemperatureEnding(temperatureType)
        subText += "&nbsp;&nbsp;&nbsp;<font style=\"font-family: weathericons\">" + futureWeatherIcon + "</font></font>"
        subText += "</b>"
        toolTipMainText = currentPlace.alias
        toolTipSubText = subText
    }

    Component.onCompleted: {
        dbgprint2("MAIN.QML")
        dbgprint((currentPlace))

        if (plasmoid.configuration.firstRun) {
            let URL =  Qt.resolvedUrl("../code/db/GI.csv")   // DEBUGGING ONLY
            var xhr = new XMLHttpRequest()
            xhr.timeout = loadingData.loadingDataTimeoutMs;
            dbgprint('Test local file opening - url: ' + URL)
            xhr.open('GET', URL)
            xhr.setRequestHeader("User-Agent","Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 ")
            xhr.send()
            xhr.onload =  (event) => {
                dbgprint("env_QML_XHR_ALLOW_FILE_READ = 1. Using Builtin Location databases...")
                env_QML_XHR_ALLOW_FILE_READ = true
            }

            if (plasmoid.configuration.widgetFontSize === undefined) {
                plasmoid.configuration.widgetFontSize = 32
                widgetFontSize = 32
            }

            switch (Qt.locale().measurementSystem) {
            case (Locale.MetricSystem):
                plasmoid.configuration.temperatureType = 0
                plasmoid.configuration.pressureType = 0
                plasmoid.configuration.windSpeedType = 2
                break;
            case (Locale.ImperialUSSystem):
                plasmoid.configuration.temperatureType = 1
                plasmoid.configuration.pressureType = 1
                plasmoid.configuration.windSpeedType = 1
                break;
            case (Locale.ImperialUKSystem):
                plasmoid.configuration.temperatureType = 0
                plasmoid.configuration.pressureType = 0
                plasmoid.configuration.windSpeedType = 1
                break;
            }
            plasmoid.configuration.firstRun = false
        }
        timerData.reloadIntervalMin=plasmoid.configuration.reloadIntervalMin
        timerData.reloadIntervalMs=timerData.reloadIntervalMin * 60000

        dbgprint("plasmoid.formFactor:" + plasmoid.formFactor)
        dbgprint("plasmoid.location:" + plasmoid.location)
        dbgprint("plasmoid.configuration.layoutType:" + plasmoid.configuration.layoutType)
        dbgprint("plasmoid.containment.containmentType:" + plasmoid.containment.containmentType)
        if (inTray) {
            dbgprint("IN TRAY!")
        }

        dbgprint2(" Load Cache")
        var cacheContent = weatherCache.readCache()

        dbgprint("readCache result length: " + cacheContent.length)

        // fill cache
        if (cacheContent) {
            try {
                cacheData.cacheMap = JSON.parse(cacheContent)
                dbgprint("cacheMap initialized - keys:")
                for (var key in cacheData.cacheMap) {
                    dbgprint("  " + key + ", data: " + cacheData.cacheMap[key])
                }
            } catch (error) {
                dbgprint("error parsing cacheContent")
            }
        }
        cacheData.cacheMap = cacheData.cacheMap || {}

        dbgprint2("get Default Place")
        setNextPlace(true)

    }

    onTimezoneTypeChanged: {
        if (currentPlace.identifier !== "") {
            dbgprint2('timezoneType changed')
            cacheData.cacheKey = DataLoader.generateCacheKey(currentPlace.identifier)
            currentPlace.cacheID = DataLoader.generateCacheKey(currentPlace.identifier)
            dbgprint("cacheKey for " + currentPlace.identifier + " is: " + currentPlace.cacheID)
            cacheData.alreadyLoadedFromCache = false
            loadDataFromInternet()
            meteogramModelChanged = ! meteogramModelChanged
        }
    }

    function loadFromCache() {
        dbgprint2("loadFromCache")
        dbgprint('loading from cache, config key: ' + cacheData.cacheKey)

        if (cacheData.alreadyLoadedFromCache) {
            dbgprint('already loaded from cache')
            return true
        }
        if (!cacheData.cacheMap || !cacheData.cacheMap[cacheData.cacheKey]) {
            dbgprint('cache not available')
            return false
        }

        currentPlace = JSON.parse(cacheData.cacheMap[cacheData.cacheKey][1])
        currentPlace.provider = setCurrentProviderAccordingId(currentPlace.providerId)

        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }

        currentWeatherModel = cacheData.cacheMap[cacheData.cacheKey][2]
        // dbgprint("currentPlace:\t"  + currentPlace.alias + "\t" + currentPlace.identifier + "\t" + currentPlace.timezoneID + "\t" + currentPlace.timezoneShortName + "\t")
        // dbgprint(JSON.stringify(currentWeatherModel))
        let meteogramModelData = JSON.parse( cacheData.cacheMap[cacheData.cacheKey][3])
        let nextDaysModelData = JSON.parse( cacheData.cacheMap[cacheData.cacheKey][4])
        // dbgprint(cacheData.cacheMap[cacheData.cacheKey][4])
        meteogramModel.clear()
        for (var i = 0; i < meteogramModelData.length; ++i) {
            meteogramModelData[i]['from'] = new Date(Date.parse(meteogramModelData[i]['from']))
            meteogramModelData[i]['to'] = new Date(Date.parse(meteogramModelData[i]['to']))
            meteogramModel.append(meteogramModelData[i])
        }

        nextDaysModel.clear()
        for (var i = 0; i < nextDaysModelData.length; ++i) {
            // meteogramModelData[i]['from'] = new Date(Date.parse(meteogramModelData[i]['from']))
            // meteogramModelData[i]['to'] = new Date(Date.parse(meteogramModelData[i]['to']))
            nextDaysModel.append(nextDaysModelData[i])
        }
        dbgprint(nextDaysModelData.length)
        nextDaysCount = nextDaysModel.count

        updateCompactItem()
        refreshTooltipSubText()
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)
        meteogramModelChanged = !meteogramModelChanged
        dbgprint("meteogramModelChanged:" + meteogramModelChanged)

        return true
    }
    function saveToCache() {
        dbgprint2("saveCache")
        dbgprint(currentPlace.alias)
        let cacheID = currentPlace.cacheID


        var meteogramModelData = ([])
        for (var i = 0; i < meteogramModel.count; ++i) {
            meteogramModelData.push(meteogramModel.get(i))
        }

        var nextDayModelData = ([])
        for (i = 0; i < nextDaysModel.count; ++i) {
            // dbgprint(JSON.stringify(nextDaysModel.get(i)))
            nextDayModelData.push(nextDaysModel.get(i))
        }
        currentPlace.provider = ""
        // for(const [key,value] of Object.entries(currentPlace)) { console.log(`  ${key}: ${value}`) }

        let contentToCache = {1: JSON.stringify(currentPlace), 2: currentWeatherModel, 3: JSON.stringify(meteogramModelData), 4: JSON.stringify(nextDayModelData)}
        print("saving cacheKey = " + cacheID)
        cacheData.cacheMap[cacheID] = contentToCache
    }


    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            dbgprint2("Timer Triggered")
            var now=dateNow()
            dbgprint("*** loadingData Flag : " + loadingData.loadingDatainProgress)
            dbgprint("*** loadingData failedAttemptCount : " + loadingData.failedAttemptCount)
            dbgprint("*** Last Load Success: " + (loadingData.lastloadingSuccessTime))
            dbgprint("*** Next Load Due    : " + (currentPlace.nextReload))
            dbgprint("*** Time Now         : " + now)
            dbgprint("*** Next Load in     : " + Math.round((currentPlace.nextReload - now) / 1000) + " sec = "+ ((currentPlace.nextReload - now) / 60000).toFixed(2) + " min")

            updateLastReloadedText()
            // if ((loadingData.lastloadingSuccessTime === 0) && (updatingPaused)) {
                // currentPlace.nextReload=now + 60000()
            // }

            if (loadingData.loadingDatainProgress) {
                dbgprint("Timeout in:" + (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs - now))
                if (now > (loadingData.lastloadingStartTime + loadingData.loadingDataTimeoutMs)) {
                    loadingData.failedAttemptCount++
                    let retryTime = Math.min(loadingData.failedAttemptCount, 30) * 30
                    console.log("Timed out downloading weather data - aborting attempt. Retrying in " + retryTime  +" seconds time.")
                    loadingData.loadingDatainProgress = false
                    loadingData.lastloadingSuccessTime = 0
                    currentPlace.nextReload = now + (retryTime * 1000)
                    loadingDataComplete = true
                }
            } else {
                if (now > currentPlace.nextReload) {
                    loadDataFromInternet()
                }
            }

        }
    }


}
