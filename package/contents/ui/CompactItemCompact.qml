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

Item
{
    id: compactItemCompact

    anchors.fill: parent

    property int layoutType: main.layoutType

    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "") ? Kirigami.Theme.defaultFont : plasmoid.configuration.widgetFontName

    property string iconNameStr: main.iconNameStr.length > 0 ? main.iconNameStr : "\uf07b"
    property string temperatureStr: main.temperatureStr.length > 0 ? main.temperatureStr : "--"

    onWidgetFontSizeChanged: {
        compactWeatherIcon.font.pixelSize = widgetFontSize
        temperatureText.font.pixelSize = widgetFontSize
    }
    onWidgetFontNameChanged: {
        temperatureText.font.family = widgetFontName
    }

    function reLayout() {
        let iconScale = (main.inPanel) ? 0.9 : 0.75
        let temperatureScale = ((main.vertical && layoutType === 0)||(! main.vertical && layoutType === 1) || (main.onDesktop)) ? 0.5 : 0.8
        temperatureText.anchors.left = [compactItemCompact.left, compactItemCompact.left, undefined][layoutType]
        temperatureText.anchors.right = [undefined, compactItemCompact.right, compactItemCompact.right][layoutType]
        temperatureText.anchors.top = [compactItemCompact.top, compactItemCompact.top, undefined][layoutType]
        temperatureText.anchors.bottom = [compactItemCompact.bottom, undefined, compactItemCompact.bottom][layoutType]
        temperatureText.width = [parent.width * temperatureScale, parent.width, parent.width * 0.6][layoutType]
        temperatureText.height = [parent.height , parent.height * temperatureScale, parent.height  * 0.6][layoutType]
        temperatureText.horizontalAlignment = [Text.AlignRight, Text.AlignHCenter, Text.AlignHCenter][layoutType]
        temperatureText.verticalAlignment = [Text.AlignVCenter, Text.AlignVCenter, Text.AlignBottom][layoutType]
        temperatureText.fontSizeMode = (main.onDesktop) ? Text.FixedSize : Text.Fit

        compactWeatherIcon.anchors.left = [temperatureText.right, compactItemCompact.left, compactItemCompact.left][layoutType]
        compactWeatherIcon.anchors.right = [undefined, compactItemCompact.right, undefined][layoutType]
        compactWeatherIcon.anchors.top = [compactItemCompact.top, undefined, compactItemCompact.top][layoutType]
        compactWeatherIcon.anchors.bottom = [compactItemCompact.bottom , compactItemCompact.bottom, compactItemCompact.bottom][layoutType]
        compactWeatherIcon.width = [parent.width * temperatureScale, parent.width, parent.width * iconScale][layoutType]
        compactWeatherIcon.height = [parent.height, parent.height * temperatureScale, parent.height * iconScale][layoutType]
        compactWeatherIcon.horizontalAlignment = [Text.AlignLeft, Text.AlignHCenter, Text.AlignLeft][layoutType]
        compactWeatherIcon.verticalAlignment = [Text.AlignVCenter, Text.AlignVCenter, Text.AlignTop][layoutType]
        compactWeatherIcon.fontSizeMode = (main.onDesktop) ? Text.FixedSize : Text.Fit
    }


    Component.onCompleted: {
        if (main.inTray)
            layoutType = 2
            layoutTimer2.start()
    }

    onLayoutTypeChanged: {
        reLayout()
    }

    PlasmaComponents.Label {
        id: compactWeatherIcon
        // Rectangle {
        //     anchors.fill: parent
        //     opacity: 0.5
        //     color: "yellow"
        // }

        font.family: 'weathericons'
        font.pixelSize: widgetFontSize
        text: iconNameStr
        opacity: layoutType === 2 ? 0.8 : 1
        // font.pointSize: -1

    }

    PlasmaComponents.Label {
        id: temperatureText
        // Rectangle {
        //     anchors.fill: parent
        //     opacity: 0.5
        //     color: "blue"
        // }

        text: temperatureStr
        font.family: widgetFontName
        font.pixelSize: widgetFontSize
        // font.pointSize: -1
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
                    target: compactItemCompact
                    opacity: 0.5
                }
            }
        ]
    }
    Timer {
        id: layoutTimer2
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            reLayout()
        }
    }
}
