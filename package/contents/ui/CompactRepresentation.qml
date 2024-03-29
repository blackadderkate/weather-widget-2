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
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

Item {
    id: compactRepresentation

    anchors.fill: parent

    CompactItem {
        id: compactItem
        inTray: false
    }

    property bool isCompactLayout: main.layoutType === 2 ? true : false
    // Layout.preferredWidth: ((! isCompactLayout ) && (plasmoid.formFactor === PlasmaCore.Types.Horizontal)) ? compactItem.height * 2 : compactItem.height
    // Layout.preferredHeight: ((! isCompactLayout ) && (plasmoid.formFactor === PlasmaCore.Types.Vertical)) ? parent.width * 2 : parent.width

    property double partHeight: compactItem.widgetHeight

    PlasmaComponents.Label {
        id: lastReloadedNotifier

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: - partHeight * 0.05
        verticalAlignment: Text.AlignBottom
        width: parent.width
        fontSizeMode: Text.Fit

        font.pixelSize: partHeight * 0.26 * (layoutType === 0 ? 1 : 0.7)
        font.pointSize: -1
        color: theme.highlightColor

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
        color: theme.backgroundColor
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

        onClicked: {
            if (mouse.button == Qt.MiddleButton) {
                main.reloadData()
            } else {
                plasmoid.expanded = !plasmoid.expanded
                lastReloadedNotifier.visible = !plasmoid.expanded
            }
        }

        PlasmaCore.ToolTipArea {
            id: toolTipArea
            anchors.fill: parent
            active: !plasmoid.expanded
            interactive: true
            mainText: placeAlias
            subText: tooltipSubText
            textFormat: Text.RichText
            icon: Qt.resolvedUrl('../images/weather-widget.svg')
        }
    }

}
