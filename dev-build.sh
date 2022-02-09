#!/bin/bash

DIR="$( dirname "${BASH_SOURCE[0]}" )"
cd $DIR

if [ ! -d build ]; then
  mkdir build
else
  rm -fr build/*
fi

if [ -d package/contents/locale/ ]; then
  echo "Folder «package/contents/locale/» exist, removing it"
  rm -rf package/contents/locale/
fi

pushd  ./build

cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make
sudo make install

popd
