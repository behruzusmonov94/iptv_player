#include "playlistmanager.h"
#include "playlistmodel.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include <QIcon>

#include <QDebug>
#include <QFile>
#include <QIcon>


int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QString iconPath = ":/qt/qml/iptv_player/icons/iptv.png";
  if (!QFile::exists(iconPath)) {
    // Fallback or try alternative path (older Qt6 versions might differ)
    iconPath = ":/iptv_player/icons/iptv.png";
  }

  if (QFile::exists(iconPath)) {
    app.setWindowIcon(QIcon(iconPath));
  } else {
    qWarning() << "Icon file not found at:" << iconPath;
  }

  QQuickStyle::setStyle("Fusion");

  qmlRegisterType<PlaylistModel>("iptv.player", 1, 0, "PlaylistModel");

  // Register PlaylistManager globally
  PlaylistManager playlistManager;

  QQmlApplicationEngine engine;
  engine.rootContext()->setContextProperty("playlistManager", &playlistManager);
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("iptv_player", "Main");

  return app.exec();
}
