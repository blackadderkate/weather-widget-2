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
 * MERCHANTABILITY or FITNESS FOR A PARTIAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami


Item {
    id: compactRepresentation

    anchors.fill: parent

    readonly property int widgetWidth: compactRepresentation.width
    readonly property int widgetHeight: compactRepresentation.height

    readonly property int minWidgetSize: Math.min(widgetWidth,widgetHeight)
    readonly property int maxWidgetSize: Math.max(widgetWidth,widgetHeight)

    CompactItem {
        id: compactItem
    }

    Layout.preferredWidth: ((layoutType === 0)) ? maxWidgetSize : minWidgetSize

    PlasmaComponents.Label {
        id: lastReloadedNotifier

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: - widgetHeight * 0.05
        verticalAlignment: Text.AlignBottom
        width: widgetWidth
        height: widgetHeight * 0.2
        elide: Text.ElideRight
        fontSizeMode: Text.Fit
        font.pointSize: -1
        color: Kirigami.Theme.highlightColor
        text: lastReloadedText
        wrapMode: Text.WordWrap
        visible: false
    }

    DropShadow {
        anchors.fill: lastReloadedNotifier
        radius: 3
        samples: 16
        spread: 0.8
        fast: true
        color: Kirigami.Theme.backgroundColor
        source: lastReloadedNotifier
        visible: (lastReloadedText.visible === true)
    }

    MouseArea {
        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        hoverEnabled: true

        onEntered: {
            lastReloadedNotifier.visible = !plasmoid.expanded
        }

        onExited: {
            lastReloadedNotifier.visible = false
        }

        onClicked: (mouse)=> {
            if (mouse.button === Qt.MiddleButton) {
                loadingData.failedAttemptCount = 0
                main.loadDataFromInternet()
            } else {
                debugLogging = 0
                dbgprint("CompactRepresentation")
                let t = main.expanded
                if (t) {
                    dbgprint("Closing FullRepresentation")
                } else {
                    dbgprint("Opening FullRepresentation")
                }
                main.expanded = ! main.expanded
                debugLogging = 0
            }
        }
    }
}
