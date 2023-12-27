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



PlasmoidItem {
    id: main

    toolTipSubText: ''
    toolTipMainText:''
// toolTipItem.enabled = false

    property string toolTipArea
    property string placeIdentifier
    property string placeAlias
    property string cacheKey
    property int timezoneID
    property string timezoneShortName
    property int timezoneOffset
    property var cacheMap: {}
    property bool renderMeteogram: plasmoid.configuration.renderMeteogram
    property int temperatureType: plasmoid.configuration.temperatureType
    property int pressureType: plasmoid.configuration.pressureType
    property int windSpeedType: plasmoid.configuration.windSpeedType
    property int timezoneType: plasmoid.configuration.timezoneType
    property string widgetFontName: plasmoid.configuration.widgetFontName
    property int widgetFontSize: plasmoid.configuration.widgetFontSize

    property bool twelveHourClockEnabled: Qt.locale().timeFormat(Locale.ShortFormat).toString().indexOf('AP') > -1
    property string placesJsonStr: plasmoid.configuration.places
    property bool onlyOnePlace: true

    property string datetimeFormat: 'yyyy-MM-dd\'T\'hh:mm:ss'
    property var xmlLocale: Qt.locale('en_GB')
    property var additionalWeatherInfo: {}

    property string overviewImageSource
    property string creditLink
    property string creditLabel

    property int reloadIntervalMin: plasmoid.configuration.reloadIntervalMin   // Download Attempt Frequency in minutes
    property int reloadIntervalMs: reloadIntervalMin * 60 * 1000               // Download Attempt Frequency in milliseconds


    property double lastloadingStartTime: 0       // Time download last attempted.
    property double lastloadingSuccessTime: 0     // Time download last successful.
    property double nextReload: 0                 // Time next download is due.

    property bool loadingData: false              // Download Attempt in progress Flag.
    property int loadingDataTimeoutMs: 15000      // Download Timeout in ms.
    property var loadingXhrs: []                  // Array of Download Attempt Objects
    property bool loadingError: false             // Whether the last Download Attempt was successful
    property bool imageLoadingError: true
    property bool alreadyLoadedFromCache: false

    property string lastReloadedText: '⬇ 0m ago'
    property string tooltipSubText: ''


    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    property bool onDesktop: (plasmoid.location == PlasmaCore.Types.Desktop || plasmoid.location == PlasmaCore.Types.Floating)
    property bool inTray: false
    property string plasmoidCacheId: plasmoid.id

    property int inTrayActiveTimeoutSec: plasmoid.configuration.inTrayActiveTimeoutSec

    property int nextDaysCount: 8

    property bool textColorLight: ((Kirigami.Theme.textColor.r + Kirigami.Theme.textColor.g + Kirigami.Theme.textColor.b) / 3) > 0.5

    // 0 - standard
    // 1 - vertical
    // 2 - compact
    property int layoutType: plasmoid.configuration.layoutType

    property var currentProvider: null

    property bool updatingPaused: true
    property bool meteogramModelChanged: false

    anchors.fill: parent

    fullRepresentation: FullRepresentation {  }
    compactRepresentation: CompactRepresentation {  }
    preferredRepresentation: compactRepresentation

    property bool debugLogging: plasmoid.configuration.debugLogging

    FontLoader {
        source: '../fonts/weathericons-regular-webfont-2.0.10.ttf'
    }

    MetNo {
        id: metnoProvider
    }

    ListModel {
        id: actualWeatherModel
    }

    ListModel {
        id: nextDaysModel
    }

    ListModel {
        id: meteogramModel
    }

    function action_toggleUpdatingPaused() {
        // updatingPaused = !updatingPaused
        // abortTooLongConnection(true)
        // Plasmoid.setAction('toggleUpdatingPaused', updatingPaused ? i18n("Resume Updating") : i18n("Pause Updating"), updatingPaused ? 'media-playback-start' : 'media-playback-pause');
    }

    WeatherCache {
        id: weatherCache
        cacheId: plasmoidCacheId
    }

    Plasma5Support.DataSource {
        id: dataSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 0
    }

    Component.onCompleted: {
        if (plasmoid.configuration.firstRun) {
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
        dbgprint(plasmoid.formFactor)
        dbgprint(plasmoid.location)
        // inTray = (plasmoid.parent !== null && (plasmoid.parent.pluginName === 'org.kde.plasma.private.systemtray' || plasmoid.parent.objectName === 'taskItemContainer'))
        // plasmoidCacheId = inTray ? plasmoid.parent.id : plasmoid.id
        // dbgprint('inTray=' + inTray + ', plasmoidCacheId=' + plasmoidCacheId)

        additionalWeatherInfo = {
            sunRise: new Date('2000-01-01T00:00:00'),
            sunSet: new Date('2000-01-01T00:00:00'),
            sunRiseTime: '0:00',
            sunSetTime: '0:00',
            nearFutureWeather: {
                iconName: null,
                temperature: null
            }
        }

        // systray settings
        if (inTray) {
            Plasmoid.compactRepresentation = crInTray
            Plasmoid.fullRepresentation = frInTray
        }


        action_toggleUpdatingPaused()
        // init contextMenu

        var cacheContent = weatherCache.readCache()

        // fill xml cache xml
        if (cacheContent) {
            try {
                cacheMap = JSON.parse(cacheContent)
                dbgprint('cacheMap initialized - keys:')
                for (var key in cacheMap) {
                    dbgprint('  ' + key + ', data: ' + cacheMap[key])
                }
            } catch (error) {
                dbgprint('error parsing cacheContent')
            }
        }
        cacheMap = cacheMap || {}

        // set initial place
       setNextPlace(true)
    }

    onTimezoneShortNameChanged: {
        refreshTooltipSubText()
    }

    onPlacesJsonStrChanged: {
        if (placesJsonStr === '') {
            return
        }
        onlyOnePlace = ConfigUtils.getPlacesArray().length === 1
        setNextPlace(true)
    }

    function showData() {
        var ok = loadFromCache()
        if (!ok) {
            reloadData()
        }
        updateLastReloadedText()
        reloadMeteogram()
    }

    function setCurrentProviderAccordingId(providerId) {
        if (providerId === 'owm') {
            dbgprint('setting provider OpenWeatherMap')
            currentProvider = owmProvider
        }
        if (providerId === "metno") {
            dbgprint('setting provider metno')
            currentProvider = metnoProvider
        }
    }

    function setNextPlace(initial,direction) {
        actualWeatherModel.clear()
        nextDaysModel.clear()
        meteogramModel.clear()
        if (direction === undefined) {
            direction = "+"
        }

        var places = ConfigUtils.getPlacesArray()
        onlyOnePlace = places.length === 1
        dbgprint('places count=' + places.length + ', placeIndex=' + plasmoid.configuration.placeIndex)
        var placeIndex = plasmoid.configuration.placeIndex
        if (!initial) {
            (direction === "+") ? placeIndex++ :placeIndex--
        }
        if (placeIndex > places.length - 1) {
            placeIndex = 0
        }
        if (placeIndex < 0 ) {
            placeIndex = places.length - 1
        }
        plasmoid.configuration.placeIndex = placeIndex
        dbgprint('placeIndex now: ' + plasmoid.configuration.placeIndex)
        var placeObject = places[placeIndex]
        placeIdentifier = placeObject.placeIdentifier
        placeAlias = placeObject.placeAlias
        if (placeObject.timezoneID  === undefined ) {
            placeObject.timezoneID = -1
        }
        timezoneID = parseInt(placeObject.timezoneID)
        dbgprint('next placeIdentifier is: ' + placeIdentifier)
        cacheKey = DataLoader.generateCacheKey(placeIdentifier)
        dbgprint('next cacheKey is: ' + cacheKey)

        alreadyLoadedFromCache = false

        setCurrentProviderAccordingId(placeObject.providerId)

        timezoneShortName = getLocalTimeZone()
        showData()
    }

    function dataLoadedFromInternet(contentToCache) {
        dbgprint("Data Loaded From Internet successfully.")
        loadingData = false
        nextReload=dateNow() + reloadIntervalMs
        dbgprint('saving cacheKey = ' + cacheKey)
        cacheMap[cacheKey] = contentToCache
        dbgprint('cacheMap now has these keys:')
        for (var key in cacheMap) {
            dbgprint('  ' + key)
        }
        alreadyLoadedFromCache = false
        weatherCache.writeCache(JSON.stringify(cacheMap))

        reloadMeteogram()
        lastloadingSuccessTime=dateNow()
        updateLastReloadedText()

        loadFromCache()
    }

    function reloadDataFailureCallback() {
        dbgprint("Failed to Load Data successfully.")
        main.loadingData = false
        handleLoadError()
    }

    function reloadData() {
        dbgprint("reloadData")

        if (loadingData) {
            dbgprint('still loading')
            return
        }

        loadingData = true
        lastloadingStartTime=dateNow()
        loadingXhrs = currentProvider.loadDataFromInternet(dataLoadedFromInternet, reloadDataFailureCallback, { placeIdentifier: placeIdentifier, timezoneID: timezoneID })

    }

    function reloadMeteogram() {
        currentProvider.reloadMeteogramImage(placeIdentifier)
    }

    function loadFromCache() {
        dbgprint('loading from cache, config key: ' + cacheKey)

        if (alreadyLoadedFromCache) {
            dbgprint('already loaded from cache')
            return true
        }

        creditLink = currentProvider.getCreditLink(placeIdentifier)
        creditLabel = currentProvider.getCreditLabel(placeIdentifier)

        if (!cacheMap || !cacheMap[cacheKey]) {
            dbgprint('cache not available')
            return false
        }

        var success = currentProvider.setWeatherContents(cacheMap[cacheKey])
        if (!success) {
            dbgprint('setting weather contents not successful')
            return false
        }

        alreadyLoadedFromCache = true
        return true
    }

    function handleLoadError() {
        dbgprint('Error getting weather data. Scheduling data reload...')
        nextReload = dateNow()
        loadFromCache()
    }

    onInTrayActiveTimeoutSecChanged: {
        if (placesJsonStr === '') {
            return
        }
        updateLastReloadedText()
    }

    function updateLastReloadedText() {
        dbgprint("updateLastReloadedText: " + lastloadingSuccessTime)
        if (lastloadingSuccessTime > 0) {
            lastReloadedText = '⬇ ' + i18n("%1 ago", DataLoader.getLastReloadedTimeText(dateNow() - lastloadingSuccessTime))
        }
        plasmoid.status = DataLoader.getPlasmoidStatus(lastloadingSuccessTime, inTrayActiveTimeoutSec)
    }

    function updateAdditionalWeatherInfoText() {
        if (additionalWeatherInfo !== undefined) {
            var sunRise = UnitUtils.convertDate(additionalWeatherInfo.sunRise, timezoneType, timezoneOffset)
            var sunSet = UnitUtils.convertDate(additionalWeatherInfo.sunSet, timezoneType, timezoneOffset)
            additionalWeatherInfo.sunRiseTime = Qt.formatTime(sunRise, Qt.locale().timeFormat(Locale.ShortFormat))
            additionalWeatherInfo.sunSetTime = Qt.formatTime(sunSet, Qt.locale().timeFormat(Locale.ShortFormat))
        }
    }

    function refreshTooltipSubText() {
        dbgprint('refreshing sub text')
        if (additionalWeatherInfo === undefined || additionalWeatherInfo.nearFutureWeather.iconName === null || actualWeatherModel.count === 0) {
            dbgprint('model not yet ready')
            return
        }
        updateAdditionalWeatherInfoText()
        var nearFutureWeather = additionalWeatherInfo.nearFutureWeather
        var futureWeatherIcon = IconTools.getIconCode(nearFutureWeather.iconName, currentProvider.providerId, getPartOfDayIndex())
        var wind1=Math.round(actualWeatherModel.get(0).windDirection)
        var windDirectionIcon = IconTools.getWindDirectionIconCode(wind1)
        var subText = ''
        subText += '<br /><font size="4" style="font-family: weathericons;">' + windDirectionIcon + '</font><font size="4"> ' + wind1 + '\u00B0 &nbsp; @ ' + UnitUtils.getWindSpeedText(actualWeatherModel.get(0).windSpeedMps, windSpeedType) + '</font>'
        subText += '<br /><font size="4">' + UnitUtils.getPressureText(actualWeatherModel.get(0).pressureHpa, pressureType) + '</font>'
        subText += '<br /><table>'
        if ((actualWeatherModel.get(0).humidity !== undefined) && (actualWeatherModel.get(0).cloudiness !== undefined)) {
            subText += '<tr>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf07a</font>&nbsp;' + actualWeatherModel.get(0).humidity + '%</font></td>'
            subText += '<td><font size="4"><font style="font-family: weathericons">\uf013</font>&nbsp;' + actualWeatherModel.get(0).cloudiness + '%</font></td>'
            subText += '</tr>'
            subText += '<tr><td>&nbsp;</td><td></td></tr>'
        }
        subText += '<tr>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf051</font>&nbsp;' + additionalWeatherInfo.sunRiseTime + ' '+timezoneShortName + '&nbsp;&nbsp;&nbsp;</font></td>'
        subText += '<td><font size="4"><font style="font-family: weathericons">\uf052</font>&nbsp;' + additionalWeatherInfo.sunSetTime + ' '+timezoneShortName + '</font></td>'
        subText += '</tr>'
        subText += '</table>'

        subText += '<br /><br />'
        subText += '<font size="3">' + i18n("near future") + '</font>'
        subText += '<b>'
        subText += '<font size="6">&nbsp;&nbsp;&nbsp;' + UnitUtils.getTemperatureNumber(nearFutureWeather.temperature, temperatureType) + UnitUtils.getTemperatureEnding(temperatureType)
        subText += '&nbsp;&nbsp;&nbsp;<font style="font-family: weathericons">' + futureWeatherIcon + '</font></font>'
        subText += '</b>'
        tooltipSubText = subText
        dbgprint(subText)
    }

    function getPartOfDayIndex() {
        var now = new Date().getTime()
        let sunrise1 = additionalWeatherInfo.sunRise.getTime()
        let sunset1 = additionalWeatherInfo.sunSet.getTime()
        let icon = ((now > sunrise1) && (now < sunset1)) ? 0 : 1
        // setDebugFlag(true)
        dbgprint(JSON.stringify(additionalWeatherInfo))
        dbgprint("NOW = " + now + "\tSunrise = " + sunrise1 + "\tSunset = " + sunset1 + "\t" + (icon === 0 ? "isDay" : "isNight"))
        dbgprint("\t > Sunrise:" + (now > sunrise1) + "\t\t Sunset:" + (now < sunset1))
        // setDebugFlag(false)

        return icon
    }

    function abortTooLongConnection(forceAbort) {
        if (!loadingData) {
            return
        }
        if (forceAbort) {
            dbgprint('timeout reached, aborting existing xhrs')
            loadingXhrs.forEach(function (xhr) {
                xhr.abort()
            })
            reloadDataFailureCallback()
        } else {
            dbgprint('regular loading, no aborting yet')
            return
        }
    }

    function tryReload() {
        updateLastReloadedText()

        if (updatingPaused) {
            return
        }

        reloadData()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            var now=dateNow()
            dbgprint("*** Timer triggered")
            dbgprint("*** loadingData Flag : " + loadingData)
            dbgprint("*** Last Load Success: " + (lastloadingSuccessTime))
            dbgprint("*** Next Load Due    : " + (nextReload))
            dbgprint("*** Time Now         : " + now)
            dbgprint("*** Next Load in     : " + Math.round((nextReload - now) / 1000) + " sec = "+ ((nextReload - now) / 60000).toFixed(2) + " min")

            updateLastReloadedText()
            if ((lastloadingSuccessTime===0) && (updatingPaused)) {
                toggleUpdatingPaused()
            }

            if (loadingData) {
                dbgprint("Timeout in:" + (lastloadingStartTime + loadingDataTimeoutMs - now))
                if (now > (lastloadingStartTime + loadingDataTimeoutMs)) {
                    console.log("Timed out downloading weather data - aborting attempt. Retrying in 60 seconds time.")
                    abortTooLongConnection(true)
                    nextReload=now + 60000
                }
            } else {
                if (now > nextReload) {
                    tryReload()
                }
            }
        }
    }

    onTemperatureTypeChanged: {
        refreshTooltipSubText()
    }

    onPressureTypeChanged: {
        refreshTooltipSubText()
    }

    onWindSpeedTypeChanged: {
        refreshTooltipSubText()
    }

    onTwelveHourClockEnabledChanged: {
        refreshTooltipSubText()
    }

    onTimezoneTypeChanged: {
        if (lastloadingSuccessTime > 0) {
            refreshTooltipSubText()
        }
    }

    function dbgprint(msg) {
        if (!debugLogging) {
            return
        }

        print('[kate weatherWidget] ' + msg)
    }

    function dateNow() {
        var now=new Date().getTime()
        return now
    }

    function setDebugFlag(flag) {
        debugLogging = flag
    }

    function getLocalTimeZone() {
        return dataSource.data["Local"]["Timezone Abbreviation"]
    }
}
