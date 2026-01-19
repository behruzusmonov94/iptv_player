#ifndef PLAYLISTMANAGER_H
#define PLAYLISTMANAGER_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QString>


struct PlaylistInfo {
  QString name;
  QString source; // URL or File Path
  bool isUrl;
};

class PlaylistManager : public QAbstractListModel {
  Q_OBJECT
public:
  enum PlaylistRoles { NameRole = Qt::UserRole + 1, SourceRole, IsUrlRole };

  explicit PlaylistManager(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index,
                int role = Qt::DisplayRole) const override;
  QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE void addPlaylist(const QString &name, const QString &source);
  Q_INVOKABLE void removePlaylist(int index);
  Q_INVOKABLE void editPlaylist(int index, const QString &name,
                                const QString &source);

  // Getters for specific playlist details (helper for QML)
  Q_INVOKABLE QString getSource(int index) const;
  Q_INVOKABLE QString getName(int index) const;

private:
  void loadPlaylists();
  void savePlaylists();
  QString getConfigPath() const;

  QList<PlaylistInfo> m_playlists;
};

#endif // PLAYLISTMANAGER_H
