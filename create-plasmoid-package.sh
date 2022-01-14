#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
cd $DIR
rm -r build
mkdir build

cd package

zip  -r ../build/weather-widget-2.plasmoid * --exclude \.git\* contents/code/db/meh.sh contents/code/db/

