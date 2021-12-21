#ifndef PLASMOIDPLUGIN_H
#define PLASMOIDPLUGIN_H

#include <QQmlExtensionPlugin>

class QQmlEngine;
class PlasmoidPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri);
};

#endif // PLASMOIDPLUGIN_H
