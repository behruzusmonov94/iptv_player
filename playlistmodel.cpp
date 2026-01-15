#include "playlistmodel.h"
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QSet>
#include <algorithm>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &PlaylistModel::onNetworkReplyFinished);
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_displayedChannels.count();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_displayedChannels.count())
        return QVariant();

    const Channel &channel = m_displayedChannels[index.row()];

    switch (role) {
    case NameRole:
        return channel.name;
    case UrlRole:
        return channel.url;
    case CategoryRole:
        return channel.category;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[UrlRole] = "url";
    roles[CategoryRole] = "category";
    return roles;
}

QStringList PlaylistModel::categories() const
{
    return m_categories;
}

void PlaylistModel::loadPlaylist(const QString &filePath)
{
    QUrl url(filePath);
    
    // Check if it's a URL (http/https)
    if (url.scheme() == "http" || url.scheme() == "https") {
        // Load from URL
        QNetworkRequest request(url);
        request.setRawHeader("User-Agent", "IPTV Player");
        QNetworkReply *reply = m_networkManager->get(request);
        // Store the reply pointer for cleanup in onNetworkReplyFinished
        reply->setProperty("originalUrl", filePath);
        return;
    }
    
    // Load from local file
    QString localPath = url.toLocalFile();
    if (localPath.isEmpty()) {
        localPath = filePath;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open playlist file:" << localPath;
        emit loadError(QString("Faylni ochib bo'lmadi: %1").arg(localPath));
        return;
    }

    QByteArray content = file.readAll();
    file.close();
    
    parsePlaylistContent(content);
}

void PlaylistModel::onNetworkReplyFinished(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Network error:" << reply->errorString();
        emit loadError(QString("URL yuklab bo'lmadi: %1").arg(reply->errorString()));
        reply->deleteLater();
        return;
    }

    QByteArray content = reply->readAll();
    reply->deleteLater();
    
    parsePlaylistContent(content);
}

void PlaylistModel::parsePlaylistContent(const QByteArray &content)
{
    beginResetModel();
    m_allChannels.clear();
    m_displayedChannels.clear();
    m_categories.clear();

    QTextStream in(content);
    QString line;
    QString currentName;
    QString currentCategory = "Boshqa (Others)"; // Default category
    QSet<QString> uniqueCategories;

    while (!in.atEnd()) {
        line = in.readLine().trimmed();

        if (line.isEmpty()) {
            continue;
        }

        if (line.startsWith("#EXTINF")) {
            // Reset category for the new entry, defaulting to "Boshqa (Others)"
            // Try to find group-title first (backward compatibility)
            currentCategory = "Boshqa (Others)";
            
            int groupTitleIndex = line.indexOf("group-title=\"");
            if (groupTitleIndex != -1) {
                int endQuote = line.indexOf("\"", groupTitleIndex + 13);
                if (endQuote != -1) {
                    currentCategory = line.mid(groupTitleIndex + 13, endQuote - (groupTitleIndex + 13));
                }
            }

            // Parse Name
            int commaIndex = line.lastIndexOf(',');
            if (commaIndex != -1) {
                currentName = line.mid(commaIndex + 1).trimmed();
            } else {
                currentName = "Unknown Channel";
            }
        } else if (line.startsWith("#EXTGRP:")) {
            // Handle #EXTGRP tag
            currentCategory = line.mid(8).trimmed();
        } else if (!line.startsWith("#")) {
            // Assume it's a URL
            if (!currentName.isEmpty()) {
                Channel channel;
                channel.name = currentName;
                channel.url = QUrl(line);
                channel.category = currentCategory;
                m_allChannels.append(channel);
                uniqueCategories.insert(currentCategory);
                
                currentName.clear();
            }
        }
    }

    // Sort categories
    m_categories = uniqueCategories.values();
    std::sort(m_categories.begin(), m_categories.end());
    emit categoriesChanged();
    
    // Initially show nothing or everything? 
    // Creating separate channel view implies we show filtered list later.
    // Let's leave currently display empty until user selects a category.
    
    endResetModel();
    emit layoutChanged();
}

void PlaylistModel::filterChannels(const QString &category, const QString &searchQuery)
{
    beginResetModel();
    m_displayedChannels.clear();
    for (const auto &channel : m_allChannels) {
        if (channel.category == category) {
            if (searchQuery.isEmpty() || channel.name.contains(searchQuery, Qt::CaseInsensitive)) {
                m_displayedChannels.append(channel);
            }
        }
    }
    endResetModel();
}

QUrl PlaylistModel::getChannelUrl(int index) const
{
    if (index >= 0 && index < m_displayedChannels.count()) {
        return m_displayedChannels[index].url;
    }
    return QUrl();
}

QString PlaylistModel::getChannelName(int index) const
{
    if (index >= 0 && index < m_displayedChannels.count()) {
        return m_displayedChannels[index].name;
    }
    return QString();
}
