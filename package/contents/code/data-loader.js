var scheduledDataReload = null

function isReadyToReload(reloadIntervalMs, lastReloaded) {
    var now = new Date().getTime()

    dbgprint("loadingError=" + loadingError)
    dbgprint("scheduledDataReload=" + scheduledDataReload)
    dbgprint("lastReloaded=" + lastReloaded)
    dbgprint("reloadIntervalMs=" + reloadIntervalMs)
    dbgprint("reloadIntervalMs=" + ( now - lastReloaded ) + " > " + reloadIntervalMs)

    if (loadingError && scheduledDataReload !== null) {
        return scheduledDataReload < now
    }
    if (!lastReloaded) {
        lastReloaded = 0
    }
    return now - lastReloaded > reloadIntervalMs
}

function setReloaded() {
    loadingError = false
    return new Date().getTime()
}

function getLastReloadedTimeText(lastReloaded) {
    var reloadedAgoMs = getReloadedAgoMs(lastReloaded)

    var mins = reloadedAgoMs / 60000
    if (mins <= 180) {
        return Math.round(mins) + 'm'
    }

    var hours = mins / 60
    if (hours <= 48) {
        return Math.round(hours) + 'h'
    }

    var days = hours / 24
    if (days <= 14) {
        return Math.round(days) + 'd'
    }

    return 'long'
}

function scheduleDataReload() {
    var now = new Date().getTime()
    loadingError = true
    scheduledDataReload = now + 600000
}

function getReloadedAgoMs(lastReloaded) {
    if (!lastReloaded) {
        lastReloaded = 0
    }
    return new Date().getTime() - lastReloaded
}

function getPlasmoidStatus(lastReloaded, inTrayActiveTimeoutSec) {
    var reloadedAgoMs = getReloadedAgoMs(lastReloaded)
    if (reloadedAgoMs < inTrayActiveTimeoutSec*1000) {
        return PlasmaCore.Types.ActiveStatus
    } else {
        return PlasmaCore.Types.PassiveStatus
    }
}

function generateCacheKey(placeIdentifier) {
    return 'cache_' + Qt.md5(placeIdentifier)
}

function isXmlStringValid(xmlString) {
    return xmlString.indexOf('<?xml ') === 0 || xmlString.indexOf('<weatherdata>') === 0 || xmlString.indexOf('<current>') === 0
}

function fetchXmlFromInternet(getUrl, successCallback, failureCallback) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
          dbgprint(xhr.readyState)
            return
        }

        if (xhr.status !== 200) {
            dbgprint('ERROR - status: ' + xhr.status)
            dbgprint('ERROR - responseText: ' + xhr.responseText)
            failureCallback()
            return
        }

        // success
        dbgprint('successfully loaded from the internet')
        dbgprint('successfully of url-call: ' + getUrl)
        dbgprint('responseText: ' + xhr.responseText)

        var xmlString = xhr.responseText;
        if (!DataLoader.isXmlStringValid(xmlString)) {
            dbgprint('incoming xmlString is not valid: ' + xmlString)
            return
        }
        dbgprint('incoming text seems to be valid')

        successCallback(xmlString)
    }
    dbgprint('GET url opening: ' + getUrl)
    xhr.open('GET', getUrl)
    dbgprint('GET url sending: ' + getUrl)
    xhr.send()

    dbgprint('GET called for url: ' + getUrl)
    return xhr
}

function fetchJsonFromInternet(getUrl, successCallback, failureCallback) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return
        }

        if (xhr.status !== 200) {
            dbgprint('ERROR - status: ' + xhr.status)
            dbgprint('ERROR - responseText: ' + xhr.responseText)
            failureCallback()
            return
        }

        // success
        dbgprint('successfully loaded from the internet')
        dbgprint('successfully of url-call: ' + getUrl)
        dbgprint('responseText: ' + xhr.responseText)

        var jsonString = xhr.responseText;
        if (!DataLoader.IsJsonString(jsonString)) {
            dbgprint('incoming jsonString is not valid: ' + jsonString)
            return
        }
        dbgprint('incoming text seems to be valid')

        successCallback(jsonString)
    }
    dbgprint('GET url opening: ' + getUrl)
    xhr.open('GET', getUrl)
    dbgprint('GET url sending: ' + getUrl)
    xhr.send()

    dbgprint('GET called for url: ' + getUrl)
    return xhr
}

function IsJsonString(str) {
    try {
        JSON.parse(str);
    } catch (e) {
        return false;
    }
    return true;
}
