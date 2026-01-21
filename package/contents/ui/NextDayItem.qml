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
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Shapes 1.6
import org.kde.plasma.components 3.0 as PlasmaComponents
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {

    property int itemRowSpacing: 5
    property double periodFontSize: Kirigami.Theme.defaultFont.pixelSize
    property double periodHeight: (height - periodFontSize - itemRowSpacing * 4) / 4
    property color lineColor: Kirigami.Theme.textColor

    PlasmaComponents.Label {
        id: dayTitleText
        text: dayTitle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: periodFontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
        fontSizeMode: Text.Fit
    }

    Item {
        id: dayTitleLine
        width: parent.width
        height: 1
        anchors.top: parent.top
        anchors.topMargin: periodFontSize * 0.8

        LinearGradient {
            anchors.fill: parent
            start: Qt.point(0, 0)
            end: Qt.point(parent.width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0) }
                GradientStop { position: 0.1; color: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 1) }
                GradientStop { position: 1.0; color: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0) }
            }
        }
    }




/*
 *
 * four item data
 *
*/
    GridLayout {
        anchors.fill: parent
        anchors.topMargin: periodFontSize

        columns: 1
        rowSpacing: 5

        height: parent.height - anchors.topMargin
        width: parent.width

        NextDayPeriodItem {
            width: parent.width
            height: periodHeight
            temperature: temperature0
            iconName: (iconName0 != undefined) ? iconName0 : ""
            hidden: hidden0
            partOfDay: partOfDay0
            pixelFontSize: periodFontSize
        }

        NextDayPeriodItem {
            width: parent.width
            height: periodHeight
            temperature: temperature1
            iconName: (iconName1 != undefined) ? iconName1 : ""
            hidden: hidden1
            partOfDay: partOfDay1
            pixelFontSize: periodFontSize
        }

        NextDayPeriodItem {
            width: parent.width
            height: periodHeight
            temperature: temperature2
            iconName: (iconName2 != undefined) ? iconName2 : ""
            hidden: hidden2
            partOfDay: partOfDay2
            pixelFontSize: periodFontSize
        }

        NextDayPeriodItem {
            width: parent.width
            height: periodHeight
            temperature: temperature3
            iconName: (iconName3 != undefined) ? iconName3 : ""
            hidden: hidden3
            partOfDay: partOfDay3
            pixelFontSize: periodFontSize
        }
    }
}
