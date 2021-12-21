#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>

class Backend : public QObject {
    
    Q_OBJECT
    
    public:
        explicit Backend(QObject *parent = 0);
        ~Backend();
        
    public Q_SLOTS:
        void writeCache(const QString &cacheContent, const QString &plasmoidId);
        QString readCache(const QString &plasmoidId);
        
};

#endif
