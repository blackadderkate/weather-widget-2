import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../code/config-utils.js" as ConfigUtils
import "../../code/placesearch-helpers.js" as Helper
import "../../code/timezoneData.js" as TZData
import Qt.labs.qmlmodels
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    function dbgprint(msg) {
        if (!cfg_debugLogging) {
            return
        }

        print('[kate weatherWidget] ' + msg)
    }


    id: generalConfigPage

    property alias cfg_reloadIntervalMin: reloadIntervalMin.value
    property string cfg_places
    property alias cfg_debugLogging: debugLogging.checked
    property double defaultFontPixelSize: Kirigami.Theme.defaultFont.pixelSize
    property bool env_QML_XHR_ALLOW_FILE_READ: plasmoid.configuration.qml_XHR_ALLOW_FILE_READ
    property bool textColorLight: ((Kirigami.Theme.textColor.r + Kirigami.Theme.textColor.g + Kirigami.Theme.textColor.b) / 3) > 0.5
    property var backgroundColor: Kirigami.Theme.backgroundColor
    property var alternateBackgroundColor: Kirigami.Theme.alternateBackgroundColor
    property var highlightColor: Kirigami.Theme.highlightColor


    Component.onCompleted: {

        var places = ConfigUtils.getPlacesArray()
        var f = 0
        ConfigUtils.getPlacesArray().forEach(function (placeObj) {
            placesModel.appendRow({
                providerId: placeObj.providerId,
                placeIdentifier: placeObj.placeIdentifier,
                placeAlias: placeObj.placeAlias,
                timezoneID: (placeObj.timezoneID !== undefined) ? placeObj.timezoneID : -1,
            })
        })
        let timezoneArray = TZData.TZData.sort(dynamicSort("displayName"))
        timezoneArray.forEach(function (tz) {
            timezoneDataModel.append({displayName: tz.displayName.replace(/_/gi, " "), id: tz.id});
        })
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
        dbgprint("placesModelChanged")
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
        dbgprint("updatenewMetnoCityOKButton")
        var latValid = newMetnoCityLatitudeField.acceptableInput
        var longValid = newMetnoCityLongitudeField.acceptableInput
        var altValid = newMetnoCityAltitudeField.acceptableInput
        dbgprint(newMetnoCityAlias.length + "\t" + latValid + "\t" + longValid + "\t" + altValid + "\t" + addMetnoCityIdDialog.timezoneID )
        if ((latValid && longValid && altValid) && (newMetnoCityAlias.length >0) && (addMetnoCityIdDialog.timezoneID > -1)) {
            buttons.standardButton(Dialog.Ok).enabled = true
        } else {
            buttons.standardButton(Dialog.Ok).enabled = false
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

    ListModel {
        id: timezoneDataModel
    }

    ListModel {
        id: countryCodesModel
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

    TableModel {
        id: filteredCSVData
        TableModelColumn {
            display: "Location"
        }
        TableModelColumn {
            display: "Area"
        }
        TableModelColumn {
            display: "Latitude"
        }
        TableModelColumn {
            display: "Longitude"
        }
        TableModelColumn {
            display: "Altitude"
        }
        TableModelColumn {
            display: "Timezone"
        }
    }

    TableModel {
        id: myCSVData
        TableModelColumn {
            display: "Location"
        }
        TableModelColumn {
            display: "Area"
        }
        TableModelColumn {
            display: "Latitude"
        }
        TableModelColumn {
            display: "Longitude"
        }
        TableModelColumn {
            display: "Altitude"
        }
        TableModelColumn {
            display: "Timezone"
        }
        TableModelColumn {
            display: "timezoneId"
        }

    }

    // ConfigGeneral home page
    ColumnLayout {
        spacing: 0

        Kirigami.Heading {
            text: i18n("Location")
            type: Kirigami.Heading.Type.Primary
            level: 3
            Layout.alignment: Qt.AlignCenter
        }

        Kirigami.Separator {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
        }

        HorizontalHeaderView {
            id: myhorizontalHeader
            // anchors.left: mytableView.left
            // anchors.leftMargin: 0
            // anchors.topMargin: 2
            // anchors.top: parent.top
            // anchors.right: parent.right
            // anchors.rightMargin: 2

            syncView: mytableView
            clip: true
            model: ListModel {
                Component.onCompleted: {
                    append({ display: i18n("Source") });
                    append({ display: i18n("Place Identifier") });
                    append({ display: i18n("Displayed as") });
                    append({ display: i18n("Action") });
                    // append({ display: ("TBA") });
                }
            }
        }
        ScrollView {
            id: placesTable
            width: parent.width
            clip: true
            Layout.maximumHeight: 180
            Layout.preferredWidth: parent.width

            TableView {
                anchors.fill: parent
                property var columnWidths: [15, 35, 25, 25]
                columnWidthProvider: function (column) {
                    let minW = 500
                    let horizontalMargin = placesTable.effectiveScrollBarWidth !== 0 ? placesTable.effectiveScrollBarWidth : Kirigami.Units.smallSpacing
                    let aw = (placesTable.width > minW ? placesTable.width : minW) - horizontalMargin
                    return parseInt(aw * columnWidths[column] / 100)
                }

                implicitHeight: 200
                implicitWidth: 500
                clip: true
                interactive: true
                rowSpacing: 1
                columnSpacing: 1
                boundsBehavior: Flickable.StopAtBounds
                model: placesModel
                id: mytableView
                alternatingRows: true

                selectionBehavior: TableView.SelectRows
                selectionModel: ItemSelectionModel {}

                delegate: myChooser

                DelegateChooser {
                    id: myChooser
                    DelegateChoice {
                        column: 0
                        delegate: Rectangle {
                            implicitHeight: Kirigami.Units.gridUnit * 2
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                anchors.fill: parent
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: 0
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    DelegateChoice {
                        column: 1
                        delegate: Rectangle {
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                anchors.fill: parent
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                        }
                    }
                    DelegateChoice {
                        column: 2
                        delegate: Rectangle {
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                anchors.fill: parent
                                id: tableLocation
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                clip: true
                            }
                        }
                    }
                    DelegateChoice {
                        column: 3
                        id:  myChoice3
                        delegate: Rectangle {
                            color: (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            GridLayout {
                                anchors.fill: parent
                                columnSpacing: 1
                                Text {
                                    id: myrowValue
                                    visible: false
                                    text: "display"
                                }
                                Button {
                                    id:myButton1
                                    icon.name: 'go-up'
                                    enabled: row === 0  ? false : true
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (row > 0) {
                                                placesModel.moveRow(row, row - 1, 1)
                                                placesModelChanged()
                                            }
                                        }
                                    }
                                }
                                Button {
                                    id:myButton2
                                    icon.name: 'go-down'
                                    enabled: row == (placesModel.rowCount - 1)  ? false: true
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (row < placesModel.rowCount) {
                                                placesModel.moveRow(row, row + 1, 1)
                                                placesModelChanged()
                                            }
                                        }
                                    }
                                }
                                Button {
                                    icon.name: 'list-remove'
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            placesModel.removeRow(row, 1)
                                            placesModelChanged()
                                        }
                                    }
                                    enabled: (placesModel.rowCount > 1)
                                }
                                Button {
                                    icon.name: 'entry-edit'
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            let entry = placesModel.getRow(row)
                                            if (entry.providerId === "metno") {
                                                let url = entry.placeIdentifier
                                                newMetnoUrl.text = url
                                                var data = url.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                                                newMetnoCityLatitudeField.text = Number(data[0]).toLocaleString(Qt.locale(),"f",5)
                                                newMetnoCityLongitudeField.text = Number(data[1]).toLocaleString(Qt.locale(),"f",5)
                                                newMetnoCityAltitudeField.text = (data[2] === undefined) ? 0:data[2]
                                                dbgprint("timezone ID=" + entry.timezoneID)
                                                addMetnoCityIdDialog.timezoneID = entry.timezoneID
                                                for (var i = 0; i < timezoneDataModel.count; i++) {
                                                    if (timezoneDataModel.get(i).id == Number(entry.timezoneID)) {
                                                        tzComboBox.currentIndex = i
                                                        break
                                                    }
                                                }
                                                newMetnoCityAlias.text = entry.placeAlias
                                                addMetnoCityIdDialog.placeNumberID = row
                                                addMetnoCityIdDialog.open()
                                            }
                                            if (entry.providerId === "owm") {
                                                newOwmCityIdField.text = "https://openweathermap.org/city/"+entry.placeIdentifier
                                                newOwmCityAlias.text = entry.placeAlias
                                                addOwmCityIdDialog.placeNumberID = row
                                                addOwmCityIdDialog.open()

                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        Kirigami.FormLayout {

            Item {
                Kirigami.FormData.isSection: true
            }

            Button {
                Kirigami.FormData.label: i18n("Add Open Weather Map Place") + ":"
                icon.name: 'list-add'
                //text: 'OWM'
                //Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                onClicked: {
                    addOwmCityIdDialog.placeNumberID = -1
                    newOwmCityIdField.text = ''
                    newOwmCityAlias.text = ''
                    newOwmCityIdField.focus = true
                    addOwmCityIdDialog.open()
                }
            }

            Button {
                Kirigami.FormData.label: i18n("Add Met.no Map Place") + ":"
                icon.name: 'list-add'
                //text: 'metno'
                //Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                onClicked: {
                    newMetnoCityAlias.text = ''
                    newMetnoCityLatitudeField.text = ''
                    newMetnoCityLongitudeField.text = ''
                    newMetnoCityAltitudeField.text = ''
                    newMetnoUrl.text = ''
                    newMetnoCityLatitudeField.focus = true
                    addMetnoCityIdDialog.placeNumberID=-1
                    addMetnoCityIdDialog.open()
                }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Miscellaneous")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Reload interval") + ":"
                id: reloadItem
                spacing: Kirigami.Units.smallSpacing

                SpinBox {
                    id: reloadIntervalMin
                    stepSize: 10

                    from: 20
                    to: 120
                    // suffix: i18nc("Abbreviation for minutes", "min")

                }
                Label {
                    text: i18nc("Abbreviation for minutes", "min")
                    leftPadding: 6
                }
            }

            CheckBox {
                Kirigami.FormData.label: "Debug"
                id: debugLogging
                checked: false
                Layout.alignment: Qt.AlignLeft
                visible: false
            }

            Label {
                Kirigami.FormData.label: i18n("Plasmoid version") + ":"
                text: plasmoid.metaData.version
                Layout.alignment: Qt.AlignRight
            }
        }

        Kirigami.Separator {
            Layout.margins: Kirigami.Units.gridUnit
        }

        ColumnLayout {
            spacing: 0

            Label {
                id: attribution1
                font: Kirigami.Theme.smallFont
                text: i18n("Met.no weather forecast data provided by The Norwegian Meteorological Institute.")
                Layout.fillHeight: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
                font: Kirigami.Theme.smallFont
                text: i18n("Sunrise/sunset data provided by Sunrise - Sunset.")
                Layout.fillHeight: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
                font: Kirigami.Theme.smallFont
                text: i18n("OWM weather forecast data provided by OpenWeather.")
                Layout.fillHeight: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
                font: Kirigami.Theme.smallFont
                text: i18n("Weather icons created by Erik Flowers.")
                Layout.fillHeight: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
    }

    // changePlaceAliasDialog
    /*Dialog {
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
    }*/

    // addOwmCityIdDialog
    Dialog {
        id: addOwmCityIdDialog
        title: i18n("Add Open Weather Map Place")
        property int placeNumberID: -1
        width: 500
        height: newOwmCityIdField.height * 9
        footer: DialogButtonBox {
            id: owmButtons
            standardButtons: Dialog.Ok | Dialog.Cancel
        }

        onAccepted: {
            var url = newOwmCityIdField.text
            var match = /https?:\/\/openweathermap\.org\/city\/([0-9]+)(\/)?/.exec(url)

            var resultString = null

            if (match !== null) {
                resultString = match[1]

                dbgprint(addOwmCityIdDialog.placeNumberID)
                if (addOwmCityIdDialog.placeNumberID === -1) {
                    placesModel.appendRow({
                        providerId: 'owm',
                        placeIdentifier: resultString,
                        placeAlias: newOwmCityAlias.text,
                        timezoneID: -1
                    })
                } else {
                    placesModel.setRow(addOwmCityIdDialog.placeNumberID,{
                        providerId: 'owm',
                        placeIdentifier: resultString,
                        placeAlias: newOwmCityAlias.text,
                        timezoneID: -1
                    })
                }
                placesModelChanged()
                close()
            }
        }

        TextField {
            id: newOwmCityIdField
            placeholderText: i18n("Paste URL here")
            width: parent.width
            onTextChanged: {
                var match = /https?:\/\/openweathermap\.org\/city\/([0-9]+)(\/)?/.exec(newOwmCityIdField.text)
                if (match === null) {
                    owmButtons.standardButton(Dialog.Ok).enabled = false
                } else {
                    owmButtons.standardButton(Dialog.Ok).enabled = true
                }
            }
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
            text: i18n("Find your city ID by searching here") + ":"
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

    // addMetnoCityIdDialog
    Dialog {

        id: addMetnoCityIdDialog
        title: i18n("Add Met.no Map Place")

        property int timezoneID: -1
        property int placeNumberID: -1

        implicitWidth: generalConfigPage.width
        footer: DialogButtonBox {
            id: buttons
            standardButtons: Dialog.Ok | Dialog.Cancel
        }


        Item {
            anchors.fill: parent
            id: metNoRowLayout
            // implicitWidth: 550
            implicitHeight: metNoRow1.height * 4
            property int labelWidth: 80
            property int textboxWidth:( metNoRowLayout.width - (3* metNoRowLayout) ) / 3
            ColumnLayout{
                spacing: 8
                RowLayout {
                    id: metNoRow1
                    Layout.preferredWidth: metNoRowLayout.width
                    Label {
                        text: ("Place Identifier") + ":"
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
                        text: i18n("Search")

                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            addMetnoCityIdDialog.close()
                            searchWindow.open()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        id: newMetnoCityLatitudeLabel
                        text: i18n("Latitude") + ":"
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
                        text: i18n("Longitude") + ":"
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
                        text: i18n("Altitude") + ": "
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
                        text: i18n("Url")+": "
                        Layout.alignment: Qt.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: metNoRowLayout.labelWidth
                    }
                    TextField {
                        id: newMetnoUrl
                        placeholderText: i18n("URL")
                        Layout.columnSpan: 5
                        Layout.fillWidth: true
                        color: acceptableInput ? newMetnoCityAltitudeLabel.color : "red"

                        function updateFields() {
                            function localiseFloat(data) {
                                return Number(data).toLocaleString(Qt.locale(),"f",5)
                            }

                            var data = newMetnoUrl.text.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
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
                        text: i18n("Timezone") + ": "
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
        onOpened: {
            updatenewMetnoCityOKButton()
            // buttons.standardButton(Dialog.Ok).enabled = false;
        }

        onAccepted: {
            var resultString = newMetnoUrl.text
            if (resultString.length === 0) {
                resultString="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
            }
            if (addMetnoCityIdDialog.placeNumberID === -1) {
                placesModel.appendRow({
                    providerId: 'metno',
                    placeIdentifier: resultString,
                    placeAlias: newMetnoCityAlias.text,
                    timezoneID: addMetnoCityIdDialog.timezoneID
                })
            } else {
                placesModel.setRow(addMetnoCityIdDialog.placeNumberID,{
                    providerId: 'metno',
                    placeIdentifier: resultString,
                    placeAlias: newMetnoCityAlias.text,
                    timezoneID: addMetnoCityIdDialog.timezoneID
                })
            }
            placesModelChanged()
            close()
        }
    }

    // searchWindow
    Dialog {
        title: i18n("Location Search")
        id: searchWindow
        z: 1
        implicitWidth: parent.width - 40
        implicitHeight: parent.height - 40
        footer: DialogButtonBox {
            id: searchWindowButtons
            standardButtons: Dialog.Ok | Dialog.Cancel
        }

        HorizontalHeaderView {
            id: mysearchhorizontalHeader
            syncView: searchtableView
            clip: true
            model: ListModel {
                Component.onCompleted: {
                    append({ display: i18n("Location")  });
                    append({ display: i18n("Area") });
                    append({ display: i18n("Latitude") });
                    append({ display: i18n("Longitude") });
                    append({ display: i18n("Alt") });
                    append({ display: i18n("Timezone") });
                    // append({ display: ("TBA") });
                }
            }
        }

        ScrollView {
            id: placesTable1
            width: parent.width
            clip: true
            Layout.preferredHeight: 180
            Layout.preferredWidth: parent.width
            Layout.maximumHeight: 180

            Layout.columnSpan: 2
            // anchors.fill: parent
            anchors.bottom: row2.top
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.top: parent.top
            // anchors.bottomMargin: 10
            anchors.topMargin: mysearchhorizontalHeader.height + 2

            TableView {
                id: searchtableView
                anchors.fill: parent
                anchors.bottomMargin: 10 + placesTable1.effectiveScrollBarHeight
                anchors.rightMargin: 10 + placesTable1.effectiveScrollBarWidth
                // verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
                // highlightOnFocus: true
                property var columnWidths: [30, 15, 15, 12, 12, 30, -1]
                property int selectedRow: -1
                columnWidthProvider: function (column) {
                    let aw = placesTable1.width - placesTable1.effectiveScrollBarWidth
                    return parseInt(aw * columnWidths[column] / 100 )

                }

                model: filteredCSVData
                clip: true
                interactive: true
                rowSpacing: 1
                columnSpacing: 1

                boundsBehavior: Flickable.StopAtBounds
                implicitHeight: 200
                implicitWidth: 600
                Layout.maximumHeight: 200


                selectionBehavior: TableView.SelectRows
                selectionModel: ItemSelectionModel { }

                delegate: searchtableChooser

                DelegateChooser {
                    id: searchtableChooser
                    DelegateChoice {
                        column: 0

                        delegate: Rectangle {
                            required property bool selected
                            required property bool current
                            border.width: current ? 2 : 0
                            implicitWidth: searchtableView.width * 0.3
                            implicitHeight: defaultFontPixelSize + 4
                                color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.fill: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        column: 1
                        delegate: Rectangle {
                            implicitHeight: defaultFontPixelSize + 4
                            // implicitWidth: searchtableView.width * 0.1
                            color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        column: 2
                        delegate: Rectangle {
                            required property bool selected
                            required property bool current
                            implicitHeight: defaultFontPixelSize + 4
                            color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        column: 3
                        delegate: Rectangle {
                            implicitHeight: defaultFontPixelSize + 4
                            color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        column: 4
                        delegate: Rectangle {
                            implicitHeight: defaultFontPixelSize + 4
                            color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                    DelegateChoice {
                        column: 5
                        delegate: Rectangle {
                            height: defaultFontPixelSize + 4
                            color: (row === searchtableView.selectedRow) ? highlightColor : (row % 2) === 0 ? backgroundColor : alternateBackgroundColor
                            Text {
                                text: display
                                color: Kirigami.Theme.textColor
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: defaultFontPixelSize
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    searchtableView.selectedRow = row
                                }
                                onDoubleClicked: {
                                    saveSearchedData.rowNumber = row
                                    saveSearchedData.visible = true
                                    saveSearchedData.open()
                                }
                            }
                        }
                    }
                }
            }
        }
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: {
            if (searchtableView.selectedRow > -1) {
                saveSearchedData.rowNumber = searchtableView.selectedRow
                saveSearchedData.visible = true
                saveSearchedData.open()
            }
        }
        onOpened: {
            let locale = Qt.locale().name.substr(3,2)
            dbgprint(locale)
            let userCountry = Helper.getDisplayName(locale)
            let tmpDB = Helper.getDisplayNames()
            for (var i=0; i < tmpDB.length - 1 ; i++) {
                countryCodesModel.append({ id: tmpDB[i] })
                if (tmpDB[i] === userCountry) {
                    countryList.currentIndex = i
                }
            }
            dbgprint(Helper.getshortCode(userCountry))
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
                text: i18n("Country") + ":"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
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
                        // dbgprint("Loading Database: "+countryList.textAt(countryList.currentIndex))
                        Helper.loadCSVDatabase(countryList.textAt(countryList.currentIndex))
                        // Helper.loadCSVDatabase("Malta")
                    }
                    dbgprint(myCSVData.length)
                }
            }
            Label {
                id: locationLabel
                anchors.right: locationEdit.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: i18n("Filter") + ":"
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
    }

    Loader {
        id: saveSearchedData
        property int rowNumber
        function open() {
            if (item) {
                item.open();
            } else {
                active = true;
            }
            item.visible = true;
        }

        active: false

        sourceComponent: Dialog {
            title: i18n("Confirmation")
            z:2
            standardButtons: Dialog.Yes | Dialog.No
            visible: true
            Text {
                anchors.fill: parent
                text: i18n("Do you want to select") + " \"" + filteredCSVData.getRow(saveSearchedData.rowNumber).Location + "\" ?"

            }
            onAccepted: {
                let data = filteredCSVData.getRow(rowNumber)
                newMetnoCityLatitudeField.text = data["Latitude"]
                newMetnoCityLongitudeField.text = data["Longitude"]
                newMetnoCityAltitudeField.text = data["Altitude"]
                newMetnoUrl.text="lat="+data["Latitude"]+"&lon="+data["Longitude"]+"&altitude="+data["Altitude"]
                let loc = data["Location"]+", "+Helper.getshortCode(countryList.textAt(countryList.currentIndex))
                newMetnoCityAlias.text = loc
                addMetnoCityIdDialog.timezoneID = data["timezoneId"]
                for (var i=0; i < timezoneDataModel.count; i++) {
                    if (timezoneDataModel.get(i).id == Number(data["timezoneId"])) {
                        tzComboBox.currentIndex = i
                        break
                    }
                }
                searchWindow.close()
                addMetnoCityIdDialog.open()
                updatenewMetnoCityOKButton()
            }
            onRejected: {
                visible = false
                searchWindow.visible = true
            }
        }
    }

}
