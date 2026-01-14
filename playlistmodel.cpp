#include "playlistmodel.h"
#include <QFile>
#include <QTextStream>
#include <QDebug>

PlaylistModel::PlaylistModel(QObject *parent)
    : QAbstractListModel(parent)
{
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
    beginResetModel();
    m_allChannels.clear();
    m_displayedChannels.clear();
    m_categories.clear();

    QString localPath = QUrl(filePath).toLocalFile();
    if (localPath.isEmpty()) {
        localPath = filePath;
    }

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Could not open playlist file:" << localPath;
        endResetModel();
        return;
    }

    QTextStream in(&file);
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

    file.close();

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
