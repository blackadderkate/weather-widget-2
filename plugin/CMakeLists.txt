set(plasmoidplugin_SRCS
    plasmoidplugin.cpp
    backend.cpp
    )

add_library(plasmoidplugin SHARED ${plasmoidplugin_SRCS})

target_link_libraries(plasmoidplugin Qt6::Quick Plasma::Plasma)

install(TARGETS plasmoidplugin DESTINATION ${QML_INSTALL_DIR}/org/kde/private/weatherWidget-2)

install(FILES qmldir DESTINATION ${QML_INSTALL_DIR}/org/kde/private/weatherWidget-2)
