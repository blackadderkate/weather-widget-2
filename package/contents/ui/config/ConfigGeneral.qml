import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import org.kde.plasma.core 2.0 as PlasmaCore
import "../../code/config-utils.js" as ConfigUtils

Item {

    property alias cfg_reloadIntervalMin: reloadIntervalMin.value
    property string cfg_places

    ListModel {
        id: placesModel
    }

    Component.onCompleted: {
        var places = ConfigUtils.getPlacesArray()
        ConfigUtils.getPlacesArray().forEach(function (placeObj) {
            placesModel.append({
                providerId: placeObj.providerId,
                placeIdentifier: placeObj.placeIdentifier,
                placeAlias: placeObj.placeAlias
            })
        })
    }

    function placesModelChanged() {
        var newPlacesArray = []
        for (var i = 0; i < placesModel.count; i++) {
            var placeObj = placesModel.get(i)
            newPlacesArray.push({
                providerId: placeObj.providerId,
                placeIdentifier: placeObj.placeIdentifier,
                placeAlias: placeObj.placeAlias
            })
        }
        cfg_places = JSON.stringify(newPlacesArray)
        print('[weatherWidget] places: ' + cfg_places)
    }


    Dialog {
        id: addOwmCityIdDialog
        title: i18n('Add Open Weather Map Place')

        width: 500

        standardButtons: StandardButton.Ok | StandardButton.Cancel

        onAccepted: {
            var url = newOwmCityIdField.text
            var match = /https?:\/\/openweathermap\.org\/city\/([0-9]+)(\/)?/.exec(url)
            var resultString = null
            if (match !== null) {
                resultString = match[1]
            }

            if (resultString === null) {
                return
            }

            placesModel.append({
                providerId: 'owm',
                placeIdentifier: resultString,
                placeAlias: newOwmCityAlias.text
            })
            placesModelChanged()
            close()
        }

        TextField {
            id: newOwmCityIdField
            placeholderText: i18n('Paste URL here')
            width: parent.width
        }

        TextField {
            id: newOwmCityAlias
            anchors.top: newOwmCityIdField.bottom
            anchors.topMargin: 10
            placeholderText: i18n('City alias')
            width: parent.width
        }

        Label {
            id: owmInfo
            anchors.top: newOwmCityAlias.bottom
            anchors.topMargin: 10
            font.italic: true
            text: i18n('Find your city ID by searching here:')
        }

        Label {
            id: owmLink
            anchors.top: owmInfo.bottom
            font.italic: true
            text: 'http://openweathermap.org/find'
        }

        MouseArea {
            cursorShape: Qt.PointingHandCursor
            anchors.fill: owmLink

            hoverEnabled: true

            onClicked: {
                Qt.openUrlExternally(owmLink.text)
            }

            onEntered: {
                owmLink.font.underline = true
            }

            onExited: {
                owmLink.font.underline = false
            }
        }

        Label {
            anchors.top: owmLink.bottom
            font.italic: true
            text: i18n('...and paste here the whole URL\ne.g. http://openweathermap.org/city/2946447 for Bonn, Germany.')
        }

    }

    Dialog {
        id: addMetnoCityIdDialog
        title: i18n('Add Met.no Map Place')

        width: 500

        standardButtons: StandardButton.Ok | StandardButton.Cancel

        onAccepted: {
            function isNumeric(n) {
                return !isNaN(parseFloat(n)) && isFinite(n);
            }
            if (isNumeric(newMetnoCityLatitudeField.text) && isNumeric(newMetnoCityLongtitudeField.text)) {
                var resultString="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongtitudeField.text
                placesModel.append({
                    providerId: 'metno',
                    placeIdentifier: resultString,
                    placeAlias: newMetnoCityAlias.text
                })
                placesModelChanged()
                close()
            }
        }

        TextField {
            id: newMetnoCityLatitudeField
            placeholderText: i18n('Latitude')
            width: parent.width / 2

        }
        TextField {
            id: newMetnoCityLongtitudeField
            placeholderText: i18n('Longtitude')
            width: parent.width / 2
            anchors.left: newMetnoCityLatitudeField.right
        }

        TextField {
            id: newMetnoCityAlias
            anchors.top: newMetnoCityLatitudeField.bottom
            anchors.topMargin: 10
            placeholderText: i18n('City alias')
            width: parent.width
        }
    }

    Dialog {
        id: changePlaceAliasDialog
        title: i18n('Change Displayed As')

        standardButtons: StandardButton.Ok | StandardButton.Cancel

        onAccepted: {
            placesModel.setProperty(changePlaceAliasDialog.tableIndex, 'placeAlias', newPlaceAliasField.text)
            placesModelChanged()
            changePlaceAliasDialog.close()
        }

        property int tableIndex: 0

        TextField {
            id: newPlaceAliasField
            placeholderText: i18n('Enter place alias')
            width: parent.width
        }
    }

    GridLayout {
        columns: 2
        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            text: i18n('Plasmoid version: ') + '1.6.10'
            Layout.alignment: Qt.AlignRight
            Layout.columnSpan: 2
        }

        Label {
            text: i18n('Location')
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            width: 2
            height: 2
        }

        TableView {
            id: placesTable
            width: parent.width

            TableViewColumn {
                id: providerIdCol
                role: 'providerId'
                title: i18n('Source')
                width: parent.width * 0.1

                delegate: Label {
                    text: styleData.value
                    elide: Text.ElideRight
                    anchors.left: parent ? parent.left : undefined
                    anchors.leftMargin: 5
                    anchors.right: parent ? parent.right : undefined
                    anchors.rightMargin: 5
                }
            }

            TableViewColumn {
                id: placeIdentifierCol
                role: 'placeIdentifier'
                title: i18n('Place Identifier')
                width: parent.width * 0.4

                delegate: Label {
                    text: styleData.value
                    elide: Text.ElideRight
                    anchors.left: parent ? parent.left : undefined
                    anchors.leftMargin: 5
                    anchors.right: parent ? parent.right : undefined
                    anchors.rightMargin: 5
                }
            }

            TableViewColumn {
                role: 'placeAlias'
                title: i18n('Displayed as')
                width: parent.width * 0.2

                delegate: MouseArea {

                    anchors.fill: parent

                    Label {
                        id: placeAliasText
                        text: styleData.value
                        height: parent.height
                        anchors.left: parent.left
                        anchors.leftMargin: 5
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                    }

                    PlasmaCore.IconItem {
                        id: noAliasWarningIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 5
                        visible: placeAliasText.text === ''
                        height: parent.height
                        width: height
                        source: 'document-edit'
                    }

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        changePlaceAliasDialog.open()
                        changePlaceAliasDialog.tableIndex = styleData.row
                        newPlaceAliasField.text = placeAliasText.text
                        newPlaceAliasField.focus = true
                    }
                }
            }

            TableViewColumn {
                title: i18n('Action')
                width: parent.width * 0.2

                delegate: Item {

                    GridLayout {
                        height: parent.height
                        columns: 3
                        rowSpacing: 0

                        Button {
                            iconName: 'go-up'
                            Layout.fillHeight: true
                            onClicked: {
                                placesModel.move(styleData.row, styleData.row - 1, 1)
                                placesModelChanged()
                            }
                            enabled: styleData.row > 0
                        }

                        Button {
                            iconName: 'go-down'
                            Layout.fillHeight: true
                            onClicked: {
                                placesModel.move(styleData.row, styleData.row + 1, 1)
                                placesModelChanged()
                            }
                            enabled: styleData.row < placesModel.count - 1
                        }

                        Button {
                            iconName: 'list-remove'
                            Layout.fillHeight: true
                            onClicked: {
                                placesModel.remove(styleData.row)
                                placesModelChanged()
                            }
                        }
                    }
                }

            }
            model: placesModel
            Layout.preferredHeight: 150
            Layout.preferredWidth: parent.width
            Layout.columnSpan: 2
        }

        Row {
            Layout.columnSpan: 2

            Button {
                iconName: 'list-add'
                text: 'OWM'
                width: 100
                onClicked: {
                    addOwmCityIdDialog.open()
                    newOwmCityIdField.text = ''
                    newOwmCityAlias.text = ''
                    newOwmCityIdField.focus = true
                }
            }

            Button {
                iconName: 'list-add'
                text: 'metno'
                width: 100
                onClicked: {
                    addMetnoCityIdDialog.open()
                    newMetnoCityAlias.text = ''
                    newMetnoCityLatitudeField.text = ''
                    newMetnoCityLongtitudeField.text = ''
                    newOwmCityIdField.focus = true
                }
            }


        }

        Item {
            width: 2
            height: 20
            Layout.columnSpan: 2
        }

        Item {
            width: 2
            height: 2
            Layout.columnSpan: 2
        }

        Label {
            text: i18n('Miscellaneous')
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            width: 2
            height: 2
        }

        Label {
            text: i18n('Reload interval:')
            Layout.alignment: Qt.AlignRight
        }

        SpinBox {
            id: reloadIntervalMin
            decimals: 0
            stepSize: 10
            minimumValue: 20
            maximumValue: 120
            suffix: i18nc('Abbreviation for minutes', 'min')
        }

    }

}
