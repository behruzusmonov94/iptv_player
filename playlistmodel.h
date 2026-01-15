#ifndef PLAYLISTMODEL_H
#define PLAYLISTMODEL_H

#include <QAbstractListModel>
#include <QString>
#include <QList>
#include <QUrl>
#include <QNetworkAccessManager>
#include <QNetworkReply>

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
    Q_INVOKABLE QUrl getChannelUrl(int index) const;
    Q_INVOKABLE QString getChannelName(int index) const;

    QStringList categories() const;

signals:
    void categoriesChanged();
    void loadError(const QString &errorMessage);

private slots:
    void onNetworkReplyFinished(QNetworkReply *reply);

private:
    void parsePlaylistContent(const QByteArray &content);
    
    QList<Channel> m_allChannels;
    QList<Channel> m_displayedChannels; // The ones currently visible in the view
    QStringList m_categories;
    QNetworkAccessManager *m_networkManager;
};

#endif // PLAYLISTMODEL_H
