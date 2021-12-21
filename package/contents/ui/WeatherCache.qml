/*
 * Copyright 2015  Martin Kotelnik <clearmartin@seznam.cz>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */
import QtQuick 2.2
import org.kde.plasma.plasmoid 2.0

Item {
    id: weatherCache

    property var cacheId
    property var cacheBackend: null
    property bool cacheBackendFailedToInitialize: false
    
    function getCacheBackend() {
        if (cacheBackend !== null) {
            return cacheBackend
        }
        if (!cacheBackendFailedToInitialize) {
            dbgprint('initializing cacheBackend...')
            try {
                cacheBackend = Qt.createQmlObject('import org.kde.private.weatherWidget 1.0 as WW; WW.Backend {}', weatherCache, 'cacheBackend')
            } catch (e) {
                print('cacheBackend failed to initialize')
                cacheBackendFailedToInitialize = true
            }
            dbgprint('initializing cacheBackend...DONE ' + cacheBackend)
        }
        return cacheBackend
    }
    
    function writeCache(cacheContent) {
        dbgprint('writing cache')
        var backend = getCacheBackend()
        if (backend) {
            backend.writeCache(cacheContent, cacheId)
        } else {
            dbgprint('cacheBackend N/A')
        }
    }
    
    function readCache() {
        dbgprint('reading cache')
        var backend = getCacheBackend()
        if (backend) {
            return backend.readCache(cacheId)
        } else {
            dbgprint('cacheBackend N/A')
            return ''
        }
    }
    
}