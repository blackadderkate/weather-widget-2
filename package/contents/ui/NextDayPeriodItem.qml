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
import org.kde.plasma.components 3.0 as PlasmaComponents
import "../code/icons.js" as IconTools
import "../code/unit-utils.js" as UnitUtils
import org.kde.kirigami as Kirigami

Item {
    property string temperature
    property string iconName
    property bool hidden
    property int partOfDay
    property double pixelFontSize
    
    onPixelFontSizeChanged: {
        if (pixelFontSize > 0) {
            temperatureText.font.pixelSize = pixelFontSize
            temperatureIcon.font.pixelSize = pixelFontSize
        }
    }
    
    Text {
        id: temperatureText
        font.pixelSize: defaultFontPixelSize
        text: UnitUtils.getTemperatureNumberExt(temperature, temperatureType)
        // Math.round(temperature) + '[]' + temperatureType
        visible: ! hidden
        width: parent.width / 2
        horizontalAlignment: Text.AlignRight
        color: Kirigami.Theme.textColor

    }
    Text {
        anchors.left: temperatureText.right
        id: temperatureIcon
        font.family: 'weathericons'
        font.pixelSize: defaultFontPixelSize
        text: (iconName > 0) ? IconTools.getIconCode(iconName, currentPlace.providerId, partOfDay) : '\uf07b'
        visible: ! hidden
        width: parent.width / 2
        horizontalAlignment: Text.AlignHCenter
        color: Kirigami.Theme.textColor
    }
}
