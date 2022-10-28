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
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils

Item {
    id: compactItem

    anchors.fill: parent

    property bool inTray
    property int layoutType: inTray ? 2 : main.layoutType
    property string widgetFontName: main.widgetFontName
    property string widgetFontSize: main.widgetFontSize

    property double parentWidth: parent.width
    property double parentHeight: parent.height


    property double partWidth: 0
    property double partHeight: 0

    property double widgetWidth: 0
    property double widgetHeight: 0

    onParentWidthChanged: {
        dbgprint("onParentWidthChanged")
        computeWidgetSize()
    }

    onParentHeightChanged: {
        dbgprint("onParentHeightChanged")
        computeWidgetSize()
    }

    onLayoutTypeChanged: {
        computeWidgetSize()
    }

    function computeWidgetSize() {
        if ((parentWidth > 0) && (parentHeight > 0)) {
            setDebugFlag(false)
            dbgprint("Widget ParentSize = " + parent.width + "x" + parent.height)
            if (layoutType === 0) {
                partWidth = vertical ? parentWidth / 2 : parentHeight
                partHeight = parentHeight
                widgetWidth = partWidth * 2
                widgetHeight = partHeight
            } else if (layoutType === 1) {
                partWidth = vertical ? parentWidth / 2 : parentWidth / 2
                partHeight = vertical ? parentWidth  : parentHeight / 2
                widgetWidth = partWidth
                widgetHeight = partHeight * 2
            } else if (layoutType === 2) {
                partWidth = vertical ? parentWidth : parentHeight
                partHeight = partWidth
                widgetWidth = partWidth
                widgetHeight = partHeight
            }
            dbgprint("Individual WidgetSize  = " + partWidth + "x" + partHeight)
            dbgprint("Combined WidgetSize = " + widgetWidth + "x" + widgetHeight)
            compactRepresentation.Layout.preferredHeight = widgetHeight
            compactRepresentation.Layout.preferredWidth = widgetWidth
            compactRepresentation.Layout.maximumWidth - widgetWidth
            setDebugFlag(false)
        }
    }



    property double fontPixelSize: partHeight * (layoutType === 2 ? 0.7 : 0.7)

    property string iconNameStr:    actualWeatherModel.count > 0 ? IconTools.getIconCode(actualWeatherModel.get(0).iconName, currentProvider.providerId, getPartOfDayIndex()) : ''
    property string temperatureStr: actualWeatherModel.count > 0 ? UnitUtils.getTemperatureNumberExt(actualWeatherModel.get(0).temperature, temperatureType) : ''

    PlasmaComponents.Label {

        anchors.left: parent.left
        anchors.leftMargin: layoutType === 0 ? partWidth : 0
        anchors.top: parent.top
        anchors.topMargin: layoutType === 1 ? partHeight : 0

        width: partWidth
        height: partHeight

        horizontalAlignment: layoutType === 2 ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: ((layoutType === 2) || (layoutType===0 && main.vertical)) ? Text.Fit : Text.FixedSize

        font.family: 'weathericons'
        text: iconNameStr

        opacity: layoutType === 2 ? 0.8 : 1

        font.pixelSize: fontPixelSize
        font.pointSize: -1
    }

    PlasmaComponents.Label {
        id: temperatureText

        anchors.left: parent.left
        anchors.leftMargin: layoutType === 2 ? partWidth * 0.25 : 0
        anchors.top: parent.top
        anchors.topMargin: 0
        width: layoutType === 2 ? partWidth * 0.75 : partWidth
        height: partHeight

        horizontalAlignment: layoutType === 1 ? Text.AlignHCenter : Text.AlignRight
        verticalAlignment: layoutType === 2 ? Text.AlignBottom : Text.AlignVCenter

        text: temperatureStr

        font.family: plasmoid.configuration.widgetFontName === "" ? (theme.defaultFont) : plasmoid.configuration.widgetFontName
        font.pixelSize: layoutType === 2 ? widgetFontSize * 0.7 : widgetFontSize
        font.pointSize: -1
        fontSizeMode: ((! vertical) && (layoutType === 1)) ? Text.VerticalFit : Text.HorizontalFit
    }

    DropShadow {
        anchors.fill: temperatureText
        radius: 3
        samples: 16
        spread: 0.8
        fast: true
        color: theme.backgroundColor
        source: temperatureText
        visible: layoutType === 2
    }

    PlasmaComponents.BusyIndicator {
        id: busyIndicator
        anchors.fill: parent
        visible: false
        running: false
    }

    states: [
        State {
            name: 'loading'
            when: loadingData

            PropertyChanges {
                target: busyIndicator
                visible: true
                running: true
            }

            PropertyChanges {
                target: compactItem
                opacity: 0.5
            }
        }
    ]
}
