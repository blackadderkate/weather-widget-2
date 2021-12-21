#!/bin/sh

$XGETTEXT `find .. -name \*.qml -o -name \*.js` -L JavaScript -o $podir/plasma_applet_org.kde.weatherWidget.pot
