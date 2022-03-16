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
import QtQuick 2.5
import QtQuick.Window 2.5
import QtQml.Models 2.5
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import QtQuick.Controls 2.5
import "../code/unit-utils.js" as UnitUtils
import "../code/icons.js" as IconTools

Item {
    visible: true
    width: imageWidth
    height: imageHeight + labelHeight// Day Label + Time Label

    property int imageWidth: 800 * units.devicePixelRatio - (labelWidth * 2)
    property int imageHeight: 320 * units.devicePixelRatio  - labelHeight - cloudarea - windarea
    property int labelWidth: textMetrics.width
    property int labelHeight: textMetrics.height

    property int cloudarea: 0
    property int windarea: 28

        property bool meteogramModelChanged: main.meteogramModelChanged


    property int temperatureYGridCount: 21   // Number of vertical grid Temperature elements
    property double temperatureIncrementDegrees: 0 // Major Step - How much each Temperature grid element rises by in Degrees
    property double temperatureIncrementPixels: imageHeight / (temperatureYGridCount - 1)  // Major Step - How much each Temperature grid element rises by in Pixels

    property int pressureSizeY: 101     // Number of virtual grid Pressure Elements
    property int pressureMultiplier: Math.round((pressureSizeY - 1) / (temperatureYGridCount - 1)) // Major Step - How much each Pressure grid element rises by in HPa

    property int pressureOffsetY: -950 // Move Pressure Graph down by 950
    property double pressureMultiplierY: imageHeight / (pressureSizeY - 1)// Major Step - How much each Pressure grid element rises by in Pixels
    property double topBottomCanvasMargin: (imageHeight / temperatureYGridCount) * 0.5

    property int dataArraySize: 2


    property bool textColorLight: ((theme.textColor.r + theme.textColor.g + theme.textColor.b) / 3) > 0.5
    property color gridColor: textColorLight ? Qt.tint(theme.textColor, '#80000000') : Qt.tint(theme.textColor, '#80FFFFFF')
    property color gridColorHighlight: textColorLight ? Qt.tint(theme.textColor, '#50000000') : Qt.tint(theme.textColor, '#50FFFFFF')
    property color pressureColor: textColorLight ? Qt.rgba(0.3, 1, 0.3, 1) : Qt.rgba(0.0, 0.6, 0.0, 1)
    property color temperatureWarmColor: textColorLight ? Qt.rgba(1, 0.3, 0.3, 1) : Qt.rgba(1, 0.0, 0.0, 1)
    property color temperatureColdColor: textColorLight ? Qt.rgba(0.2, 0.7, 1, 1) : Qt.rgba(0.1, 0.5, 1, 1)
    property color rainColor: textColorLight ? Qt.rgba(0.33, 0.66, 1, 1) : Qt.rgba(0, 0.33, 1, 1)


    property int precipitationFontPixelSize: 8 * units.devicePixelRatio
    property int precipitationHeightMultiplier: 15 * units.devicePixelRatio
    property int precipitationLabelMargin: 8 * units.devicePixelRatio

/*
    property int temperatureType: 0
    property int pressureType: 0
    property int timezoneType: 0
    property bool twelveHourClockEnabled: false
    property int windSpeedType: 0
*/
    property double sampleWidth: imageWidth / (meteogramModel.count - 1)

    onMeteogramModelChangedChanged: {
        dbgprint('meteogram changed')
        buildMetogramData()
        processMeteogramData()
        buildCurves()
    }


    ListModel {
        id: verticalGridModel
    }
    ListModel {
        id: hourGridModel
    }
    ListModel {
        id: actualWeatherModel
    }
    ListModel {
        id: nextDaysModel
    }
//     ListModel {
//         id: meteogramModel
//     }

    TextMetrics {
        id: textMetrics
        font.family: theme.defaultFont.family
        font.pixelSize: 11 * units.devicePixelRatio
        text: "999999"
    }

    Item {
        id: meteogram
        width: imageWidth + (labelWidth * 2)
        height: imageHeight + (labelHeight) + cloudarea + windarea
    }
    Rectangle {
        id: graphArea
        width: imageWidth
        height: imageHeight
        anchors.top: meteogram.top
        anchors.left: meteogram.left
        anchors.leftMargin: labelWidth
        anchors.rightMargin: labelWidth
        anchors.topMargin: labelHeight  + cloudarea
        border.color:gridColor
        color: "transparent"
    }
    ListView {
        id: horizontalLines1
        model: verticalGridModel
        anchors.left: graphArea.left
        anchors.top: graphArea.top
//         anchors.bottom: graphArea.bottom + labelHeight
//         anchors.fill: graphArea
        height: graphArea.height + labelHeight
        interactive: false
        delegate: Item {
            height: graphArea.height / (temperatureYGridCount - 1)
            width: graphArea.width
            visible:  num % 2 === 0

            Rectangle {
                id: gridLine
                width: parent.width
                height: 1 * units.devicePixelRatio
                color: gridColor
            }
            PlasmaComponents.Label {
                text: UnitUtils.getTemperatureNumberExt(-temperatureIncrementDegrees + (temperatureYGridCount - num), temperatureType)
                height: labelHeight
                width: labelWidth
                horizontalAlignment: Text.AlignRight
                anchors.left: gridLine.left
                anchors.top: gridLine.top
                anchors.leftMargin: -labelWidth - 2
                anchors.topMargin: -labelHeight / 2
                font.pixelSize: 11 * units.devicePixelRatio
                font.pointSize: -1
            }
            PlasmaComponents.Label {
                text: String(UnitUtils.getPressureNumber((pressureSizeY - 1 - num * pressureMultiplier) -pressureOffsetY, pressureType))
                height: labelHeight
                width: labelWidth
                anchors.top: gridLine.top
                anchors.topMargin: -labelHeight / 2
                anchors.left: gridLine.right
                anchors.leftMargin: 2
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 11 * units.devicePixelRatio
                font.pointSize: -1
                color: pressureColor
            }
        }
    }
    PlasmaComponents.Label {
        text: UnitUtils.getPressureEnding(pressureType)
        height: labelHeight
        width: labelWidth
        horizontalAlignment: (UnitUtils.getPressureEnding(pressureType).length > 4) ? Text.AlignRight : Text.AlignLeft
        anchors.right: (graphArea.right)
        anchors.rightMargin: -labelWidth
        font.pixelSize: 11 * units.devicePixelRatio
        font.pointSize: -1
        color: pressureColor
        anchors.bottom: graphArea.top
        anchors.bottomMargin: 6
    }
    ListView {
        id: hourGrid
        model: hourGridModel
        property double hourItemWidth: hourGridModel.count === 0 ? 0 : imageWidth / (hourGridModel.count - 1)
        anchors.fill: graphArea
        interactive: false
        orientation: ListView.Horizontal
        delegate: Item {
            height: labelHeight
            width: hourGrid.hourItemWidth

            property int hourFrom: dateFrom.getHours()
            property string hourFromStr: UnitUtils.getHourText(hourFrom, twelveHourClockEnabled)
            property string hourFromEnding: twelveHourClockEnabled ? UnitUtils.getAmOrPm(hourFrom) : '00'
            property bool dayBegins: hourFrom === 0
            property bool hourVisible: hourFrom % 2 === 0
            property bool textVisible: hourVisible && index < hourGridModel.count-1
            property int timePeriod: hourFrom >= 6 && hourFrom <= 18 ? 0 : 1


            property double precAvg: parseFloat(precipitationAvg) || 0
            property double precMax: parseFloat(precipitationMax) || 0

            property bool precLabelVisible: precAvg >= 0.1 || precMax >= 0.1

            property string precAvgStr: precipitationFormat(precAvg)
            property string precMaxStr: precipitationFormat(precMax)



            Rectangle {
                id: verticalLine
                width: dayBegins ? 2 : 1
                height: imageHeight
                color: dayBegins ? gridColorHighlight : gridColor
                visible: hourVisible
                anchors.leftMargin: labelWidth
                anchors.top: parent.top
            }
            anchors.leftMargin: labelWidth
            PlasmaComponents.Label {
                id: hourText
                text: hourFromStr
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                height: labelHeight
                width: hourGrid.hourItemWidth
                anchors.top: verticalLine.bottom
                anchors.topMargin: 2
                //                anchors.horizontalCenter: verticalLine.left
                anchors.horizontalCenter: verticalLine.horizontalCenter
                font.pixelSize: 11 * units.devicePixelRatio
                font.pointSize: -1
                visible: textVisible
            }
            PlasmaComponents.Label {
                text: hourFromEnding
                verticalAlignment: Text.AlignTop
                horizontalAlignment: Text.AlignLeft
                anchors.top: hourText.top
                anchors.left: hourText.right
                font.pixelSize: 7 * units.devicePixelRatio
                font.pointSize: -1
                visible: textVisible
            }
            function windFrom(rotation) {
                rotation = (Math.round( rotation / 22.5 ) * 22.5)
                rotation = (rotation >= 180) ? rotation - 180 : rotation + 180
                return rotation
            }
            function windStrength(windspeed,themecolor) {
                var img = "images/"
                img += (themecolor) ? "light" : "dark"
                img += Math.min(5,Math.trunc(windspeed / 5) + 1)
                return img
            }
            function precipitationFormat(precFloat) {
                if (precFloat >= 0.1) {
                    var result = Math.round(precFloat * 10) / 10
                    return String(result)
                }
                return ''
            }
            Item {
                id: windspeedAnchor
                width: parent.width
                height: 32
                anchors.top: hourText.bottom
                anchors.left: hourText.left

                ToolTip{
                    id: windspeedhover
                    text: (index % 2 == 1) ? UnitUtils.getWindSpeedText(windSpeedMps, windSpeedType) : ""
                    padding: 4
                    x: windspeedAnchor.width + 6
                    y: (windspeedAnchor.height / 2)
                    opacity: 1
                    visible: false
                }

                Image {
                    id: wind
                    source: windStrength(windSpeedMps,textColorLight)
                    anchors.horizontalCenter: parent.horizontalCenter
                    rotation: windFrom(windDirection)
                    anchors.top: windspeedAnchor.top
                    width: 16
                    height: 16
                    fillMode: Image.PreserveAspectFit
                    visible: (index % 2 == 1) && (index < hourGridModel.count-1)
                    anchors.leftMargin: -8
                    anchors.left: parent.left
                    //                    visible: ((windDirection > 0) || (windSpeedMps > 0)) && (! textVisible) && (index > 0) && (index < hourGridModel.count-1)
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        windspeedhover.visible = (windspeedhover.text.length > 0)
                    }

                    onExited: {
                        windspeedhover.visible = false
                    }
                }
            }
            PlasmaComponents.Label {
                id: dayTest
                text: Qt.locale().dayName(dateFrom.getDay(), Locale.LongFormat)
                height: labelHeight
                anchors.top: parent.top
                anchors.topMargin: -labelHeight
                anchors.left: parent.left
                anchors.leftMargin: parent.width / 2
                font.pixelSize: 11 * units.devicePixelRatio
                font.pointSize: -1
                visible: dayBegins && canShowDay
            }
            Rectangle {
                id: precipitationMaxRect
                width: parent.width
                height: (precMax < precAvg ? precAvg : precMax) * precipitationHeightMultiplier
                color: rainColor
                anchors.left: verticalLine.left
                anchors.bottom: verticalLine.bottom
                anchors.bottomMargin: precipitationLabelMargin
            }
            PlasmaComponents.Label {
                width: parent.width
                text: precMaxStr || precAvgStr
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                anchors.bottom: precipitationMaxRect.top
                anchors.horizontalCenter: precipitationMaxRect.horizontalCenter
                font.pixelSize: precipitationFontPixelSize
                font.pointSize: -1
                visible: precLabelVisible
            }
            PlasmaComponents.Label {
                function localisePrecipitationUnit(unitText) {
                    switch (unitText) {
                    case "mm":
                        return i18n("mm")
                    case "cm":
                        return i18n("cm")
                    case "in":
                        return i18n("in")
                    default:
                        return unitText
                    }
                }
                text: localisePrecipitationUnit(precipitationLabel)
                width: parent.width
                //                verticalAlignment: Text.AlignTop
                //                horizontalAlignment: Text.AlignHCenter
                anchors.left: verticalLine.left
                anchors.bottom: verticalLine.bottom
                //                anchors.bottom: verticalLine.bottom
                anchors.bottomMargin: -precipitationLabelMargin
                //                anchors.horizontalCenter: precipitationMaxRect.horizontalCenter
                font.pixelSize: precipitationFontPixelSize
                font.pointSize: -1
                visible: precLabelVisible
            }
            PlasmaComponents.Label {
                font.pixelSize: 14 * units.devicePixelRatio
                font.pointSize: -1
                width: parent.width
                anchors.top: parent.top
                anchors.topMargin: (temperatureYGridCount - (temperature + temperatureIncrementDegrees)) * temperatureIncrementPixels - font.pixelSize * 2.5
                anchors.left: verticalLine.left
                anchors.leftMargin: -8
                z: 999
                font.family: 'weathericons'
                text: (differenceHours === 1 && textVisible) || index === hourGridModel.count-1 || index === 0 || iconName === '' ? '' : IconTools.getIconCode(iconName, currentProvider.providerId, timePeriod)
                visible: iconName != "\uf07b"
                Component.onCompleted: {
//                   console.log(temperatureYGridCount +" - " + "(" + temperature + " + " + temperatureIncrementDegrees + ") * " +temperatureIncrementPixels + " - " +  font.pixelSize + " * 2.5")
                }
            }
            /*
            Item {
                visible: canShowPrec
//                anchors.fill: parent
                anchors.bottom: verticalLine.bottom



                Rectangle {
                    id: precipitationAvgRect
                    width: parent.width
                    height: precAvg * precipitationHeightMultiplier
                    color: theme.highlightColor
                    anchors.left: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: precipitationLabelMargin
                }

                PlasmaComponents.Label {
                    function localisePrecipitationUnit(unitText) {
                        switch (unitText) {
                        case "mm":
                            return i18n("mm")
                        case "cm":
                            return i18n("cm")
                        case "in":
                            return i18n("in")
                        default:
                            return unitText
                        }
                    }
                    text: localisePrecipitationUnit(precipitationLabel)
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignHCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: -precipitationLabelMargin
                    anchors.horizontalCenter: precipitationAvgRect.horizontalCenter
                    font.pixelSize: precipitationFontPixelSize
                    font.pointSize: -1
                    visible: precLabelVisible
                }
        }
*/

        }
    }

    Item {
        z: 1
        id: canvases
        anchors.fill: graphArea
        anchors.topMargin: 0
        Canvas {
            id: meteogramCanvasPressure
            anchors.fill: parent
            contextType: '2d'

            Path {
                id: pressurePath
                startX: 0
            }

            onPaint: {
                context.clearRect(0, 0, width, height)

                context.strokeStyle = pressureColor
                context.lineWidth = 1 * units.devicePixelRatio;
                context.path = pressurePath
                context.stroke()
            }
        }
        Canvas {
            id: meteogramCanvasWarmTemp
            anchors.top: imageWidth.top
            width: parent.width
            height: parent.height - temperatureIncrementPixels * (temperatureIncrementDegrees - 1) + 0

            onWidthChanged: {

                meteogramCanvasWarmTemp.requestPaint()
            }

            contextType: '2d'

            Path {
                id: temperaturePathWarm
                startX: 0
            }

            onPaint: {
                context.clearRect(0, 0, width, height)
                context.strokeStyle = temperatureWarmColor
                context.lineWidth = 2 * units.devicePixelRatio;
                context.path = temperaturePathWarm
                context.stroke()
            }
        }

        Item {

            anchors.fill: parent
            anchors.topMargin: meteogramCanvasWarmTemp.height
            clip: true
            Canvas {
                id: meteogramCanvasColdTemp
                anchors.top: parent.top
                width: imageWidth
                height: imageHeight
                anchors.topMargin: -parent.anchors.topMargin
                contextType: '2d'

                Path {
                    id: temperaturePathCold
                    startX: 0
                }

                onPaint: {
                    context.clearRect(0, 0, width, height)

                    context.strokeStyle = temperatureColdColor
                    context.lineWidth = 2 * units.devicePixelRatio;
                    context.path = temperaturePathCold
                    context.stroke()
                }
            }
        }
    }
    function repaintCanvas() {
        meteogramCanvasWarmTemp.requestPaint()
        meteogramCanvasColdTemp.requestPaint()
        meteogramCanvasPressure.requestPaint()
    }

    function parseISOString(s) {
        var b = s.split(/\D+/)
        return new Date(Date.UTC(b[0], --b[1], b[2], b[3], b[4], b[5], b[6]))
    }

    function buildMetogramData() {
        var precipitation_unit = meteogramModel.get(0).precipitationLabel
        var counter = 0
        var i = 0
        const oneHourMs = 3600000
        hourGridModel.clear()

        while (i < meteogramModel.count) {
            var obj = meteogramModel.get(i)
            var dateFrom = obj.from
            var dateTo = obj.to
            dateFrom.setMinutes(0)
            dateFrom.setSeconds(0)
            dateFrom.setMilliseconds(0)
            var differenceHours = Math.floor((dateTo.getTime() - dateFrom.getTime()) / oneHourMs)
            dbgprint(dateFrom + "\t" + dateTo + "\t" + differenceHours)
            var differenceHoursMid = Math.ceil(differenceHours / 2) - 1
            var wd = obj.windDirection
            var ws = obj.windSpeedMps
            var ap = obj.pressureHpa
            var airtmp = parseFloat(obj.temperature)
            var icon = obj.iconName
            var prec = obj.precipitationAvg

            for (var j = 0; j < differenceHours; j++) {
                counter = (prec > 0) ? counter + 1 : 0
                var preparedDate = new Date(dateFrom.getTime() + (j * oneHourMs))

                hourGridModel.append({
                                      dateFrom: UnitUtils.convertDate(preparedDate, timezoneType),
                                      iconName: j === differenceHoursMid ? icon : '',
                                      temperature: airtmp,
                                      precipitationAvg: parseFloat(prec / differenceHours).toFixed(1),
                                      precipitationLabel: (counter === 1) ? "mm" : "",
                                      precipitationMax: parseFloat(prec / differenceHours).toFixed(1),
                                      canShowDay: true,
                                      canShowPrec: true,
                                      windDirection: parseFloat(wd),
                                      windSpeedMps: parseFloat(ws),
                                      pressureHpa: parseFloat(ap),
                                      differenceHours: differenceHours
                                  })
            }
            i++
        }
        for (i = hourGridModel.count - 5; i < hourGridModel.count; i++) {
            hourGridModel.setProperty(i, 'canShowDay', false)
        }
        hourGridModel.setProperty(hourGridModel.count - 1, 'canShowPrec', false)
    }
    function buildCurves() {
        var newPathElements = []
        var newPressureElements = []

        if (meteogramModel.count === 0) {
            return
        }
        for (var i = 0; i < meteogramModel.count; i++) {
            var dataObj = meteogramModel.get(i)

            var rawTempY = temperatureYGridCount - (dataObj.temperature + temperatureIncrementDegrees)
            var temperatureY = rawTempY * temperatureIncrementPixels
            var rawPressY = pressureSizeY - (dataObj.pressureHpa + pressureOffsetY)
            var pressureY = rawPressY * pressureMultiplierY
            if (i === 0) {
                temperaturePathWarm.startY = temperatureY
                temperaturePathCold.startY = temperatureY
                pressurePath.startY = pressureY
            }
            newPathElements.push(Qt.createQmlObject('import QtQuick 2.0; PathCurve { x: ' + (i * sampleWidth) + '; y: ' + temperatureY + ' }', graphArea, "dynamicTemperature" + i))
            newPressureElements.push(Qt.createQmlObject('import QtQuick 2.0; PathCurve { x: ' + (i * sampleWidth) + '; y: ' + pressureY + ' }', graphArea, "dynamicPressure" + i))
        }
        temperaturePathWarm.pathElements = newPathElements
        temperaturePathCold.pathElements = newPathElements
        pressurePath.pathElements = newPressureElements
        repaintCanvas()
    }
    function processMeteogramData() {
        for (var i = 0; i <= temperatureYGridCount; i++) {
            verticalGridModel.append({ num: i })
        }

        dataArraySize = meteogramModel.count

        if (dataArraySize === 0) {
            dbgprint('model is empty -> clearing canvas and exiting')
            clearCanvas()
            return
        }

        var minValue = null
        var maxValue = null

        for (i = 0; i < dataArraySize; i++) {
            var obj = meteogramModel.get(i)
            var value = obj.temperature
            if (minValue === null) {
                minValue = value
                maxValue = value
                continue
            }
            if (value < minValue) {
                minValue = value
            }
            if (value > maxValue) {
                maxValue = value
            }
        }
        var mid = (maxValue - minValue) / 2 + minValue
        var halfSize = temperatureYGridCount / 2

        temperatureIncrementDegrees = Math.round(- (mid - halfSize))

    }
}
