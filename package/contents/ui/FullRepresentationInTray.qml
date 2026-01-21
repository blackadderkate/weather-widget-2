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
import QtQuick.Controls
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Item {
    id: fullRepresentation

    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize

    Layout.minimumWidth: main.switchWidth
    Layout.minimumHeight: headingHeight + (nextDayHeight * 5) + footerHeight

    Layout.preferredWidth: defaultFontPixelSize * 30
    Layout.preferredHeight: headingHeight + (nextDayHeight * 5) + footerHeight

    property int headingHeight: defaultFontPixelSize * 2
    property double footerHeight: defaultFontPixelSize * 3

    property int nextDaysSpacing: defaultFontPixelSize
    property int nextDayHeight: defaultFontPixelSize * 4
    property int nextDayItemSpacing: defaultFontPixelSize

    property double headingTopMargin: defaultFontPixelSize

    property color lineColor: Kirigami.Theme.textColor


    PlasmaComponents.Label {
        id: currentLocationText
        text: main.currentPlace.alias

        anchors.top: parent.top
        anchors.left: parent.left

        height: headingHeight
        width: parent.width / 2

        color: Kirigami.Theme.textColor

        verticalAlignment: Text.AlignTop
    }

    PlasmaComponents.Label {
        id: nextLocationText
        text: i18n("Next Location")

        anchors.top: parent.top
        anchors.right: parent.right

        height: headingHeight
        width: parent.width / 2

        visible: (placesCount > 1)

        color: Kirigami.Theme.textColor

        horizontalAlignment:Text.AlignRight
        verticalAlignment: Text.AlignTop

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            hoverEnabled: true

            onClicked: {
                main.setNextPlace()
            }
            onEntered: {
                nextLocationText.font.underline = true
            }
            onExited: {
                nextLocationText.font.underline = false
            }
        }
    }


    ScrollView {
        id: nextDays

        anchors.top: currentLocationText.bottom
        anchors.bottom: frFooter.top
        anchors.bottomMargin:  defaultFontPixelSize / 2

        width: parent.width

        ListView {
            id: nextDaysView

            anchors.fill: parent
            model: nextDaysModel

            orientation: Qt.Vertical
            spacing: nextDayItemSpacing
            interactive: false

            delegate: Item {

                width: nextDaysView.width - 50
                height: (defaultFontPixelSize * 3.6)

                property string svgLineName: 'horizontal-line'

                KSvg.SvgItem {
                    anchors.top: dayTitleText.top
                    width: parent.width
                    height: lineSvg.elementSize(svgLineName).height
                    elementId: svgLineName
                    svg: KSvg.Svg {
                        id: lineSvg
                        imagePath: 'widgets/line'
                    }
                }

                PlasmaComponents.Label {
                    id: dayTitleText
                    anchors.topMargin: Kirigami.Units.smallSpacing * 0.5
                    verticalAlignment: Text.AlignTop
                    text: dayTitle
                    font.pixelSize: defaultFontPixelSize * 1.5
                    font.bold: true
                }

                property double periodMargin: defaultFontPixelSize * 0.5
                property double periodItemWidth: (nextDaysView.width - 10 - (periodMargin * 4)) / 4
                property double periodItemHeight: defaultFontPixelSize * 2

                Item {

                    anchors.top: dayTitleText.bottom
                    height: periodItemHeight

                    NextDayPeriodItem {
                        id: period1

                        width: periodItemWidth
                        height: parent.height

                        temperature: temperature0
                        iconName: iconName0
                        hidden: hidden0
                        partOfDay: partOfDay0
                        pixelFontSize: defaultFontPixelSize * 1.5
                    }

                    NextDayPeriodItem {
                        id: period2

                        anchors.left: period1.right
                        anchors.leftMargin: periodMargin

                        width: periodItemWidth
                        height: parent.height

                        temperature: temperature1
                        iconName: iconName1
                        hidden: hidden1
                        partOfDay: partOfDay1
                        pixelFontSize: defaultFontPixelSize * 1.5
                    }

                    NextDayPeriodItem {
                        id: period3

                        anchors.left: period2.right
                        anchors.leftMargin: periodMargin

                        width: periodItemWidth
                        height: parent.height

                        temperature: temperature2
                        iconName: iconName2
                        hidden: hidden2
                        partOfDay: partOfDay3
                        pixelFontSize: defaultFontPixelSize * 1.5
                    }

                    NextDayPeriodItem {
                        id: period4

                        anchors.left: period3.right
                        anchors.leftMargin: periodMargin

                        width: periodItemWidth
                        height: parent.height

                        temperature: temperature3
                        iconName: iconName3
                        hidden: hidden3
                        partOfDay: partOfDay3
                        pixelFontSize: defaultFontPixelSize * 1.5
                    }
                }
            }
        }
    }

    Rectangle {
        id: frFooter

        anchors.bottom: fullRepresentation.bottom
        anchors.left: fullRepresentation.left
        anchors.right: fullRepresentation.right
        height: footerHeight

        color: Kirigami.Theme.backgroundColor

        MouseArea {
            id: lastReloadArea
            cursorShape: Qt.PointingHandCursor

            anchors.bottom: parent.bottom
            anchors.left: parent.left

            height: footerHeight
            width: parent.width * 0.25

            hoverEnabled: true

            PlasmaComponents.Label {
                id: lastReloadedTextComponent

                anchors.fill: parent

                text: main.lastReloadedText

                color: Kirigami.Theme.textColor
                elide: Text.ElideRight
                maximumLineCount: 3
                verticalAlignment: Text.AlignBottom
                wrapMode: Text.WordWrap
            }

            PlasmaComponents.Label {
                id: reloadTextComponent

                anchors.fill: parent

                text: '\u21bb '+ i18n("Reload")

                verticalAlignment: Text.AlignBottom
                visible: false
            }

            onClicked: {
                main.loadDataFromInternet()
            }
            onEntered: {
                lastReloadedTextComponent.visible = false
                reloadTextComponent.visible = true
            }
            onExited: {
                lastReloadedTextComponent.visible = true
                reloadTextComponent.visible = false
            }
        }

        MouseArea {
            // id: frFooter

            cursorShape: Qt.PointingHandCursor
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.left: lastReloadArea.right

            hoverEnabled: true

            PlasmaComponents.Label {
                id: creditText
                anchors.fill: parent

                text: main.currentPlace.creditLabel

                color: Kirigami.Theme.textColor
                font: Kirigami.Theme.smallFont

                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignBottom
                maximumLineCount: 3
                wrapMode: Text.WordWrap

            }

            onClicked: {
                Qt.openUrlExternally(main.currentPlace.creditLink)
            }
            onEntered: {
                creditText.font.underline = true
            }
            onExited: {
                creditText.font.underline = false
            }
        }

    }
}
