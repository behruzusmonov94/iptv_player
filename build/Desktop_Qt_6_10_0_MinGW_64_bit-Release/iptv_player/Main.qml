import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import iptv.player 1.0

Window {
    id: mainWindow
    width: 1024
    height: 768
    visible: true
    title: qsTr("IPTV Player (Uzbek)")
    
    property bool isPinned: false
    property bool isFullScreenMode: false
    property bool sidebarVisible: true
    
    flags: isFullScreenMode 
           ? (Qt.Window | Qt.FramelessWindowHint | (isPinned ? Qt.WindowStaysOnTopHint : 0))
           : (Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint | (isPinned ? Qt.WindowStaysOnTopHint : 0))
    
    // Auto-maximize/restore if needed, or just let it occupy current size. 
    // User said "interface closes, full video shows", implying the window size might stay or fill screen. 
    // Often "Full Screen" implies `visibility: Window.FullScreen`. 
    // But user specifically said "X button invalid", "just interface closes". 
    // Let's stick to flags for now. If they want true Monitor Fullscreen, they usually assign visibility. 
    // Let's toggle visibility too if they want "real" fullscreen experience + frameless.
    // User text: "haqiqiy to'liq ekran qilmaydi shunchaki interfeys yopiladi" -> "It doesn't make real fullscreen, just interface closes". 
    // So DO NOT set Window.FullScreen. Just flags and UI hiding.

    PlaylistModel {
        id: playlistModel
    }


    FileDialog {
        id: fileDialog
        title: "Pleylistni tanlang (Select Playlist)"
        nameFilters: ["Playlist files (*.m3u *.m3u8)", "All files (*)"]
        onAccepted: {
            playlistModel.loadPlaylist(selectedFile)
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: categoryParams

        // Define pages as Components
        Component {
            id: categoryParams
            
            Rectangle {
                color: "#2b2b2b"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    Text {
                        text: "Kategoriyalar (Categories)"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: 20
                    }

                    ListView {
                        id: catListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: playlistModel.categories // Uses the new QStringList property

                        delegate: ItemDelegate {
                            width: parent.width
                            height: 50
                            
                            contentItem: Text {
                                text: modelData // modelData is the string in QStringList
                                color: "white"
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 20
                            }

                            background: Rectangle {
                                color: parent.highlighted ? "#0078d7" : "#333333"
                                border.color: "#444"
                                border.width: 1
                            }

                            highlighted: ListView.isCurrentItem
                            onClicked: {
                                playlistModel.filterChannels(modelData, "")
                                stackView.push(channelListComp, {categoryName: modelData})
                            }
                        }
                        ScrollBar.vertical: ScrollBar {}
                    }

                    Button {
                        text: "Pleylistni Ochish"
                        Layout.fillWidth: true
                        Layout.margins: 10
                        onClicked: fileDialog.open()
                    }
                }
            }
        }

        Component {
            id: channelListComp
            
            Rectangle {
                color: "#1e1e1e"
                property string categoryName: ""

                MediaPlayer {
                    id: player
                    videoOutput: videoOutput
                    audioOutput: AudioOutput {
                        volume: volumeSlider.value
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    color: "#333"
                    visible: !isFullScreenMode
                    
                    RowLayout {
                       anchors.fill: parent
                       anchors.margins: 10
                       
                       Button {
                           icon.source: "icons/back.svg"
                           icon.color: "white"
                           display: AbstractButton.IconOnly
                           background: Item {} // Transparent background for cleaner look
                           onClicked: stackView.pop()
                       }
                       
                       Text {
                           text: categoryName
                           color: "white"
                           font.bold: true
                           font.pixelSize: 18
                           horizontalAlignment: Text.AlignRight
                       }

                       TextField {
                           Layout.fillWidth: true
                           placeholderText: "Qidirish... (Search)"
                           onTextChanged: {
                               playlistModel.filterChannels(categoryName, text)
                           }
                       }
                    }
                }

                    // Split View for Channels + Player (reuse existing logic)
                    SplitView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: Qt.Horizontal

                        // Channel List
                        Rectangle {
                            id: playlistSidebar
                            SplitView.minimumWidth: 200
                            SplitView.preferredWidth: 300
                            color: "#2b2b2b"
                            visible: mainWindow.sidebarVisible && !mainWindow.isFullScreenMode

                            ListView {
                                id: channelListView
                                anchors.fill: parent
                                model: playlistModel
                                clip: true

                                delegate: ItemDelegate {
                                    width: parent.width
                                    text: model.name
                                    
                                    contentItem: Text {
                                        text: model.name
                                        color: "white"
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: parent.highlighted ? "#0078d7" : "transparent"
                                    }

                                    highlighted: ListView.isCurrentItem
                                    onClicked: {
                                        channelListView.currentIndex = index
                                        player.source = model.url
                                        player.play()
                                    }
                                }
                                ScrollBar.vertical: ScrollBar {}
                            }
                        }

                        // Video Player
                        Rectangle {
                            SplitView.fillWidth: true
                            color: "black"

                            VideoOutput {
                                id: videoOutput
                                anchors.fill: parent
                                
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true // To detect mouseX before press if needed, though drag works without
                                    
                                    property real lastY: 0
                                    property bool isVolumeDrag: false
                                    
                                    // Logic: 
                                    // If Fullscreen: Left side = Window Drag, Right side = Volume
                                    // If Normal: All side = Volume (since Window Drag isn't needed here, or strictly Volume?)
                                    // User said "video ustiga...". Let's enable Volume everywhere in Normal mode.
                                    // But wait, in Normal mode, we don't drag window via Video.
                                    // So: 
                                    // drag.target: mainWindow // THIS DOES NOT WORK for Windows
                                    
                                    onPressed: (mouse) => {
                                        lastY = mouse.y
                                        
                                        // Logic:
                                        // Left side + Fullscreen = Move Window
                                        // Right side OR Normal mode = Volume
                                        
                                        if (isFullScreenMode && mouse.x < width * 0.5) {
                                            mainWindow.startSystemMove()
                                        } else {
                                            isVolumeDrag = true
                                            volumeOverlay.visible = true
                                        }
                                    }
                                    
                                    onReleased: {
                                        isVolumeDrag = false
                                        volumeOverlay.visible = false
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        if (isVolumeDrag) {
                                            var delta = lastY - mouse.y
                                            // Sensitivity: full height = 1.0 (100%) change?
                                            // Let's say 2 pixels = 1% volume => 0.01
                                            var change = delta / height * 2.0 // Factor 2.0 speed
                                            
                                            // Update volume
                                            var newVol = player.audioOutput.volume + change
                                            if (newVol > 1.0) newVol = 1.0
                                            if (newVol < 0.0) newVol = 0.0
                                            
                                            player.audioOutput.volume = newVol
                                            volumeSlider.value = newVol // Sync slider
                                            
                                            lastY = mouse.y
                                        }
                                    }
                                    
                                    onDoubleClicked: isFullScreenMode = !isFullScreenMode
                                }

                                // Volume Overlay
                                Rectangle {
                                    id: volumeOverlay
                                    anchors.centerIn: parent
                                    width: 150
                                    height: 100
                                    color: "#aa000000" // Semi-transparent black
                                    radius: 10
                                    visible: false
                                    
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        
                                        Text {
                                            text: "Ovoz (Volume)"
                                            color: "white"
                                            font.bold: true
                                        }
                                        
                                        Text {
                                            text: Math.round(player.audioOutput.volume * 100) + "%"
                                            color: "white"
                                            font.pixelSize: 30
                                            font.bold: true
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Video yo'q"
                                color: "gray"
                                visible: player.playbackState === MediaPlayer.StoppedState
                            }
                        }
                    }

                    // Bottom Controls
                    Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        color: "#1e1e1e"
                        visible: !isFullScreenMode

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 15

                            Button {
                                icon.source: isPinned ? "icons/unpin.svg" : "icons/pin.svg"
                                icon.color: "white"
                                display: AbstractButton.IconOnly
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 4
                                    border.color: parent.hovered ? "#444" : "transparent"
                                }
                                onClicked: isPinned = !isPinned
                                ToolTip.visible: hovered
                                ToolTip.text: isPinned ? "Unpin" : "Pin"
                            }

                            Button {
                                icon.source: "icons/menu.svg"
                                icon.color: mainWindow.sidebarVisible ? "#0078d7" : "white"
                                display: AbstractButton.IconOnly
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 4
                                    border.color: parent.hovered ? "#444" : "transparent"
                                }
                                onClicked: mainWindow.sidebarVisible = !mainWindow.sidebarVisible
                                ToolTip.visible: hovered
                                ToolTip.text: "Ro'yxatni ochish/yopish"
                            }

                            Button {
                                icon.source: player.playbackState === MediaPlayer.PlayingState ? "icons/pause.svg" : "icons/play.svg"
                                icon.color: "white"
                                icon.width: 32
                                icon.height: 32
                                display: AbstractButton.IconOnly
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 16
                                    border.color: parent.hovered ? "#444" : "transparent"
                                }
                                onClicked: {
                                    if (player.playbackState === MediaPlayer.PlayingState)
                                        player.pause()
                                    else
                                        player.play()
                                }
                            }

                            Button {
                                icon.source: "icons/stop.svg"
                                icon.color: "white"
                                display: AbstractButton.IconOnly
                                background: Rectangle {
                                    color: "transparent"
                                    radius: 4
                                    border.color: parent.hovered ? "#444" : "transparent"
                                }
                                onClicked: player.stop()
                            }

                            Text {
                                text: "Ovoz:"
                                color: "white"
                            }

                            Slider {
                                id: volumeSlider
                                from: 0
                                to: 1.0
                                value: 1.0
                                Layout.preferredWidth: 150
                            }

                            Item { Layout.fillWidth: true } // Spacer
                        }
                    }
                }
            }
        }
    }

    // frameless resizing handles
    // Only active when isFullScreenMode is true.
    
    // Right Edge
    MouseArea {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 10
        cursorShape: Qt.SizeHorCursor
        enabled: isFullScreenMode
        visible: isFullScreenMode
        onPressed: {
            mainWindow.startSystemResize(Qt.RightEdge)
        }
    }

    // Left Edge
    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 10
        cursorShape: Qt.SizeHorCursor
        enabled: isFullScreenMode
        visible: isFullScreenMode
        onPressed: {
            mainWindow.startSystemResize(Qt.LeftEdge)
        }
    }

    // Bottom Edge
    MouseArea {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 10
        cursorShape: Qt.SizeVerCursor
        enabled: isFullScreenMode
        visible: isFullScreenMode
        onPressed: {
            mainWindow.startSystemResize(Qt.BottomEdge)
        }
    }

    // Top Edge
    MouseArea {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 10
        cursorShape: Qt.SizeVerCursor
        enabled: isFullScreenMode
        visible: isFullScreenMode
        onPressed: {
            mainWindow.startSystemResize(Qt.TopEdge)
        }
    }

    // Bottom-Right Corner
    MouseArea {
        anchors { right: parent.right; bottom: parent.bottom }
        width: 20; height: 20
        cursorShape: Qt.SizeFDiagCursor
        enabled: isFullScreenMode
        visible: isFullScreenMode
        onPressed: {
            mainWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }
}
