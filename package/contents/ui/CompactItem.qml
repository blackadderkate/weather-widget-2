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


GridLayout {
    id: iconAndText

    anchors.fill: parent

    property bool vertical: main.vertical

    property int layoutType: main.layoutType

    property int widgetFontSize: plasmoid.configuration.widgetFontSize
    property string widgetFontName: (plasmoid.configuration.widgetFontName === "") ? Kirigami.Theme.defaultFont : plasmoid.configuration.widgetFontName

    property string iconNameStr: main.iconNameStr.length > 0 ? main.iconNameStr : "\uf07b"
    property string temperatureStr: main.temperatureStr.length > 0 ? main.temperatureStr : "--"

    columnSpacing: 0
    rowSpacing: 0

    rows: (layoutType === 0) ? 1 : 2
    columns: (layoutType === 0) ? 2 : 1

    Item {
        // Otherwise it takes up too much space while loading
        visible: temperatureText.text.length > 0

        Layout.alignment: Qt.AlignCenter

        Layout.fillWidth: iconAndText.vertical
        Layout.fillHeight: !iconAndText.vertical
        Layout.minimumWidth: iconAndText.vertical ? 0 : sizehelperText.paintedWidth
        Layout.maximumWidth: iconAndText.vertical ? Infinity : Layout.minimumWidth

        Layout.minimumHeight: iconAndText.vertical ? sizehelperText.paintedHeight : (main.onDesktop ? sizehelperText.paintedHeight : 0)
        Layout.maximumHeight: iconAndText.vertical ? Layout.minimumHeight : Infinity

        Text {
            id: sizehelperText

            font {
                family: temperatureText.font.family
                weight: temperatureText.font.weight
                italic: temperatureText.font.italic
                pixelSize: (main.onDesktop) ? Math.max(Kirigami.Units.gridUnit, widgetFontSize) : Math.min(Kirigami.Units.gridUnit, widgetFontSize) // random "big enough" size - this is used as a max pixelSize by the fontSizeMode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: main.onDesktop ? Text.Text.FixedSize : iconAndText.vertical ? Text.HorizontalFit : Text.VerticalFit
            wrapMode: Text.NoWrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors {
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }
            // These magic values are taken from the digital clock, so that the
            // text sizes here are identical with various clock text sizes
            height: {
                const textHeightScaleFactor = (parent.height > 26) ? 0.7 : 0.9;
                return Math.min (parent.height * textHeightScaleFactor, 3 * Kirigami.Theme.defaultFont.pixelSize);
            }
            visible: false

            // pattern to reserve some constant space TODO: improve and take formatting/i18n into account
            text: "888°"
        }

        PlasmaComponents.Label {
            id: temperatureText

            font {
                weight: Font.Normal
                family: widgetFontName
                pixelSize: widgetFontSize
                pointSize: 0 // we need to unset pointSize otherwise it breaks the Text.Fit size mode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: Text.Fit
            wrapMode: Text.NoWrap

            height: 0
            width: 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: temperatureStr
            anchors {
                fill: parent
                //leftMargin: Kirigami.Units.smallSpacing
                //rightMargin: Kirigami.Units.smallSpacing
            }
        }
    }


    Item {
        // Otherwise it takes up too much space while loading
        visible: compactWeatherIcon.text.length > 0

        Layout.alignment: Qt.AlignCenter

        Layout.fillWidth: iconAndText.vertical
        Layout.fillHeight: !iconAndText.vertical
        Layout.minimumWidth: iconAndText.vertical ? 0 : sizehelperIcon.paintedWidth
        Layout.maximumWidth: iconAndText.vertical ? Infinity : Layout.minimumWidth

        Layout.minimumHeight: iconAndText.vertical ? sizehelperIcon.paintedHeight : 0
        Layout.maximumHeight: iconAndText.vertical ? Layout.minimumHeight : Infinity

        Text {
            id: sizehelperIcon

            font {
                family: compactWeatherIcon.font.family
                weight: compactWeatherIcon.font.weight
                italic: compactWeatherIcon.font.italic
                pixelSize: (main.onDesktop) ? Math.max(Kirigami.Units.gridUnit, widgetFontSize) : Math.min(Kirigami.Units.gridUnit, widgetFontSize) // random "big enough" size - this is used as a max pixelSize by the fontSizeMode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: main.onDesktop ? Text.Text.FixedSize : iconAndText.vertical ? Text.HorizontalFit : Text.VerticalFit
            wrapMode: Text.NoWrap

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors {
                leftMargin: Kirigami.Units.smallSpacing
                rightMargin: Kirigami.Units.smallSpacing
            }
            // These magic values are taken from the digital clock, so that the
            // text sizes here are identical with various clock text sizes
            height: {
                const textHeightScaleFactor = (parent.height > 26) ? 0.7 : 0.9;
                return Math.min (parent.height * textHeightScaleFactor, 3 * Kirigami.Theme.defaultFont.pixelSize);
            }
            visible: false

            // pattern to reserve some constant space TODO: improve and take formatting/i18n into account
            text: "XXX"
        }

        PlasmaComponents.Label {
            id: compactWeatherIcon

            font {
                weight: Font.Normal
                family: 'weathericons'
                pixelSize: widgetFontSize
                pointSize: 0 // we need to unset pointSize otherwise it breaks the Text.Fit size mode
            }
            minimumPixelSize: Math.round(Kirigami.Units.gridUnit / 2)
            fontSizeMode: Text.Fit
            wrapMode: Text.NoWrap

            height: 0
            width: 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: iconNameStr
            anchors {
                fill: parent
                //leftMargin: Kirigami.Units.smallSpacing
                //rightMargin: Kirigami.Units.smallSpacing
            }
        }
    }
}

