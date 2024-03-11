cmake_minimum_required(VERSION 3.14.0 FATAL_ERROR)
project(plasma-weather-widget)

set(QT_MAJOR_VERSION 6)
set(QT_MIN_VERSION "6.0.0")
set(KF6_MIN_VERSION "6.0.0")
set(PLASMA_MIN_VERSION "6.0.0")

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)

find_package(Qt6 ${REQUIRED_QT_VERSION} CONFIG REQUIRED Quick)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED)
find_package(Plasma ${PLASMA_MIN_VERSION} REQUIRED)
find_package(Plasma5Support ${PLASMA_MIN_VERSION} REQUIRED)

add_subdirectory(plugin)
add_subdirectory(translations)

plasma_install_package(package org.kde.weatherWidget-3)
