var hourDurationMs = 1000 * 60 * 60
var wholeDayDurationMs = hourDurationMs * 24

/*
 tempInfoArray of objects: {
    temperature: '23'
    iconName: '45'
    isPast: false
 }
 */
function createEmptyNextDaysObject() {
    return {
        tempInfoArray: [],
        dayTitle: ''
    }
}

function populateNextDaysObject(nextDaysObj) {
    for (var i = 0; i < 4; i++) {

        var tempInfo = nextDaysObj.tempInfoArray[i]
        var hidden = false
        if (tempInfo === null) {
            tempInfo = {}
            nextDaysObj['temperature' + i] = 0
            nextDaysObj['iconName' + i] = ''
            nextDaysObj['isPast' + i] = false
            hidden = true
        } else {
            nextDaysObj['temperature' + i] = tempInfo.temperature
            nextDaysObj['iconName' + i] = tempInfo.iconName
            nextDaysObj['isPast' + i] = tempInfo.isPast
        }
        nextDaysObj['hidden' + i] = hidden
    }
}
