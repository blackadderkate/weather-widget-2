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

Item {
    id: compactRepresentationInTray
    
    anchors.fill: parent
    
    CompactItem {
        id: compactItem
        inTray: true
    }
    
    Plasmoid.toolTipMainText: placeAlias
    Plasmoid.toolTipSubText: tooltipSubText
    Plasmoid.toolTipTextFormat: Text.RichText
    Plasmoid.icon: Qt.resolvedUrl('../images/weather-widget.svg')
    
}
