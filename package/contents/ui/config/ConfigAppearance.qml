import QtQuick 2.2
import QtQuick.Controls
import QtQuick.Layouts 1.1
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    id: appearancePage
    property int cfg_layoutType
    property alias cfg_inTrayActiveTimeoutSec: inTrayActiveTimeoutSec.value
    property string cfg_widgetFontName: plasmoid.configuration.widgetFontName
    property string cfg_widgetFontSize: plasmoid.configuration.widgetFontSize
    property alias cfg_showLastReloadedTime: showLastReloadedTime.checked


    onCfg_layoutTypeChanged: {
        switch (cfg_layoutType) {
            case 0:
                layoutTypeGroup.checkedButton = layoutTypeRadioHorizontal;
                break;
            case 1:
                layoutTypeGroup.checkedButton = layoutTypeRadioVertical;
                break;
            case 2:
                layoutTypeGroup.checkedButton = layoutTypeRadioCompact;
                break;
            default:
        }
    }

    ListModel {
        id: fontsModel
        Component.onCompleted: {
            var arr = []
            arr.push({text: i18nc("Use default font", "Default"), value: ""})

            var fonts = Qt.fontFamilies()
            var foundIndex = 0
            for (var i = 0, j = fonts.length; i < j; ++i) {
                if (fonts[i] === cfg_widgetFontName) {
                    foundIndex = i
                }
                arr.push({text: fonts[i], value: fonts[i]})
            }
            append(arr)
            if (foundIndex > 0) {
                fontFamilyComboBox.currentIndex = foundIndex + 1
            }
        }
    }

    Component.onCompleted: {
        cfg_layoutTypeChanged()
    }

    ButtonGroup {
        id: layoutTypeGroup
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Layout")
        }

        RadioButton {
            Kirigami.FormData.label: i18n("Layout type") + ":"
            id: layoutTypeRadioHorizontal
            Layout.row: 0
            Layout.column: 0
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Horizontal")
            onCheckedChanged: if (checked) cfg_layoutType = 0;
        }
        RadioButton {
            id: layoutTypeRadioVertical
            Layout.row: 1
            Layout.column: 0
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Vertical")
            onCheckedChanged: if (checked) cfg_layoutType = 1;
        }
        RadioButton {
            id: layoutTypeRadioCompact
            Layout.row: 2
            Layout.column: 0
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Compact")
            onCheckedChanged: if (checked) cfg_layoutType = 2;
        }

        Label {
            text: i18n("NOTE: Setting layout type for in-tray plasmoid has no effect.")
            font: Kirigami.Theme.smallFont
            Layout.preferredWidth: 250
            wrapMode: Text.WordWrap
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("In-Tray Settings")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Active timeout") + ":"
            spacing: Kirigami.Units.smallSpacing
            SpinBox {
                id: inTrayActiveTimeoutSec
                Layout.alignment: Qt.AlignVCenter
                stepSize: 10
                from: 10
                to: 8000
                //            suffix: i18nc("Abbreviation for seconds", "sec")
            }
            Label {
                text: i18nc("Abbreviation for seconds", "sec")
            }
        }

        Label {
            text: i18n("NOTE: After this timeout widget will be hidden in system tray until refreshed. You can always set the widget to be always \"Shown\" in system tray \"Entries\" settings.")
            font: Kirigami.Theme.smallFont
            Layout.preferredWidth: 250
            wrapMode: Text.WordWrap
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            Kirigami.FormData.label: i18n("Widget font style") + ":"
            id: fontFamilyComboBox
            Layout.fillWidth: true
            currentIndex: 0
            //Layout.minimumWidth: Kirigami.Units.gridUnit * 10
            Layout.preferredWidth: 300
            model: fontsModel
            textRole: "text"

            onCurrentIndexChanged: {
                var current = model.get(currentIndex)
                if (current) {
                    cfg_widgetFontName = currentIndex === 0 ? Kirigami.Theme.defaultFont : current.value
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            Kirigami.FormData.label: i18n("Show last reloaded time") + ":"
            id: showLastReloadedTime
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Widget font size") + ":"
            spacing: Kirigami.Units.smallSpacing
            SpinBox {
                id: widgetFontSize
                Layout.alignment: Qt.AlignVCenter
                // decimals: 0
                stepSize: 1
                from: 4
                value: cfg_widgetFontSize
                to: 512
                onValueChanged: {
                    cfg_widgetFontSize = widgetFontSize.value
                }
            }
            Label {
                text: i18nc("pixels", "px")
            }
        }
    }
}
