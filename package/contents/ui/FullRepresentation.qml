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
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: fullRepresentation

    property int imageWidth: 800 * Screen.devicePixelRatio  // Makes yr.no images grainy,
    property int imageHeight: 320 * Screen.devicePixelRatio + defaultFontPixelSize// prefer rendering meteograms

    property double defaultFontPixelSize: theme.defaultFont.pixelSize
    property double footerHeight: defaultFontPixelSize

    property int nextDayItemSpacing: defaultFontPixelSize * 0.5
    property int nextDaysHeight: defaultFontPixelSize * 9
    property int nextDaysVerticalMargin: defaultFontPixelSize
    property int hourLegendMargin: defaultFontPixelSize * 2
    property double nextDayItemWidth: (imageWidth / nextDaysCount) - nextDayItemSpacing - hourLegendMargin / nextDaysCount
    property int headingHeight: defaultFontPixelSize * 2
    property double hourLegendBottomMargin: defaultFontPixelSize * 0.2

    implicitWidth: imageWidth
    implicitHeight: headingHeight + imageHeight + footerHeight + nextDaysHeight + 14



    PlasmaComponents.Label {
        id: currentLocationText

        anchors.left: parent.left
        anchors.top: parent.top
        verticalAlignment: Text.AlignTop

        text: {
            var t = main.placeAlias
            switch (timezoneType) {
                case 0:
                    t += " (" + getLocalTimeZone()+ ")"
                    break
                case 1:
                    t += " (" + i18n("UTC") + ")"
                    break
                case 2:
                    if (main.timezoneShortName === "") {
                        main.timezoneShortName = "unknown"
                    }
                    t += " (" +  main.timezoneShortName + ")"
                    break
                default:
                    t += " (" + "TBA" + ")"
                    break
                }
            return t
        }
    }

    PlasmaComponents.Label {
        id: nextLocationText

        anchors.right: parent.right
        anchors.top: parent.top
        verticalAlignment: Text.AlignTop
        visible: !onlyOnePlace
        color: theme.textColor
        text: i18n("Next Location") + " >>"
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: nextLocationText

        hoverEnabled: true

        onClicked: {
            dbgprint('clicked next location')
            main.setNextPlace(false,"+")
        }

        onEntered: {
            nextLocationText.font.underline = true
        }

        onExited: {
            nextLocationText.font.underline = false
        }
    }

    PlasmaComponents.Label {
        id: prevLocationText

        anchors.right: nextLocationText.left
        anchors.top: nextLocationText.top
        anchors.rightMargin: 15
        verticalAlignment: Text.AlignTop
        visible: !onlyOnePlace
        color: theme.textColor
        text: "<< " + i18n("Previous Location")
    }

    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: prevLocationText

        hoverEnabled: true

        onClicked: {
            dbgprint('clicked previous location')
            main.setNextPlace(false,"-")
        }

        onEntered: {
            prevLocationText.font.underline = true
        }

        onExited: {
            prevLocationText.font.underline = false
        }
    }

    Meteogram {
        id: meteogram2
        anchors.top: parent.top
        anchors.topMargin: headingHeight
        width: imageWidth
        height: imageHeight
     }
  /*
     *
     * NEXT DAYS
     *
     */
    ListView {
        id: nextDaysView
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerHeight + nextDaysVerticalMargin
        anchors.left: parent.left
        anchors.leftMargin: hourLegendMargin
        anchors.right: parent.right
        height: nextDaysHeight

        model: nextDaysModel
        orientation: Qt.Horizontal
        spacing: nextDayItemSpacing
        interactive: false

        delegate: NextDayItem {
            width: nextDayItemWidth
            height: nextDaysHeight
        }
    }

    Column {
        id: hourLegend
        anchors.bottom: parent.bottom
        anchors.bottomMargin: footerHeight + nextDaysVerticalMargin
        spacing: 1 * Screen.devicePixelRatio

        width: hourLegendMargin
        height: nextDaysHeight - defaultFontPixelSize

        PlasmaComponents.Label {
            text: twelveHourClockEnabled ? '3AM' : '3:00'
            width: parent.width
            height: parent.height / 4
            font.pixelSize: defaultFontPixelSize * 0.8
            font.pointSize: -1
            horizontalAlignment: Text.AlignRight
            opacity: 0.6
        }
        PlasmaComponents.Label {
            text: twelveHourClockEnabled ? '9AM' : '9:00'
            width: parent.width
            height: parent.height / 4
            font.pixelSize: defaultFontPixelSize * 0.8
            font.pointSize: -1
            horizontalAlignment: Text.AlignRight
            opacity: 0.6
        }
        PlasmaComponents.Label {
            text: twelveHourClockEnabled ? '3PM' : '15:00'
            width: parent.width
            height: parent.height / 4
            font.pixelSize: defaultFontPixelSize * 0.8
            font.pointSize: -1
            horizontalAlignment: Text.AlignRight
            opacity: 0.6
        }
        PlasmaComponents.Label {
            text: twelveHourClockEnabled ? '9PM' : '21:00'
            width: parent.width
            height: parent.height / 4
            font.pixelSize: defaultFontPixelSize * 0.8
            font.pointSize: -1
            horizontalAlignment: Text.AlignRight
            opacity: 0.6
        }
    }


    /*
     *
     * FOOTER
     *
     */
    MouseArea {
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        width: lastReloadedTextComponent.contentWidth
        height: lastReloadedTextComponent.contentHeight

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        PlasmaComponents.Label {
            id: lastReloadedTextComponent
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignBottom

            text: lastReloadedText
        }

        PlasmaComponents.Label {
            id: reloadTextComponent
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignBottom

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

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        verticalAlignment: Text.AlignBottom

        text: creditLabel
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
