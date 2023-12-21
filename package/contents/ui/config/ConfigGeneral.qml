import QtQuick
import QtQuick.Controls 2.15
// import QtQuick.Controls 2.15
import QtQuick.Layouts
import QtQuick.Dialogs
import "../../code/config-utils.js" as ConfigUtils
import "../../code/placesearch-helpers.js" as Helper
import "../../code/db/timezoneData.js" as TZData
import org.kde.plasma.components 3.0 as Plasmacore
import Qt.labs.qmlmodels
import org.kde.kirigami as Kirigami

import "mystuff"

Item {
    id: generalConfigPage

    property alias cfg_reloadIntervalMin: reloadIntervalMin.value
    property string cfg_places
    property alias cfg_debugLogging: debugLogging.checked
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property int editEntryNumber: -1
     Component.onCompleted: {

         console.log("***** kate" + addMetnoCityIdDialog.title)
         console.log("***** kate" + newMetnoCityLatitudeField.text)

        var places = ConfigUtils.getPlacesArray()
        var f = 0
        ConfigUtils.getPlacesArray().forEach(function (placeObj) {
            placesModel.appendRow({
                                      providerId: placeObj.providerId,
                                      placeIdentifier: placeObj.placeIdentifier,
                                      placeAlias: placeObj.placeAlias,
                                      timezoneID: (placeObj.timezoneID !== undefined) ? placeObj.timezoneID : -1,
                                      rowID: f
                                  })
            placesModelGUI.appendRow({
                                         providerId: placeObj.providerId,
                                         placeIdentifier: placeObj.placeIdentifier,
                                         placeAlias: placeObj.placeAlias,
                                         rowID: f
                                     })
            f++
        })
        let timezoneArray = TZData.TZData.sort(dynamicSort("displayName"))
        timezoneArray.forEach(function (tz) {
            timezoneDataModel.append({displayName: tz.displayName.replace(/_/gi, " "), id: tz.id});
        })
        placesModelGUI.rows = placesModel.rows
    }

    function dynamicSort(property) {
        var sortOrder = 1;

        if (property[0] === "-") {
            sortOrder = -1;
            property = property.substr(1);
        }

        return function (a,b) {
            if (sortOrder == -1){
                return b[property].localeCompare(a[property]);
            } else {
                return a[property].localeCompare(b[property]);
            }
        }
    }
    function isNumeric(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }
    function placesModelChanged() {
        var newPlacesArray = []
        for (var i = 0; i < placesModel.rowCount; i++) {
            var placeObj = placesModel.getRow(i)
            newPlacesArray.push({
                                    providerId: placeObj.providerId,
                                    placeIdentifier: placeObj.placeIdentifier,
                                    placeAlias: placeObj.placeAlias,
                                    timezoneID: (placeObj.timezoneID !== undefined) ? placeObj.timezoneID : -1

                                })
        }
        cfg_places = JSON.stringify(newPlacesArray)
    }
    function updatenewMetnoCityOKButton() {
        var latValid = newMetnoCityLatitudeField.acceptableInput
        var longValid = newMetnoCityLongitudeField.acceptableInput
        var altValid = newMetnoCityAltitudeField.acceptableInput
        console.log('******************')
        console.log(latValid)
        console.log(longValid)
        console.log(altValid)
        console.log(newMetnoCityAlias.length)
        console.log(addMetnoCityIdDialog.timezoneID)

        console.log('******************')
        if ((latValid && longValid && altValid) && (newMetnoCityAlias.length >0) && (addMetnoCityIdDialog.timezoneID > -1)) {
            buttons.standardButton(Dialog.Ok).enabled = true;
        }
    }
    function updateUrl() {
        var Url=""
        var latValid = newMetnoCityLatitudeField.acceptableInput
        var longValid = newMetnoCityLongitudeField.acceptableInput
        var altValid = newMetnoCityAltitudeField.acceptableInput
        if (latValid) {
            Url += "lat=" + (Number.fromLocaleString(newMetnoCityLatitudeField.text))
        }
        if (longValid) {
            if (Url.length > 0) {
                Url += "&"
            }
            Url += "lon=" + (Number.fromLocaleString(newMetnoCityLongitudeField.text))
        }
        if (altValid) {
            if (Url.length > 0) {
                Url += "&"
            }
            Url += "altitude=" + (Number.fromLocaleString(newMetnoCityAltitudeField.text))
        }
        newMetnoUrl.text = Url
        updatenewMetnoCityOKButton()
    }


    TableModel {
        id: placesModel
        TableModelColumn {
            display: "providerId"
        }
        TableModelColumn {
            display: "placeIdentifier"
        }
        TableModelColumn {
            display: "placeAlias"
        }
        TableModelColumn {
            display: "timezoneID"
        }
    }
    ListModel {
        id: myCSVData
    }
    ListModel {
        id: countryCodesModel
    }
    ListModel {
        id: filteredCSVData
    }
    ListModel {
        id: timezoneDataModel
    }
    ColumnLayout {
        id: rhsColumn
        width: parent.width
        spacing: 2

        Label {
            text: i18n("Plasmoid version:") + ' 2.3.5'
            Layout.alignment: Qt.AlignRight
        }

        Label {
            text: i18n("Location")
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }


        Rectangle {
            id: placesTable
            width: parent.width
            // columnSpacing: 1
            // rowSpacing: 1
            border.color:  Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            clip: true
            Layout.preferredHeight: 180
            Layout.preferredWidth: parent.width
            Layout.columnSpan: 2

            TableModel {
                id: placesModelGUI
                TableModelColumn {
                    display: "providerId"
                }
                TableModelColumn {
                    display: "placeIdentifier"
                }
                TableModelColumn {
                    display: "placeAlias"
                }
                // TableModelColumn {
                // display: "timezoneID"
                // }
                TableModelColumn {
                    display: "rowID"
                }
            }
            HorizontalHeaderView {
                id: myhorizontalHeader
                anchors.left: mytableView.left
                anchors.leftMargin: 0
                anchors.topMargin: 2
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 2

                syncView: mytableView
                clip: true
                model: ListModel {
                    Component.onCompleted: {
                        append({ display: ("Source") });
                        append({ display: ("Place Identifier") });
                        append({ display: ("Displayed as") });
                        append({ display: ("Description") });
                        // append({ display: ("TBA") });
                    }
                }
            }
            TableView {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.topMargin: myhorizontalHeader.height + 2
                anchors.rightMargin: 0
                implicitHeight: 200
                clip: true
                interactive: true
                rowSpacing: 1
                columnSpacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: placesModelGUI
                id: mytableView
                alternatingRows: true
                delegate: myChooser
                DelegateChooser {
                    id: myChooser
                    DelegateChoice {
                        column: 0
                        delegate: Rectangle {
                            implicitWidth: mytableView.width * 0.1
                            implicitHeight: defaultFontPixelSize
                            Text {
                                text: display
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: 0
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    DelegateChoice {
                        column: 1
                        delegate: Rectangle {
                            implicitWidth: mytableView.width * 0.45
                            Text {
                                text: display
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    DelegateChoice {
                        column: 2
                        delegate: Rectangle {
                            implicitWidth: mytableView.width * 0.2
                            Text {
                                id: tableLocation
                                text: display
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                    DelegateChoice {
                        column: 3
                        id:  myChoice3
                        delegate: GridLayout {
                            function findRow(ID) {
                                var f = 0
                                while (f < placesModel.rowCount) {
                                    if ((placesModel.rows[f].rowID) == ID) { break; }
                                    f++
                                }
                                if (f > placesModel.rowCount) { f=-1 }
                                return f
                            }
                            implicitWidth: mytableView.width * 0.3
                            columnSpacing: 1
                            Text {
                                id: myrowValue
                                // visible: false
                                text: display
                                // font.family: Kirigami.Theme.defaultFont.family
                                // font.pixelSize: defaultFontPixelSize
                                // anchors.verticalCenter: parent.verticalCenter
                            }
                            Plasmacore.Button {
                                id:myButton1
                                icon.name: 'go-up'
                                property int rownum1: findRow(myrowValue.text)
                                // enabled: rownum1 > 0  ? true : false
                                onClicked: {
                                    var row=findRow(myrowValue.text)
                                    if (row > 0) {
                                        placesModel.moveRow(row, row - 1, 1)
                                        placesModelGUI.moveRow(row, row - 1, 1)
                                        placesModelChanged()
                                        // myButton1.enabled= row === 1  ? false : true
                                    }
                                }
                            }
                            Plasmacore.Button {
                                id:myButton2
                                icon.name: 'go-down'
                                property int rownum2: findRow(myrowValue.text)
                                // enabled: rownum2 == (placesModelGUI.rowCount - 1)  ? false: true
                                onClicked: {
                                    var row=findRow(myrowValue.text)
                                    if (row < placesModel.rowCount - 1) {
                                        placesModel.moveRow(row, row + 1, 1)
                                        placesModelGUI.moveRow(row, row + 1, 1)
                                        placesModelChanged()
                                    }
                                }
                            }
                            Plasmacore.Button {
                                icon.name: 'list-remove'
                                onClicked: {
                                    var row=findRow(myrowValue.text)
                                    placesModel.removeRow(row, 1)
                                    placesModelGUI.removeRow(row, 1)
                                    placesModelChanged()
                                }
                            }
                            Plasmacore.Button {
                                icon.name: 'entry-edit'
                                onClicked: {
                                    var row=findRow(myrowValue.text)
                                    let entry = placesModel.getRow(row)
                                    if (entry.providerId === "metno") {
                                        let url=entry.placeIdentifier
                                        newMetnoUrl.text = url
                                        var data = url.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                                        newMetnoCityLatitudeField.text = Number(data[0]).toLocaleString(Qt.locale(),"f",5)
                                        newMetnoCityLongitudeField.text = Number(data[1]).toLocaleString(Qt.locale(),"f",5)
                                        newMetnoCityAltitudeField.text = (data[2] === undefined) ? 0:data[2]
                                        for (var i = 0; i < timezoneDataModel.count; i++) {
                                            if (timezoneDataModel.get(i).id == Number(entry.timezoneID)) {
                                                tzComboBox.currentIndex = i
                                                timezoneID = entry.timezoneID
                                                break
                                            }
                                        }
                                        newMetnoCityAlias.text = entry.placeAlias
                                        addMetnoCityIdDialog.open()
                                    }
                                    if (entry.providerId === "owm") {
                                        /*
                                    newOwmCityIdField.text = "https://openweathermap.org/city/"+entry.placeIdentifier
                                    newOwmCityAlias.text = entry.placeAlias
                                    addOwmCityIdDialog.open()
    */
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
        Row {
            Button {
                icon.name: 'list-add'
                text: 'OWM'
                width: 100
                onClicked: {
                    editEntryNumber = -1
                    addOwmCityIdDialog.open()
                    newOwmCityIdField.text = ''
                    newOwmCityAlias.text = ''
                    newOwmCityIdField.focus = true
                }
            }

            Button {
                icon.name: 'list-add'
                text: 'metno'
                width: 100
                onClicked: {

                    console.log("*** 1" + newMetnoCityLatitudeField.text)
                    console.log("*** 2" + newMetnoCityLatitudeField.text)
                    editEntryNumber = -1
                    newMetnoCityAlias.text = ''

                    newMetnoCityLatitudeField.text = ''
                    newMetnoCityLongitudeField.text = ''
                    newMetnoCityAltitudeField.text = ''
                    newMetnoUrl.text = ''
                    newMetnoCityLatitudeField.focus = true
                    addMetnoCityIdDialog.open()
                }
            }
        }

        Label {
            topPadding: 16
            bottomPadding: 6
            text: i18n("Miscellaneous")
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Item {
            id: reloadItem
            width: parent.width

            Label {
                id: reloadLabel1
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: i18n("Reload interval:")
                Layout.alignment: Qt.AlignLeft
                rightPadding: 6
            }
            SpinBox {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left:reloadLabel1.right
                id: reloadIntervalMin
                stepSize: 10

                from: 20
                to: 120
                // suffix: i18nc("Abbreviation for minutes", "min")

            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left:reloadIntervalMin.right
                text: i18nc("Abbreviation for minutes", "min")
                leftPadding: 6
            }
        }

        CheckBox {
            id: debugLogging
            checked: false
            text: "Debug"
            Layout.alignment: Qt.AlignLeft
            visible: false
        }

    }
    Item {
        anchors.bottom: parent.bottom
        Rectangle {
            color:  "red"

            anchors.fill: parent
            // anchors.top:
        }
        Label {
            id: attribution1
            anchors.bottom: attribution2.top
            anchors.bottomMargin: 2
            font: Kirigami.Theme.smallFont
            text: i18n("Met.no weather forecast data provided by The Norwegian Meteorological Institute.")
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: attribution1

                hoverEnabled: true

                onClicked: {
                    Qt.openUrlExternally('https://www.met.no/en/About-us')
                }

                onEntered: {
                    attribution1.font.underline = true
                }

                onExited: {
                    attribution1.font.underline = false
                }
            }
        }
        Label {
            id: attribution2
            anchors.bottom: attribution3.top
            anchors.bottomMargin: 2
            font: Kirigami.Theme.smallFont
            text: i18n("Sunrise/sunset data provided by Sunrise - Sunset.")
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: attribution2

                hoverEnabled: true

                onClicked: {
                    Qt.openUrlExternally('https://sunrise-sunset.org/about')
                }

                onEntered: {
                    attribution2.font.underline = true
                }

                onExited: {
                    attribution2.font.underline = false
                }
            }
        }
        Label {
            id: attribution3
            anchors.bottom: attribution4.top
            anchors.bottomMargin: 2
            font: Kirigami.Theme.smallFont
            text: i18n("OWM weather forecast data provided by OpenWeather.")
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: attribution3

                hoverEnabled: true

                onClicked: {
                    Qt.openUrlExternally('https://openweathermap.org/about-us')
                }

                onEntered: {
                    attribution3.font.underline = true
                }

                onExited: {
                    attribution3.font.underline = false
                }
            }
        }
        Label {
            id: attribution4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            font: Kirigami.Theme.smallFont
            text: i18n("Weather icons created by Erik Flowers.")
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: attribution4

                hoverEnabled: true

                onClicked: {
                    Qt.openUrlExternally('https://erikflowers.github.io/weather-icons/')
                }

                onEntered: {
                    attribution4.font.underline = true
                }

                onExited: {
                    attribution4.font.underline = false
                }
            }
        }
    }



    Dialog {
        id: changePlaceAliasDialog
        title: i18n("Change Displayed As")

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            placesModel.setProperty(changePlaceAliasDialog.tableIndex, 'placeAlias', newPlaceAliasField.text)
            placesModelChanged()
            changePlaceAliasDialog.close()
        }

        property int tableIndex: 0

        TextField {
            id: newPlaceAliasField
            placeholderText: i18n("Enter place alias")
            width: parent.width
        }
    }

    Dialog {
        id: addOwmCityIdDialog
        title: i18n("Add Open Weather Map Place")

        width: 500
        height: newOwmCityIdField.height * 9

        standardButtons: Dialog.Ok | Dialog.Cancel

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

            if (editEntryNumber === -1) {
                placesModel.append({
                                       providerId: 'owm',
                                       placeIdentifier: resultString,
                                       placeAlias: newOwmCityAlias.text
                                   })
            } else {
                placesModel.set(editEntryNumber,{
                                    providerId: 'owm',
                                    placeIdentifier: resultString,
                                    placeAlias: newOwmCityAlias.text
                                })
            }
            placesModelChanged()
            close()
        }

        TextField {
            id: newOwmCityIdField
            placeholderText: i18n("Paste URL here")
            width: parent.width
        }

        TextField {
            id: newOwmCityAlias
            anchors.top: newOwmCityIdField.bottom
            anchors.topMargin: 10
            placeholderText: i18n("City alias")
            width: parent.width
        }

        Label {
            id: owmInfo
            anchors.top: newOwmCityAlias.bottom
            anchors.topMargin: 10
            font.italic: true
            text: i18n("Find your city ID by searching here:")
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
            text: i18n("...and paste here the whole URL\ne.g. http://openweathermap.org/city/2946447 for Bonn, Germany.")
        }

    }

    Dialog {

        id: addMetnoCityIdDialog
        title: i18n("Add Met.no Map Place")

        property int timezoneID: -1

        width: generalConfigPage.width
        height: 400

        footer: DialogButtonBox {
            id: buttons
            standardButtons: Dialog.Ok | Dialog.Cancel
        }

        onOpened: {
            buttons.standardButton(Dialog.Ok).enabled = false;
        }

        onAccepted: {
            var resultString = newMetnoUrl.text
            if (resultString.length === 0) {
                resultString="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
            }
            if (editEntryNumber === -1) {
                placesModel.append({
                                       providerId: 'metno',
                                       placeIdentifier: resultString,
                                       placeAlias: newMetnoCityAlias.text,
                                       timezoneID: addMetnoCityIdDialog.timezoneID
                                   })
            } else {
                placesModel.set(editEntryNumber,{
                                    providerId: 'metno',
                                    placeIdentifier: resultString,
                                    placeAlias: newMetnoCityAlias.text,
                                    timezoneID: addMetnoCityIdDialog.timezoneID
                                })
            }
            placesModelChanged()
            close()
        }

Rectangle {
    anchors.horizontalCenter : parent.Center
        Item {
            id: metNoRowLayout
            width:  addMetnoCityIdDialog.width
            height: defaultFontPixelSize * 5
            property int labelWidth: 80
            property int textboxWidth:( metNoRowLayout.width - (3* metNoRowLayout) ) / 3
            Component.onCompleted: {
                console.log(metNoRowLayout.colwidth)
            }
            ColumnLayout{
                spacing: 8
                RowLayout {
                    id: metNoRowLayout1
                    Layout.preferredWidth: metNoRowLayout.width
                    Label {
                        text: ("Place Identifier")+": "
                        Layout.alignment: Qt.AlignVCenter
                    }
                    TextField {
                        id: newMetnoCityAlias
                        Layout.alignment: Qt.AlignVCenter
                        placeholderText: ("City alias")
                        onTextChanged: {
                            updateUrl()
                        }
                    }
                    Item {
                        // spacer item
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // Rectangle { anchors.fill: parent; color: "#ffaaaa" } // to visualize the spacer
                    }
                    Button {
                        text: ("Search")

                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            searchWindow.open()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        id: newMetnoCityLatitudeLabel
                        text: ("Latitude")+":"
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                        horizontalAlignment: Text.AlignRight
                    }
                    TextField {
                        id: newMetnoCityLatitudeField
                        Layout.preferredWidth: metNoRowLayout.textboxWidth
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: -90; top: 90; decimals: 5 }
                        color: acceptableInput ? newMetnoCityLatitudeLabel.color : "red"
                        onTextChanged: {
                            updateUrl()
                        }
                    }

                    Label {
                        id: newMetnoCityLongitudeLabel
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                        text: ("Longitude")+":"
                    }

                    TextField {
                        id: newMetnoCityLongitudeField
                        validator: DoubleValidator { bottom: -180; top: 180; decimals: 5 }
                        Layout.fillWidth: true
                        Layout.preferredWidth:  metNoRowLayout.textboxWidth
                        color: acceptableInput ? newMetnoCityLongitudeLabel.color : "red"
                        onTextChanged: {
                            updateUrl()
                        }
                    }
                    Label {
                        id: newMetnoCityAltitudeLabel
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                        text: ("Altitude")+":"
                    }

                    TextField {
                        id: newMetnoCityAltitudeField
                        Layout.fillWidth: true
                        Layout.preferredWidth:  metNoRowLayout.textboxWidth
                        validator: IntValidator { bottom: -999; top: 5000 }
                        color: acceptableInput ? newMetnoCityAltitudeLabel.color : "red"
                        onTextChanged: {
                            updateUrl()
                        }
                    }



                }
                RowLayout {
                    Layout.preferredWidth: metNoRowLayout.width
                    Label {
                        text: ("Url")+": "
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                    }
                    TextField {
                        id: newMetnoUrl
                        placeholderText: ("URL")
                        Layout.columnSpan: 5
                        Layout.fillWidth: true
                        color: acceptableInput ? newMetnoCityAltitudeLabel.color : "red"

                        function updateFields() {
                            function localiseFloat(data) {
                                return Number(data).toLocaleString(Qt.locale(),"f",5)
                            }

                            var data=newMetnoUrl.text.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                            if (data === undefined)
                                return
                            if (data.length === 3) {
                                var newlat = localiseFloat(data[0])
                                var newlon = localiseFloat(data[1])
                                var newalt = Number(data[2])
                                if ((! newMetnoCityLatitudeField.acceptableInput) || (newMetnoCityLatitudeField.text.length === 0) || (newMetnoCityLatitudeField.text !== newlat)) {
                                    newMetnoCityLatitudeField.text = newlat
                                }
                                if ((! newMetnoCityLongitudeField.acceptableInput) || (newMetnoCityLongitudeField.text.length === 0) || (newMetnoCityLongitudeField.text !== newlon)) {
                                    newMetnoCityLongitudeField.text = newlon
                                }
                                if ((! newMetnoCityAltitudeField.acceptableInput) || (newMetnoCityAltitudeField.text.length === 0)  || (newMetnoCityAltitudeField.text !== data[2])) {
                                    //                             if ((newalt >= newMetnoCityAltitudeField.validator.bottom) && (newalt <= newMetnoCityAltitudeField.validator.top)) {
                                    newMetnoCityAltitudeField.text = data[2]
                                    //                             }
                                }
                            }
                            updatenewMetnoCityOKButton()
                        }

                        onTextChanged: {
                            updateFields()
                        }

                        onEditingFinished: {
                            updateFields()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        id: newMetnoCityTimezoneLabel
                        text: ("Timezone")+":"
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                        horizontalAlignment: Text.AlignRight
                    }
                    ComboBox {
                        id: tzComboBox
                        model: timezoneDataModel
                        currentIndex: -1
                        textRole: "displayName"
                        Layout.preferredWidth: (metNoRowLayout.labelWidth * 3)
                        onCurrentIndexChanged: {
                            if (tzComboBox.currentIndex > 0) {
                                addMetnoCityIdDialog.timezoneID = timezoneDataModel.get(tzComboBox.currentIndex).id
                            }
                            updateUrl()
                        }
                    }
                }
            }
            /*








            /*
            TextField {
                width: (dlg.width / 3) * 0.6
            }
            Label {
                text: "hello:"
            }
            TextField {
                width: (dlg.width / 3) * 0.6
            }
    */
        }
}


    }


}




/*
MessageDialog {
    id: invalidData
    title: i18n("Error!")
    text: ""
    icon: StandardIcon.Critical
    informativeText: ""
    visible: false
}

MessageDialog {
    id: saveSearchedData
    title: i18n("Confirmation")
    text: i18n("Do you want to select this place?")
    icon: StandardIcon.Question
    standardButtons: StandardButton.Yes | StandardButton.No
    informativeText: ""
    visible: false
    onYes: {
        let data=filteredCSVData.get(tableView.currentRow)
        newMetnoCityLatitudeField.text=data["latitude"]
        newMetnoCityLongitudeField.text=data["longitude"]
        newMetnoCityAltitudeField.text=data["altitude"]
        newMetnoUrl.text="lat="+data["latitude"]+"&lon="+data["longitude"]+"&altitude="+data["altitude"]
        let loc=data["locationName"]+", "+Helper.getshortCode(countryList.textAt(countryList.currentIndex))
        newMetnoCityAlias.text=loc
        addMetnoCityIdDialog.timezoneID=data["timezoneId"]
        for (var i=0; i < timezoneDataModel.count; i++) {
            if (timezoneDataModel.get(i).id == Number(data["timezoneId"])) {
                tzComboBox.currentIndex=i
                break
            }
        }
        searchWindow.close()
        addMetnoCityIdDialog.open()
    }
}
*/
/*
Dialog {

    id: addMetnoCityIdDialog
    title: i18n("Add Met.no Map Place")

    property int timezoneID: -1

    width: 600

    footer: DialogButtonBox {
        id: buttons
        standardButtons: Dialog.Ok | Dialog.Cancel
    }

    onOpened: {
        buttons.standardButton(Dialog.Ok).enabled = false;
    }

    onAccepted: {
        var resultString = newMetnoUrl.text
        if (resultString.length === 0) {
            resultString="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
        }
        if (editEntryNumber === -1) {
            placesModel.append({
                                   providerId: 'metno',
                                   placeIdentifier: resultString,
                                   placeAlias: newMetnoCityAlias.text,
                                   timezoneID: addMetnoCityIdDialog.timezoneID
                               })
        } else {
            placesModel.set(editEntryNumber,{
                                providerId: 'metno',
                                placeIdentifier: resultString,
                                placeAlias: newMetnoCityAlias.text,
                                timezoneID: addMetnoCityIdDialog.timezoneID
                            })
        }
        placesModelChanged()
        close()
    }


    Item {
        id: metNoRowLayout
        width: 550
        property int labelWidth: 80
        property int textboxWidth:( metNoRowLayout.width - (3* metNoRowLayout) ) / 3
        Component.onCompleted: {
            console.log(metNoRowLayout.colwidth)
        }
        ColumnLayout{
            spacing: 8
            RowLayout {
                Layout.preferredWidth: metNoRowLayout.width
                Label {
                    text: ("Place Identifier")+": "
                    Layout.alignment: Qt.AlignVCenter
                }
                TextField {
                    id: newMetnoCityAlias
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: ("City alias")
                    onTextChanged: {
                        updateUrl()
                    }
                }
                Item {
                    // spacer item
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // Rectangle { anchors.fill: parent; color: "#ffaaaa" } // to visualize the spacer
                }
                Button {
                    text: ("Search")

                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        searchWindow.open()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    id: newMetnoCityLatitudeLabel
                    text: ("Latitude")+":"
                    Layout.preferredWidth: metNoRowLayout.labelWidth
                    horizontalAlignment: Text.AlignRight
                }
                TextField {
                    id: newMetnoCityLatitudeField
                    Layout.preferredWidth: metNoRowLayout.textboxWidth
                    Layout.fillWidth: true
                    validator: DoubleValidator { bottom: -90; top: 90; decimals: 5 }
                    color: acceptableInput ? newMetnoCityLatitudeLabel.color : "red"
                    onTextChanged: {
                        updateUrl()
                    }
                }

                Label {
                    id: newMetnoCityLongitudeLabel
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: metNoRowLayout.labelWidth
                    text: ("Longitude")+":"
                }

                TextField {
                    validator: DoubleValidator { bottom: -180; top: 180; decimals: 5 }
                    Layout.fillWidth: true
                    Layout.preferredWidth:  metNoRowLayout.textboxWidth
                    color: acceptableInput ? newMetnoCityLongitudeLabel.color : "red"
                    onTextChanged: {
                        updateUrl()
                    }
                }
                Label {
                    id: newMetnoCityAltitudeLabel
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: metNoRowLayout.labelWidth
                    text: ("Altitude")+":"
                }

                TextField {
                    id: newMetnoCityAltitudeField
                    Layout.fillWidth: true
                    Layout.preferredWidth:  metNoRowLayout.textboxWidth
                    validator: IntValidator { bottom: -999; top: 5000 }
                    color: acceptableInput ? newMetnoCityAltitudeLabel.color : "red"
                    onTextChanged: {
                        updateUrl()
                    }
                }



            }
            RowLayout {
                Layout.preferredWidth: metNoRowLayout.width
                Label {
                    text: ("Url")+": "
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: metNoRowLayout.labelWidth
                }
                TextField {
                    id: newMetnoUrl
                    placeholderText: ("URL")
                    Layout.columnSpan: 5
                    Layout.fillWidth: true
                    color: acceptableInput ? newMetnoCityAltitudeLabel.color : "red"

                    function updateFields() {
                        function localiseFloat(data) {
                            return Number(data).toLocaleString(Qt.locale(),"f",5)
                        }

                        var data=newMetnoUrl.text.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                        if (data === undefined)
                            return
                        if (data.length === 3) {
                            var newlat = localiseFloat(data[0])
                            var newlon = localiseFloat(data[1])
                            var newalt = Number(data[2])
                            if ((! newMetnoCityLatitudeField.acceptableInput) || (newMetnoCityLatitudeField.text.length === 0) || (newMetnoCityLatitudeField.text !== newlat)) {
                                newMetnoCityLatitudeField.text = newlat
                            }
                            if ((! newMetnoCityLongitudeField.acceptableInput) || (newMetnoCityLongitudeField.text.length === 0) || (newMetnoCityLongitudeField.text !== newlon)) {
                                newMetnoCityLongitudeField.text = newlon
                            }
                            if ((! newMetnoCityAltitudeField.acceptableInput) || (newMetnoCityAltitudeField.text.length === 0)  || (newMetnoCityAltitudeField.text !== data[2])) {
                                //                             if ((newalt >= newMetnoCityAltitudeField.validator.bottom) && (newalt <= newMetnoCityAltitudeField.validator.top)) {
                                newMetnoCityAltitudeField.text = data[2]
                                //                             }
                            }
                        }
                        updatenewMetnoCityOKButton()
                    }

                    onTextChanged: {
                        updateFields()
                    }

                    onEditingFinished: {
                        updateFields()
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    id: newMetnoCityTimezoneLabel
                    text: ("Timezone")+":"
                    Layout.preferredWidth: metNoRowLayout.labelWidth
                    horizontalAlignment: Text.AlignRight
                }
                ComboBox {
                    id: tzComboBox
                    model: timezoneDataModel
                    currentIndex: -1
                    textRole: "displayName"
                    Layout.preferredWidth: (metNoRowLayout.labelWidth * 3)
                    onCurrentIndexChanged: {
                        if (tzComboBox.currentIndex > 0) {
                            addMetnoCityIdDialog.timezoneID = timezoneDataModel.get(tzComboBox.currentIndex).id
                        }
                        updateUrl()
                    }
                }
            }
        }
    }



}


*/
/*
Dialog {
    title: i18n("Location Search")
    id: searchWindow
    width: 640
    height: 400
    standardButtons: StandardButton.Ok | StandardButton.Cancel
    onAccepted: {
        if(tableView.currentRow > -1) {
            saveSearchedData.open()
        }
    }
    Component.onCompleted: {
        let locale=Qt.locale().name.substr(3,2)
        let userCountry=Helper.getDisplayName(locale)
        let tmpDB=Helper.getDisplayNames()
        for (var i=0; i < tmpDB.length - 1 ; i++) {
            countryCodesModel.append({ id: tmpDB[i] })
            if (tmpDB[i] === userCountry) {
                countryList.currentIndex = i
            }
        }
    }
    TableView {
        id: tableView
        height: 140
        verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
        highlightOnFocus: true
        anchors.bottom: row2.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottomMargin: 10
        model: filteredCSVData
        TableViewColumn { role: "locationName"; title: i18n("Location") }
        TableViewColumn { role: "region"; title: i18n("Area"); width :75 }
        TableViewColumn { role: "latitude"; title: i18n("Latitude"); width :75 }
        TableViewColumn { role: "longitude"; title: i18n("Longitude"); width :75 }
        TableViewColumn { role: "altitude"; title: i18n("Altitude"); width :75}
        TableViewColumn { role: "timezoneName"; title: i18n("Timezone"); width :100}
        onDoubleClicked: {
            saveSearchedData.open()
        }
    }
    Item {
        id: row1
        anchors.bottom: parent.bottom
        height: 20
        width: parent.width
        Label {
            id:locationDataCredit
            text: i18n("Search data extracted from data provided by Geonames.org.")
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    MouseArea {
        cursorShape: Qt.PointingHandCursor
        anchors.fill: row1

        hoverEnabled: true

        onClicked: {
            Qt.openUrlExternally("https://www.geonames.org/")
        }

        onEntered: {
            locationDataCredit.font.underline = true
        }

        onExited: {
            locationDataCredit.font.underline = false
        }
    }

    Item {
        id: row2
        x: 0
        y: 0
        height: 54
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: row1.top
        anchors.bottomMargin: 0
        Label {
            id: countryLabel
            text: i18n("Country:")
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
        }

        QC215.ComboBox {
            id: countryList
            anchors.left: countryLabel.right
            anchors.leftMargin: 20
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            model: countryCodesModel
            width: 200
            editable: false
            onCurrentIndexChanged: {
                if (countryList.currentIndex > 0) {
                    Helper.loadCSVDatabase(countryList.textAt(countryList.currentIndex))
                }
            }
        }
        Label {
            id: locationLabel
            anchors.right: locationEdit.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: i18n("Filter:")
        }
        TextField {
            id: locationEdit
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            width: 160
            height: 31
            text: ""
            focus: true
            font.capitalization: Font.Capitalize
            selectByMouse: true
            clip: false
            Keys.onReturnPressed: {
                event.accepted = true
            }
            onTextChanged: {
                Helper.updateListView(locationEdit.text)
            }
        }
    }
*/

