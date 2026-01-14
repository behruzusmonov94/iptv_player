#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "playlistmodel.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<PlaylistModel>("iptv.player", 1, 0, "PlaylistModel");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("iptv_player", "Main");

    return app.exec();
}
