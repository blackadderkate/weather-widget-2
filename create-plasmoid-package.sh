#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
cd $DIR
rm -r buildWidget
mkdir buildWidget

cd package

zip  -r ../buildWidget/weather-widget-2.plasmoid * --exclude \.git\* contents/code/db/meh.sh contents/code/db/

