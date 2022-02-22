#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
CURRDIR=$PWD
cd $DIR
rm -r buildWidget
mkdir buildWidget

#compile translations used inside the plasmoid
pushd translations/po
./build.sh
popd

cd package


VERSION="$( grep -i PluginInfo-Version ./metadata.desktop | cut -d'=' -f 2 )"
echo $VERSION

zip  -r "../buildWidget/weather-widget-$VERSION.plasmoid" * --exclude \.git\* --exclude *.bak
