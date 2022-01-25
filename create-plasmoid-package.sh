#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
VERSION="$( grep -i PluginInfo-Version package/metadata.desktop | cut -d'=' -f 2 )"
echo $VERSION
cd $DIR
rm -r buildWidget
mkdir buildWidget

cd package



zip  -r "../buildWidget/weather-widget-$VERSION.plasmoid" * --exclude \.git\*

