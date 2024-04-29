import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {

    property int cfg_temperatureType
    property int cfg_pressureType
    property int cfg_windSpeedType
    property int cfg_timezoneType


    onCfg_temperatureTypeChanged: {
        switch (cfg_temperatureType) {
            case 0:
                temperatureTypeRadioCelsius.checked = true
                break
            case 1:
                temperatureTypeRadioFahrenheit.checked = true
                break
            case 2:
                temperatureTypeRadioKelvin.checked = true
                break
            default:
        }
    }

    onCfg_pressureTypeChanged: {
        switch (cfg_pressureType) {
            case 0:
                pressureTypeRadioHpa.checked = true
                break
            case 1:
                pressureTypeRadioInhg.checked = true
                break
            case 2:
                pressureTypeRadioMmhg.checked = true
                break
            default:
        }
    }

    onCfg_windSpeedTypeChanged: {
        switch (cfg_windSpeedType) {
            case 0:
                windSpeedTypeRadioMps.checked = true
                break
            case 1:
                windSpeedTypeRadioMph.checked = true
                break
            case 2:
                windSpeedTypeRadioKmh.checked = true
                break
            default:
        }
    }

    onCfg_timezoneTypeChanged: {
        switch (cfg_timezoneType) {
            case 0:
                timezoneTypeRadioUserLocalTime.checked = true
                break
            case 1:
                timezoneTypeRadioUtc.checked = true
                break
            case 2:
                timezoneTypeRadioLocationLocal.checked = true
                break
            default:
        }
    }

    Component.onCompleted: {
        cfg_temperatureTypeChanged()
        cfg_pressureTypeChanged()
        cfg_windSpeedTypeChanged()
        cfg_timezoneTypeChanged()
    }

    ButtonGroup {
        id: temperatureTypeGroup
    }

    ButtonGroup {
        id: pressureTypeGroup
    }

    ButtonGroup {
        id: windSpeedTypeGroup
    }

    ButtonGroup {
        id: timezoneTypeGroup
    }

    Kirigami.FormLayout {

        RadioButton {
            Kirigami.FormData.label: i18n("Temperature") + ":"

            id: temperatureTypeRadioCelsius
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("°C")
            onCheckedChanged: if (checked) cfg_temperatureType = 0
        }

        RadioButton {
            id: temperatureTypeRadioFahrenheit
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("°F")
            onCheckedChanged: if (checked) cfg_temperatureType = 1
        }

        RadioButton {
            id: temperatureTypeRadioKelvin
            ButtonGroup.group: temperatureTypeGroup
            text: i18n("K")
            onCheckedChanged: if (checked) cfg_temperatureType = 2
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Pressure") + ":"

            id: pressureTypeRadioHpa
            ButtonGroup.group: pressureTypeGroup
            text: i18n("hPa")
            onCheckedChanged: if (checked) cfg_pressureType = 0
        }

        RadioButton {
            id: pressureTypeRadioInhg
            ButtonGroup.group: pressureTypeGroup
            text: i18n("inHg")
            onCheckedChanged: if (checked) cfg_pressureType = 1
        }

        RadioButton {
            id: pressureTypeRadioMmhg
            ButtonGroup.group: pressureTypeGroup
            text: i18n("mmHg")
            onCheckedChanged: if (checked) cfg_pressureType = 2
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Wind speed") + ":"

            id: windSpeedTypeRadioMps
            ButtonGroup.group: windSpeedTypeGroup
            text: i18n("m/s")
            onCheckedChanged: if (checked) cfg_windSpeedType = 0
        }

        RadioButton {
            id: windSpeedTypeRadioMph
            ButtonGroup.group: windSpeedTypeGroup
            text: i18n("mph")
            onCheckedChanged: if (checked) cfg_windSpeedType = 1
        }

        RadioButton {
            id: windSpeedTypeRadioKmh
            ButtonGroup.group: windSpeedTypeGroup
            text: i18n("km/h")
            onCheckedChanged: if (checked) cfg_windSpeedType = 2
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Timezone") + ":"

            id: timezoneTypeRadioUserLocalTime
            ButtonGroup.group: timezoneTypeGroup
            text: i18n("My local-time")
            onCheckedChanged: if (checked) cfg_timezoneType = 0
        }

        RadioButton {
            id: timezoneTypeRadioUtc
            ButtonGroup.group: timezoneTypeGroup
            text: i18n("UTC")
            onCheckedChanged: if (checked) cfg_timezoneType = 1
        }

        RadioButton {
            id: timezoneTypeRadioLocationLocal
            ButtonGroup.group: timezoneTypeGroup
            text: i18n("Location Timezone")
            onCheckedChanged: if (checked) cfg_timezoneType = 2
        }
    }

}
