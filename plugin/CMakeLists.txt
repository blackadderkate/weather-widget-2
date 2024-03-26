set(plasmoidplugin_SRCS
    plasmoidplugin.cpp
    backend.cpp
    )

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt6::Quick Plasma::Plasma)

install(TARGETS plasmoidplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/private/weatherWidget-3)

install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/private/weatherWidget-3)
