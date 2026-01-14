#ifndef PLAYLISTMODEL_H
#define PLAYLISTMODEL_H

#include <QAbstractListModel>
#include <QString>
#include <QList>
#include <QUrl>

struct Channel {
    QString name;
    QUrl url;
    QString category;
};

class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QStringList categories READ categories NOTIFY categoriesChanged)

public:
    enum ChannelRoles {
        NameRole = Qt::UserRole + 1,
        UrlRole,
        CategoryRole
    };

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadPlaylist(const QString &filePath);
    Q_INVOKABLE void filterChannels(const QString &category, const QString &searchQuery);

    QStringList categories() const;

signals:
    void categoriesChanged();

private:
    QList<Channel> m_allChannels;
    QList<Channel> m_displayedChannels; // The ones currently visible in the view
    QStringList m_categories;
};

#endif // PLAYLISTMODEL_H
