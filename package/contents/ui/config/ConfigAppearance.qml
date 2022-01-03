import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {

    property int cfg_layoutType
    property alias cfg_inTrayActiveTimeoutSec: inTrayActiveTimeoutSec.value

    onCfg_layoutTypeChanged: {
        switch (cfg_layoutType) {
        case 0:
            layoutTypeGroup.current = layoutTypeRadioHorizontal;
            break;
        case 1:
            layoutTypeGroup.current = layoutTypeRadioVertical;
            break;
        case 2:
            layoutTypeGroup.current = layoutTypeRadioCompact;
            break;
        default:
        }
    }

    Component.onCompleted: {
        cfg_layoutTypeChanged()
    }

    ExclusiveGroup {
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
            text: i18n("Layout type:")
            Layout.alignment: Qt.AlignVCenter|Qt.AlignRight
        }
        RadioButton {
            id: layoutTypeRadioHorizontal
            exclusiveGroup: layoutTypeGroup
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
            exclusiveGroup: layoutTypeGroup
            text: i18n("Vertical")
            onCheckedChanged: if (checked) cfg_layoutType = 1;
        }
        RadioButton {
            id: layoutTypeRadioCompact
            exclusiveGroup: layoutTypeGroup
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
            text: i18n("Active timeout:")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        }
        SpinBox {
            id: inTrayActiveTimeoutSec
            decimals: 0
            stepSize: 10
            minimumValue: 10
            maximumValue: 8000
            suffix: i18nc("Abbreviation for seconds", "sec")
        }
        Label {
            text: i18n("NOTE: After this timeout widget will be hidden in system tray until refreshed. You can always set the widget to be always \"Shown\" in system tray \"Entries\" settings.")
            Layout.rowSpan: 3
            Layout.preferredWidth: 250
            wrapMode: Text.WordWrap
        }
    }

}
