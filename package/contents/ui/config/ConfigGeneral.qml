import QtQuick 2.2
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import org.kde.plasma.core 2.0 as PlasmaCore
import "../../code/config-utils.js" as ConfigUtils
import "../../code/placesearch-helpers.js" as Helper
import "../../code/db/timezoneData.js" as TZData
Item {

    property alias cfg_reloadIntervalMin: reloadIntervalMin.value
    property string cfg_places
    property alias cfg_debugLogging: debugLogging.checked


    property int editEntryNumber: -1

    ListModel {
        id: placesModel
    }

    Component.onCompleted: {
        var places = ConfigUtils.getPlacesArray()
        ConfigUtils.getPlacesArray().forEach(function (placeObj) {
            placesModel.append({
                providerId: placeObj.providerId,
                placeIdentifier: placeObj.placeIdentifier,
                placeAlias: placeObj.placeAlias,
                timezoneID: (placeObj.timezoneID !== undefined) ? placeObj.timezoneID : -1
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
        var newPlacesArray = []
        for (var i = 0; i < placesModel.count; i++) {
            var placeObj = placesModel.get(i)
            newPlacesArray.push({
                providerId: placeObj.providerId,
                placeIdentifier: placeObj.placeIdentifier,
                placeAlias: placeObj.placeAlias,
                timezoneID: (placeObj.timezoneID !== undefined) ? placeObj.timezoneID : -1

            })
        }
        cfg_places = JSON.stringify(newPlacesArray)
        print('[weatherWidget] places: ' + cfg_places)
    }


    Dialog {
        id: addOwmCityIdDialog
        title: i18n("Add Open Weather Map Place")

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

    Dialog {
        id: addMetnoCityIdDialog
        title: i18n("Add Met.no Map Place")

        property int timezoneID: -1

        width: 500

        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onActionChosen: {

            function between(x, min, max) {
                return x >= min && x <= max;
            }

            if (action.button === Dialog.Ok) {
                var reason=""
                var reasoncount=0;
                var latValid=isNumeric(newMetnoCityLatitudeField.text)
                var longValid=isNumeric(newMetnoCityLongitudeField.text)

                action.accepted = false

                if (!(latValid)) {
                    reason+=i18n("The Latitude is not numeric.")+"\n"
                    reasoncount++
                }
                else {
                    if (! between(newMetnoCityLatitudeField.text,-90,90)) {
                        reason+=i18n("The Latitude is not between -90 and 90.")+"\n"
                        reasoncount++
                    }
                }

                if (!(longValid)) {
                    reason+=i18n("The Longitude is not numeric.")+"\n"
                    reasoncount++
                }
                else {
                    if (! between(newMetnoCityLongitudeField.text,-180,180)) {
                        reason+=i18n("The Longitude is not between -180 and 180.")+"\n"
                        reasoncount++
                    }
                }

                if (newMetnoCityAlias.text.length === 0) {
                    reason+=i18n("The Place Name is empty.")+"\n"
                    reasoncount++
                }

                if (reasoncount === 0 ) {
                    action.accepted = true
                } else {
                    action.accepted = false
                    invalidData.text=i18np("There is an error!", "There are %1 errors!",reasoncount)
                    invalidData.informativeText=reason
                    invalidData.open()
                }
            }
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

        GridLayout {
            id: metNoRowLayout
            anchors.fill: parent
            columns: 8
            Label {
                id: newMetnoCityLatitudeLabel
                text: i18n("Latitude")+":"
            }

            TextField {
                id: newMetnoCityLatitudeField
                Layout.fillWidth: true
                onEditingFinished: {
                    if (isNumeric(newMetnoCityLatitudeField.text)) {
                        newMetnoUrl.text="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
                    }
                }
            }

            Item {
              width: 20
            }

            Label {
                id: newMetnoCityLongitudeLabel
                text: i18n("Longitude")+":"
            }

            TextField {
                id: newMetnoCityLongitudeField
                Layout.fillWidth: true
                onEditingFinished: {
                    if (isNumeric(newMetnoCityLongitudeField.text)) {
                        newMetnoUrl.text="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
                    }
                }
            }

            Item {
              width: 20
            }

            Label {
                id: newMetnoCityAltitudeLabel
                text: i18n("Altitude")+":"
            }

            TextField {
                id: newMetnoCityAltitudeField
                Layout.fillWidth: true
                onEditingFinished: {
                    if (isNumeric(newMetnoCityAltitudeField.text)) {
                        newMetnoUrl.text="lat="+newMetnoCityLatitudeField.text+"&lon="+newMetnoCityLongitudeField.text+"&altitude="+newMetnoCityAltitudeField.text
                    }
                }
            }

            Label {
              text: i18n("URL")+":"
            }
          TextField {
              id: newMetnoUrl
              placeholderText: i18n("URL")
              Layout.columnSpan: 5
              Layout.fillWidth: true

              onEditingFinished: {
                  var data=newMetnoUrl.text.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                  if (data.length === 3) {
                    newMetnoCityLatitudeField.text=data[0]
                    newMetnoCityLongitudeField.text=data[1]
                    newMetnoCityAltitudeField.text=data[2]
                  }
              }
          }
            ComboBox {
                id: tzComboBox
                model: timezoneDataModel
                currentIndex: -1
                textRole: "displayName"
                Layout.columnSpan: 2
                Layout.fillWidth: true
                onCurrentIndexChanged: {
                    if (tzComboBox.currentIndex > 0) {
//                         console.log(tzComboBox.currentIndex)
//                         console.log(JSON.stringify(timezoneDataModel.get(tzComboBox.currentIndex)))
                        addMetnoCityIdDialog.timezoneID = timezoneDataModel.get(tzComboBox.currentIndex).id

                    }
                }
            }
          Label {
              text: i18n("Place Identifier")+":"
          }
          TextField {
              id: newMetnoCityAlias
              placeholderText: i18n("City alias")
              Layout.columnSpan: 6
              Layout.fillWidth: true
          }
          Button {
              text: i18n("Search")
              Layout.alignment: Qt.AlignRight
              onClicked: {
                  searchWindow.open()
              }
          }
        }
    }

    Dialog {
        id: changePlaceAliasDialog
        title: i18n("Change Displayed As")

        standardButtons: StandardButton.Ok | StandardButton.Cancel

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
    }

    ColumnLayout{
        id: rhsColumn
        width: parent.width

        Label {
            text: i18n("Plasmoid version:") + ' 2.2.2'
            Layout.alignment: Qt.AlignRight
        }

        Label {
              text: i18n("Location")
              font.bold: true
              Layout.alignment: Qt.AlignLeft
        }

        TableView {
            id: placesTable
            width: parent.width

            TableViewColumn {
                id: providerIdCol
                role: 'providerId'
                title: i18n("Source")
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
                title: i18n("Place Identifier")
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
                title: i18n("Displayed as")
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
                title: i18n("Action")
                width: parent.width * 0.2

                delegate: Item {

                    GridLayout {
                        height: parent.height
                        columns: 4
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
                        Button {
                            iconName: 'entry-edit'
                            Layout.fillHeight: true
                            onClicked: {
                                editEntryNumber = styleData.row
                                let entry = placesModel.get(styleData.row)
                                if (entry.providerId === "metno") {
                                    let url=entry.placeIdentifier
                                    newMetnoUrl.text = url
                                    var data = url.match(RegExp("([+-]?[0-9]{1,5}[.]?[0-9]{0,5})","g"))
                                    newMetnoCityLatitudeField.text = data[0]
                                    newMetnoCityLongitudeField.text = data[1]
                                    newMetnoCityAltitudeField.text = (data[2] === undefined) ? 0:data[2]
                                    for (var i = 0; i < timezoneDataModel.count; i++) {
                                      if (timezoneDataModel.get(i).id == Number(entry.timezoneID)) {
                                        tzComboBox.currentIndex = i
                                        addMetnoCityIdDialog.timezoneID = entry.timezoneID
                                        break
                                      }
                                    }
                                    newMetnoCityAlias.text = entry.placeAlias
                                    addMetnoCityIdDialog.open()
                                }
                                if (entry.providerId === "owm") {
                                    newOwmCityIdField.text = "https://openweathermap.org/city/"+entry.placeIdentifier
                                    newOwmCityAlias.text = entry.placeAlias
                                    addOwmCityIdDialog.open()
                                }
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
            Button {
                iconName: 'list-add'
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
                iconName: 'list-add'
                text: 'metno'
                width: 100
                onClicked: {
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
            bottomPadding: 4
            text: i18n("Miscellaneous")
            font.bold: true
            Layout.alignment: Qt.AlignLeft
        }

        Row {
            Label {
                text: i18n("Reload interval:")
                Layout.alignment: Qt.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: 6
            }
            SpinBox {
                id: reloadIntervalMin
                decimals: 0
                stepSize: 10
                minimumValue: 20
                maximumValue: 120
                suffix: i18nc("Abbreviation for minutes", "min")
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
        anchors.left: parent.left
        anchors.right: parent.right
        Label {
            id: attribution1
            anchors.bottom: attribution2.top
            anchors.bottomMargin: 2
            font.pointSize: 8
            text: i18n("Met.no weather forecast data provided by The Norwegian Meteorological Institute.")
        }
        Label {
            id: attribution2
            anchors.bottom: attribution3.top
            anchors.bottomMargin: 2
            font.pointSize: 8
            text: i18n("Sunrise/sunset data provided by Sunrise - Sunset.")
        }
        Label {
            id: attribution3
            anchors.bottom: attribution4.top
            anchors.bottomMargin: 2
            font.pointSize: 8
            text: i18n("OWM weather forecast data provided by OpenWeather.")
        }
        Label {
            id: attribution4
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            font.pointSize: 8
            text: i18n("Weather icons created by Erik Flowers.")
        }
        MouseArea {
            cursorShape: Qt.PointingHandCursor
            anchors.fill: attribution1

            hoverEnabled: true

            onClicked: {
                Qt.openUrlExternally('https://www.met.no/en/About-us')
            }

            onEntered: {
                owmLink.font.underline = true
            }

            onExited: {
                owmLink.font.underline = false
            }
        }
        MouseArea {
            cursorShape: Qt.PointingHandCursor
            anchors.fill: attribution2

            hoverEnabled: true

            onClicked: {
                Qt.openUrlExternally('https://sunrise-sunset.org/about')
            }

            onEntered: {
                owmLink.font.underline = true
            }

            onExited: {
                owmLink.font.underline = false
            }
        }
        MouseArea {
            cursorShape: Qt.PointingHandCursor
            anchors.fill: attribution3

            hoverEnabled: true

            onClicked: {
                Qt.openUrlExternally('https://openweathermap.org/about-us')
            }

            onEntered: {
                owmLink.font.underline = true
            }

            onExited: {
                owmLink.font.underline = false
            }
        }
        MouseArea {
            cursorShape: Qt.PointingHandCursor
            anchors.fill: attribution4

            hoverEnabled: true

            onClicked: {
                Qt.openUrlExternally('https://erikflowers.github.io/weather-icons/')
            }

            onEntered: {
                owmLink.font.underline = true
            }

            onExited: {
                owmLink.font.underline = false
            }
        }
    }
}
