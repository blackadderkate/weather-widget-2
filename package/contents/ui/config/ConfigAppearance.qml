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

    GridLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 3

        Item {
            width: 2
            height: 10
            Layout.columnSpan: 3
        }

        Label {
            text: i18n("Layout")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            font.bold: true
            Layout.columnSpan: 3
        }
        Label {
            text: i18n("Layout type") + ":"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
        RadioButton {
            id: layoutTypeRadioHorizontal
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Horizontal")
            onCheckedChanged: if (checked) cfg_layoutType = 0;
        }
        Label {
            text: i18n("NOTE: Setting layout type for in-tray plasmoid has no effect.")
            Layout.rowSpan: 3
            Layout.preferredWidth: 250
            wrapMode: Text.WordWrap
        }
        Item {
            width: 2
            height: 2
            Layout.rowSpan: 2
        }
        RadioButton {
            id: layoutTypeRadioVertical
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Vertical")
            onCheckedChanged: if (checked) cfg_layoutType = 1;
        }
        RadioButton {
            id: layoutTypeRadioCompact
            ButtonGroup.group: layoutTypeGroup
            text: i18n("Compact")
            onCheckedChanged: if (checked) cfg_layoutType = 2;
        }

        Item {
            width: 2
            height: 20
            Layout.columnSpan: 3
        }

        Label {
            text: i18n("In-Tray Settings")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            font.bold: true
            Layout.columnSpan: 3
        }


        Label {
            id: timeoutLabel
            text: i18n("Active timeout") + ":"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            height: inTrayActiveTimeoutSec.height
            // anchors.verticalCenter: inTrayActiveTimeoutSec.verticalCenter
        }
        Item {
            SpinBox {
                id: inTrayActiveTimeoutSec
                Layout.alignment: Qt.AlignVCenter
                stepSize: 10
                from: 10
                to: 8000
                anchors.verticalCenter: parent.verticalCenter
                //            suffix: i18nc("Abbreviation for seconds", "sec")
            }
            Label {
                text: i18nc("Abbreviation for seconds", "sec")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left:inTrayActiveTimeoutSec.right
                anchors.leftMargin: 4
            }
        }
        Label {
            text: i18n("NOTE: After this timeout widget will be hidden in system tray until refreshed. You can always set the widget to be always \"Shown\" in system tray \"Entries\" settings.")
            Layout.rowSpan: 3
            Layout.preferredWidth: 250
            wrapMode: Text.WordWrap
        }


        Item {
            width: 2
            height: 20
            Layout.columnSpan: 3
        }

        Label {
            text: i18n("Widget font style") + ":"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
        ComboBox {
            id: fontFamilyComboBox
            Layout.fillWidth: true
            currentIndex: 0
            Layout.minimumWidth: Kirigami.Units.gridUnit * 10
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
            width: 2
            height: 20
            Layout.columnSpan: 3
        }

        Label {
            text: i18n("Show last reloaded time") + ":"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }

        CheckBox {
            id: showLastReloadedTime
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            width: 2
            height: 20
            Layout.columnSpan: 3
        }

        Label {
            text: i18n("Widget font size") + ":"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            // anchors.verticalCenter: widgetFontSize.verticalCenter


        }
        Item {
            SpinBox {
                id: widgetFontSize
                Layout.alignment: Qt.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
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
                anchors.verticalCenter: parent.verticalCenter
                anchors.left:widgetFontSize.right
                text: i18nc("pixels", "px")
            }
        }
    }
}
