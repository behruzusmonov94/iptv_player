#include "playlistmanager.h"
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QUrl>


PlaylistManager::PlaylistManager(QObject *parent) : QAbstractListModel(parent) {
  loadPlaylists();
}

int PlaylistManager::rowCount(const QModelIndex &parent) const {
  if (parent.isValid())
    return 0;
  return m_playlists.count();
}

QVariant PlaylistManager::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_playlists.count())
    return QVariant();

  const PlaylistInfo &playlist = m_playlists[index.row()];

  switch (role) {
  case NameRole:
    return playlist.name;
  case SourceRole:
    return playlist.source;
  case IsUrlRole:
    return playlist.isUrl;
  default:
    return QVariant();
  }
}

QHash<int, QByteArray> PlaylistManager::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[NameRole] = "name";
  roles[SourceRole] = "source";
  roles[IsUrlRole] = "isUrl";
  return roles;
}

void PlaylistManager::addPlaylist(const QString &name, const QString &source) {
  beginInsertRows(QModelIndex(), m_playlists.count(), m_playlists.count());

  PlaylistInfo info;
  info.name = name;
  info.source = source;

  QUrl url(source);
  // Simple heuristic: if it has schemes http/https/ftp, assume URL. Otherwise
  // file path.
  info.isUrl = (url.scheme().startsWith("http") || url.scheme() == "ftp");

  m_playlists.append(info);
  endInsertRows();

  savePlaylists();
}

void PlaylistManager::removePlaylist(int index) {
  if (index < 0 || index >= m_playlists.count())
    return;

  beginRemoveRows(QModelIndex(), index, index);
  m_playlists.removeAt(index);
  endRemoveRows();

  savePlaylists();
}

void PlaylistManager::editPlaylist(int index, const QString &name,
                                   const QString &source) {
  if (index < 0 || index >= m_playlists.count())
    return;

  m_playlists[index].name = name;
  m_playlists[index].source = source;

  QUrl url(source);
  m_playlists[index].isUrl =
      (url.scheme().startsWith("http") || url.scheme() == "ftp");

  emit dataChanged(this->index(index), this->index(index));
  savePlaylists();
}

QString PlaylistManager::getSource(int index) const {
  if (index < 0 || index >= m_playlists.count())
    return QString();
  return m_playlists[index].source;
}

QString PlaylistManager::getName(int index) const {
  if (index < 0 || index >= m_playlists.count())
    return QString();
  return m_playlists[index].name;
}

QString PlaylistManager::getConfigPath() const {
  QString path =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir dir(path);
  if (!dir.exists()) {
    dir.mkpath(path);
  }
  return path + "/playlists.json";
}

void PlaylistManager::savePlaylists() {
  QJsonArray array;
  for (const auto &p : m_playlists) {
    QJsonObject obj;
    obj["name"] = p.name;
    obj["source"] = p.source;
    obj["isUrl"] = p.isUrl;
    array.append(obj);
  }

  QJsonDocument doc(array);
  QFile file(getConfigPath());
  if (file.open(QIODevice::WriteOnly)) {
    file.write(doc.toJson());
    file.close();
  } else {
    qWarning() << "Failed to save playlists to" << getConfigPath();
  }
}

void PlaylistManager::loadPlaylists() {
  QFile file(getConfigPath());
  if (!file.open(QIODevice::ReadOnly)) {
    return; // File doesn't exist or can't be opened, just start empty
  }

  QByteArray data = file.readAll();
  file.close();

  QJsonDocument doc = QJsonDocument::fromJson(data);
  if (!doc.isArray())
    return;

  beginResetModel();
  m_playlists.clear();

  QJsonArray array = doc.array();
  for (const auto &val : array) {
    QJsonObject obj = val.toObject();
    PlaylistInfo info;
    info.name = obj["name"].toString();
    info.source = obj["source"].toString();
    // If "isUrl" is missing (old files), infer it
    if (obj.contains("isUrl")) {
      info.isUrl = obj["isUrl"].toBool();
    } else {
      QUrl url(info.source);
      info.isUrl = (url.scheme().startsWith("http") || url.scheme() == "ftp");
    }
    m_playlists.append(info);
  }
  endResetModel();
}
