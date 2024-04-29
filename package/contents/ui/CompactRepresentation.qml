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


Loader {
    id: compactRepresentation

    anchors.fill: parent
    readonly property bool vertical: (Plasmoid.formFactor == PlasmaCore.Types.Vertical)

    property bool showLastReloadedTime: plasmoid.configuration.showLastReloadedTime

    property int layoutType: main.layoutType
    property int defaultWidgetSize: -1

    sourceComponent: !(layoutType === 2) ? compactItem : compactItemCompact

    Layout.fillWidth: compactRepresentation.vertical
    Layout.fillHeight: !compactRepresentation.vertical
    Layout.minimumWidth: item.Layout.minimumWidth
    Layout.minimumHeight: item.Layout.minimumHeight


    Component {
        id: compactItem
        CompactItem {
            vertical: compactRepresentation.vertical
        }
    }


    Component {
        id: compactItemCompact
        CompactItemCompact {
        }
    }

    PlasmaComponents.Label {
        id: lastReloadedNotifier
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: - defaultWidgetSize * 0.05
        verticalAlignment: Text.AlignBottom
        width: parent.width
        font.pixelSize: lastReloadedNotifier.height
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        color: Kirigami.Theme.highlightColor
        text: lastReloadedText
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        visible: false
        z: 1
    }


    PlasmaComponents.BusyIndicator {
        id: busyIndicator
        anchors.fill: parent
        visible: false
        running: false
        z: 1

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
                    //opacity: 0.5
                }
            }
        ]
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
            if (showLastReloadedTime)
            {
                lastReloadedNotifier.visible = !main.expanded
            }
        }

        onExited: {
            if (showLastReloadedTime)
            {
                lastReloadedNotifier.visible = false
            }
        }

        onClicked: (mouse)=> {
            if (mouse.button === Qt.MiddleButton) {
                loadingData.failedAttemptCount = 0
                main.loadDataFromInternet()
            } else {
                main.expanded = !main.expanded
                if (showLastReloadedTime)
                {
                    lastReloadedNotifier.visible = !main.expanded
                }
            }
        }

        PlasmaCore.ToolTipArea {
            id: toolTipArea
            anchors.fill: parent
            active: !main.expanded
            interactive: true
            mainText: main.currentPlace.alias
            subText:  main.toolTipSubText
            textFormat: Text.RichText
            icon: Qt.resolvedUrl('../images/weather-widget.svg')
        }
    }

    Component.onCompleted: {
        if ((defaultWidgetSize === -1) && (compactRepresentation.width > 0 ||  compactRepresentation.height)) {
            defaultWidgetSize = Math.min(compactRepresentation.width, compactRepresentation.height)
        }
    }
}
