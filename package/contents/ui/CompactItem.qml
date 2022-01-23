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
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils

Item {
    id: compactItem

    anchors.fill: parent

    property bool inTray
    property int layoutType: inTray ? 2 : main.layoutType

    property double parentWidth: parent.width
    property double parentHeight: parent.height

    property double partHeight: 0

    property double widgetWidth: 0
    property double widgetHeight: 0

    property int boxLeft: 0
    property int boxTop: 0
    property int boxWidth: 0
    property int boxHeight: 0

    onParentWidthChanged: {
        computeWidgetSize()
    }

    onParentHeightChanged: {
        computeWidgetSize()
    }

    onLayoutTypeChanged: {
        computeWidgetSize()
    }

    function computeWidgetSize() {
      widgetWidth = compactItem.width
      widgetHeight = compactItem.height

      if ((widgetWidth === 0) || (widgetHeight === 0))
        return

      switch (layoutType) {
        case 0:
          boxWidth = widgetHeight
          boxHeight = widgetHeight
          widgetWidth = widgetHeight * 2
          break
        case 1:
          boxWidth = widgetHeight
          boxHeight = widgetHeight / 2
          widgetWidth = widgetHeight
          break
        case 2:
          boxWidth = widgetHeight
          boxHeight = widgetHeight
          widgetWidth = widgetHeight
          break
      }
      compactRepresentation.Layout.preferredHeight = widgetHeight
      compactRepresentation.Layout.preferredWidth = widgetWidth
    }

    property double fontPixelSize: boxHeight * (layoutType === 2 ? 0.7 : 0.7)

    property string iconNameStr:    actualWeatherModel.count > 0 ? IconTools.getIconCode(actualWeatherModel.get(0).iconName, currentProvider.providerId, getPartOfDayIndex()) : '\uf07b'
    property string temperatureStr: actualWeatherModel.count > 0 ? UnitUtils.getTemperatureNumberExt(actualWeatherModel.get(0).temperature, temperatureType) : '--'
    Item {
        id: innerWindow
        anchors.fill: parent

        PlasmaComponents.Label {
            width: boxWidth
            height: boxHeight

            anchors.left: parent.left
            anchors.leftMargin: layoutType === 0 ? boxWidth : 0
            anchors.top: parent.top
            anchors.topMargin: layoutType === 1 ? boxHeight : 0

            horizontalAlignment: layoutType === 2 ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: layoutType === 2 ? Text.Fit : Text.FixedSize

            font.family: 'weathericons'
            text: iconNameStr

            opacity: layoutType === 2 ? 0.8 : 1

            font.pixelSize: fontPixelSize
            font.pointSize: -1
        }
        PlasmaComponents.Label {
            id: temperatureText

            width: boxWidth
            height: boxHeight

              anchors.left: parent.left
              anchors.leftMargin: 0
              anchors.top: parent.top
              anchors.topMargin: 0

            horizontalAlignment: layoutType === 1 ? Text.AlignHCenter : Text.AlignRight
            verticalAlignment: layoutType === 2 ? Text.AlignBottom : Text.AlignVCenter

            text: temperatureStr
            font.pixelSize: fontPixelSize * (layoutType === 2 ? 0.5 : (temperatureType !== UnitUtils.TemperatureType.CELSIUS ? 6/7 : 1))
            font.pointSize: -1
        }
        DropShadow {
            anchors.fill: temperatureText
            radius: 3
            samples: 16
            spread: 0.9
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
}
