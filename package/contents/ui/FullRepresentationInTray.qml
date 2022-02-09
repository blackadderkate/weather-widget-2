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
import org.kde.plasma.plasmoid 2.0
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: fullRepresentation

    width: parent.width

    property double defaultFontPixelSize: theme.defaultFont.pixelSize
    property double footerHeight: defaultFontPixelSize * 3.5

    property int nextDaysSpacing: 5 * units.devicePixelRatio
    property int nextDayHeight: defaultFontPixelSize * 4.9
    property int headingHeight: defaultFontPixelSize * 3
    property int nextDayItemSpacing: defaultFontPixelSize * 0.7

    property double headingTopMargin: defaultFontPixelSize

    property color lineColor: theme.textColor

    PlasmaComponents.Label {
        id: currentLocationText

        anchors.left: parent.left
        anchors.top: parent.top

        text: main.placeAlias
    }

    PlasmaComponents.Label {
        id: nextLocationText

        anchors.right: parent.right
        anchors.top: parent.top
        visible: !onlyOnePlace

        text: i18n("Next Location")
        color: theme.textColor
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: nextLocationText

        hoverEnabled: true

        onClicked: {
            dbgprint('clicked next location')
            main.setNextPlace()
        }

        onEntered: {
            nextLocationText.font.underline = true
        }

        onExited: {
            nextLocationText.font.underline = false
        }
    }




    /*
     *
     * NEXT DAYS
     *
     */
    ScrollView {
        id: nextDays

        anchors.top: parent.top
        anchors.topMargin: headingHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerHeight

        width: parent.width

        ListView {
            id: nextDaysView

            anchors.fill: parent
            width: parent.width
            height: parent.height

            model: nextDaysModel
            orientation: Qt.Vertical
            spacing: nextDayItemSpacing
            interactive: false

            delegate: Item {

                width: nextDaysView.width
                height: nextDayHeight

                property string svgLineName: 'horizontal-line'

                PlasmaCore.SvgItem {
                    id: dayTitleLine
                    width: parent.width
                    height: lineSvg.elementSize(svgLineName).height
                    elementId: svgLineName
                    svg: PlasmaCore.Svg {
                        id: lineSvg
                        imagePath: 'widgets/line'
                    }
                }

                PlasmaComponents.Label {
                    id: dayTitleText

                    anchors.top: dayTitleLine.bottom
                    anchors.topMargin: units.smallSpacing * 0.5
                    verticalAlignment: Text.AlignTop

                    text: dayTitle
                }



                /*
                *
                * four item data
                *
                */
                property double periodMargin: defaultFontPixelSize * 1.5
                property double periodItemWidth: (width - periodMargin * 4) / 4
                property double periodItemHeight: nextDayHeight - headingTopMargin
                property double periodFontSize: periodItemHeight * 0.45

                Item {

                    anchors.top: parent.top
                    anchors.topMargin: headingTopMargin

                    height: periodItemHeight

                    NextDayPeriodItem {
                        id: period1
                        width: periodItemWidth
                        height: parent.height
                        temperature: temperature0
                        iconName: iconName0
                        hidden: hidden0
                        past: isPast0
                        partOfDay: 1
                        pixelFontSize: periodFontSize
                    }

                    NextDayPeriodItem {
                        id: period2
                        width: periodItemWidth
                        height: parent.height
                        temperature: temperature1
                        iconName: iconName1
                        hidden: hidden1
                        past: isPast1
                        partOfDay: 0
                        pixelFontSize: periodFontSize

                        anchors.left: period1.right
                        anchors.leftMargin: periodMargin
                    }

                    NextDayPeriodItem {
                        id: period3
                        width: periodItemWidth
                        height: parent.height
                        temperature: temperature2
                        iconName: iconName2
                        hidden: hidden2
                        past: isPast2
                        partOfDay: 0
                        pixelFontSize: periodFontSize

                        anchors.left: period2.right
                        anchors.leftMargin: periodMargin
                    }

                    NextDayPeriodItem {
                        id: period4
                        width: periodItemWidth
                        height: parent.height
                        temperature: temperature3
                        iconName: iconName3
                        hidden: hidden3
                        past: isPast3
                        partOfDay: 1
                        pixelFontSize: periodFontSize

                        anchors.left: period3.right
                        anchors.leftMargin: periodMargin
                    }
                }

            }
        }
    }




    /*
     *
     * FOOTER
     *
     */
    MouseArea {
        id: reloadMouseArea

        anchors.top: nextDays.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.topMargin: units.smallSpacing

        width: lastReloadedTextComponent.contentWidth
        height: lastReloadedTextComponent.contentHeight

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        PlasmaComponents.Label {
            id: lastReloadedTextComponent
            anchors.fill: parent

            verticalAlignment: Text.AlignTop

            text: lastReloadedText
        }

        PlasmaComponents.Label {
            id: reloadTextComponent
            anchors.fill: parent

            verticalAlignment: Text.AlignTop

            text: '\u21bb '+ i18n("Reload")
            visible: false
        }

        onEntered: {
            lastReloadedTextComponent.visible = false
            reloadTextComponent.visible = true
        }

        onExited: {
            lastReloadedTextComponent.visible = true
            reloadTextComponent.visible = false
        }

        onClicked: {
            main.reloadData()
        }
    }


    PlasmaComponents.Label {
        id: creditText

        anchors.top: nextDays.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: reloadMouseArea.right
        anchors.topMargin: units.smallSpacing
        anchors.leftMargin: units.largeSpacing

        text: creditLabel
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: creditText

        hoverEnabled: true

        onClicked: {
            dbgprint('opening: ', creditLink)
            Qt.openUrlExternally(creditLink)
        }

        onEntered: {
            creditText.font.underline = true
        }

        onExited: {
            creditText.font.underline = false
        }
    }

}
