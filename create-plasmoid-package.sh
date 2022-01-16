#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
cd $DIR
rm -r buildWidget
mkdir buildWidget

cd package

zip  -r ../buildWidget/weather-widget-2.1.plasmoid * --exclude \.git\*

