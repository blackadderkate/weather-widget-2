#include "backend.h"

#include <QDebug>
#include <QFile>
#include <QDir>
#include <QStandardPaths>

Backend::Backend(QObject *parent) : QObject(parent) {
}

Backend::~Backend() {
}

void Backend::writeCache(const QString &cacheContent, const QString &plasmoidId) {
    
    qDebug() << "backend: writing cache, plasmoidId = " + plasmoidId;

    QString fileDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/plasmoids/org.kde.weatherWidget-2/");
    QDir().mkpath(fileDir);
    
    QString fileName(fileDir + "plasmoidId-" + plasmoidId + ".json");

    qDebug() << "backend: file " + fileName;

    QFile file( fileName );
    if (file.open(QIODevice::WriteOnly)) {
        QTextStream outstream( &file );
        outstream << cacheContent << endl;
    } else {
        qDebug() << "error opening file";
    }

    qDebug() << "backend: writing cache content finished";
}

QString Backend::readCache(const QString &plasmoidId) {
    
    qDebug() << "backend: reading cache, plasmoidId = " + plasmoidId;

    QString fileName(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    fileName += "/plasmoids/org.kde.weatherWidget-2/plasmoidId-";
    fileName += plasmoidId;
    fileName += ".json";

    qDebug() << "backend: file " + fileName;

    QString cacheContent;

    QFile file( fileName );
    if (file.open(QIODevice::ReadOnly)) {
        QTextStream instream(&file);
        while (!instream.atEnd()) {
            cacheContent += instream.readLine();
        }
    } else {
        qDebug() << "error opening file";
    }

    qDebug() << "backend: reading cache content finished";

    return cacheContent;
}
