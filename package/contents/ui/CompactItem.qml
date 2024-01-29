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
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils

Item {
    id: compactItem

    anchors.fill: parent

    property int layoutType: main.layoutType

    property double parentWidth: parent.width
    property double parentHeight: parent.height

    property double widgetWidth: 0
    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property string widgetFontName: plasmoid.configuration.widgetFontName

// property double fontPixelSize: defaultWidgetSize * (layoutType === 2 ? 0.95 : 0.8)

    property string iconNameStr: main.iconNameStr.length > 0 ? main.iconNameStr : "\uf07b"
    property string temperatureStr: main.temperatureStr.length > 0 ? main.temperatureStr : "--"

    onWidgetFontSizeChanged: {
        compactWeatherIcon.font.pixelSize = widgetFontSize
        temperatureText.font.pixelSize = widgetFontSize
    }
    onWidgetFontNameChanged: {
        temperatureText.font.family = widgetFontName

    }


    PlasmaComponents.Label {
        id: compactWeatherIcon

        width: {
            switch (layoutType) {
            case 0:
                return widgetSize / 2
                break
            case 1:
                return widgetSize
                break
            case 2:
                return widgetSize * 0.8
                break

            }
        }

        height: {
            switch (layoutType) {
            case 0:
                return defaultWidgetSize
                break
            case 1:
                return defaultWidgetSize / 2
                break
            case 2:
                return defaultWidgetSize * 0.8
                break

            }
        }

        anchors.left: parent.left
        anchors.leftMargin: layoutType === 2 ? widgetSize * .1 : layoutType === 1 ? 0 : widgetSize / 2
        anchors.top: parent.top
        anchors.topMargin: layoutType === 1 ? defaultWidgetSize / 2 : layoutType === 2 ? widgetSize * .2 : 0
        anchors.fill: parent
        horizontalAlignment: layoutType === 2 ? Text.AlignRight : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.FixedSize
        font.family: 'weathericons'
        text: iconNameStr
        opacity: layoutType === 2 ? 0.8 : 1
        font.pixelSize: fontPixelSize
        font.pointSize: -1

    }

    PlasmaComponents.Label {
        id: temperatureText

        width: {
            switch (layoutType) {
            case 0:
                return widgetSize / 2
                break
            case 1:
                return widgetSize
                break
            case 2:
                return widgetSize
                break

            }
        }

        height: {
            switch (layoutType) {
            case 0:
                return defaultWidgetSize
                break
            case 1:
                return defaultWidgetSize / 2
                break
            case 2:
                return defaultWidgetSize
                break

            }
        }

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: layoutType === 1 ? Text.HorizontalFit : Text.VerticalFit

        text: temperatureStr
        font.pixelSize: fontPixelSize
        font.pointSize: -1
    }

    DropShadow {
        anchors.fill: temperatureText
        radius: 3
        samples: 16
        spread: 0.8
        fast: true
        color: Kirigami.Theme.backgroundColor
        source: temperatureText
        visible: layoutType === 2
    }

    PlasmaComponents.BusyIndicator {
        id: busyIndicator
        anchors.fill: parent
        visible: false
        running: false

        states: [
            State {
                name: 'loading'
                when: !loadingDataComplete

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


