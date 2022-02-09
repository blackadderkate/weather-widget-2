#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
cd $DIR

if [ ! -d build ]; then
  mkdir build
fi

sudo rm -fr build/*

TMP=$(mktemp -d -u)
mv package/contents/locale $TMP
pushd  ./build

cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make
sudo make install

popd
mv $TMP package/contents/locale
