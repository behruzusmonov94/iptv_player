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
                                    
                                    property real lastY: 0
                                    property real lastX: 0
                                    property real startX: 0
                                    property real startY: 0
                                    property bool isPressed: false
                                    property bool isVolumeDrag: false
                                    property bool isChannelDrag: false
                                    property bool isWindowMove: false
                                    property real minDragDistance: 50 // Minimum distance for channel switching
                                    property int lastSwitchedIndex: -1 // To prevent multiple switches during drag
                                    property string dragMode: "" // "volume", "channel", "window"
                                    property bool isDoubleClick: false // Track if double click happened
                                    
                                    // Function to switch to next channel
                                    function nextChannel() {
                                        if (channelListView.count > 0) {
                                            var nextIndex = channelListView.currentIndex + 1
                                            if (nextIndex >= channelListView.count) {
                                                nextIndex = 0 // Loop to first channel
                                            }
                                            if (nextIndex !== lastSwitchedIndex) {
                                                lastSwitchedIndex = nextIndex
                                                channelListView.currentIndex = nextIndex
                                                var channelUrl = playlistModel.getChannelUrl(nextIndex)
                                                if (channelUrl.toString() !== "") {
                                                    player.source = channelUrl
                                                    player.play()
                                                    // Show channel name overlay
                                                    channelOverlay.showChannel(nextIndex)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Function to switch to previous channel
                                    function previousChannel() {
                                        if (channelListView.count > 0) {
                                            var prevIndex = channelListView.currentIndex - 1
                                            if (prevIndex < 0) {
                                                prevIndex = channelListView.count - 1 // Loop to last channel
                                            }
                                            if (prevIndex !== lastSwitchedIndex) {
                                                lastSwitchedIndex = prevIndex
                                                channelListView.currentIndex = prevIndex
                                                var channelUrl = playlistModel.getChannelUrl(prevIndex)
                                                if (channelUrl.toString() !== "") {
                                                    player.source = channelUrl
                                                    player.play()
                                                    // Show channel name overlay
                                                    channelOverlay.showChannel(prevIndex)
                                                }
                                            }
                                        }
                                    }
                                    
                                    onPressed: (mouse) => {
                                        isPressed = true
                                        lastY = mouse.y
                                        lastX = mouse.x
                                        startX = mouse.x
                                        startY = mouse.y
                                        isVolumeDrag = false
                                        isChannelDrag = false
                                        isWindowMove = false
                                        dragMode = ""
                                        lastSwitchedIndex = -1
                                        isDoubleClick = false // Reset double click flag
                                    }
                                    
                                    onReleased: (mouse) => {
                                        isPressed = false
                                        
                                        var deltaX = Math.abs(mouse.x - startX)
                                        var deltaY = Math.abs(mouse.y - startY)
                                        
                                        // Don't process channel switching if:
                                        // 1. Double click happened
                                        // 2. Movement is very small (likely a click or double click, not a drag)
                                        if (isDoubleClick || (deltaX < 10 && deltaY < 10)) {
                                            // Reset states and return - this was a click, not a drag
                                            isVolumeDrag = false
                                            isChannelDrag = false
                                            isWindowMove = false
                                            dragMode = ""
                                            volumeOverlay.visible = false
                                            lastSwitchedIndex = -1
                                            return
                                        }
                                        
                                        // If no drag mode was detected during drag, check for final drag gesture on release
                                        // This handles cases where drag didn't reach threshold during movement
                                        if (dragMode === "") {
                                            // Horizontal drag - channel switching (only if not vertical drag)
                                            // Left swipe = next channel, Right swipe = previous channel
                                            if (deltaX > minDragDistance && deltaX > deltaY * 1.5) {
                                                var switchIndex = -1
                                                if (mouse.x < startX) {
                                                    // Swiped left = next channel
                                                    if (channelListView.count > 0) {
                                                        switchIndex = channelListView.currentIndex + 1
                                                        if (switchIndex >= channelListView.count) {
                                                            switchIndex = 0
                                                        }
                                                        nextChannel() // This will show overlay
                                                    }
                                                } else {
                                                    // Swiped right = previous channel
                                                    if (channelListView.count > 0) {
                                                        switchIndex = channelListView.currentIndex - 1
                                                        if (switchIndex < 0) {
                                                            switchIndex = channelListView.count - 1
                                                        }
                                                        previousChannel() // This will show overlay
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Reset all states
                                        isVolumeDrag = false
                                        isChannelDrag = false
                                        isWindowMove = false
                                        dragMode = ""
                                        volumeOverlay.visible = false
                                        lastSwitchedIndex = -1
                                    }
                                    
                                    onPositionChanged: (mouse) => {
                                        // CRITICAL: Only process if mouse is actually pressed
                                        if (!isPressed) {
                                            return
                                        }
                                        
                                        var deltaX = mouse.x - lastX
                                        var deltaY = mouse.y - lastY
                                        var totalDeltaX = Math.abs(mouse.x - startX)
                                        var totalDeltaY = Math.abs(mouse.y - startY)
                                        
                                        // Determine drag mode only once when threshold is reached
                                        if (dragMode === "") {
                                            // Priority 1: Fullscreen + left side + horizontal = window move
                                            if (isFullScreenMode && startX < width * 0.5) {
                                                if (totalDeltaX > 30 && totalDeltaX > totalDeltaY * 1.2) {
                                                    dragMode = "window"
                                                    isWindowMove = true
                                                    mainWindow.startSystemMove()
                                                    return // Window move started, exit
                                                }
                                            }
                                            
                                            // Priority 2: Vertical drag = volume control
                                            if (totalDeltaY > 15 && totalDeltaY > totalDeltaX) {
                                                dragMode = "volume"
                                                isVolumeDrag = true
                                                volumeOverlay.visible = true
                                                lastY = startY // Reset for accurate volume calculation
                                            }
                                            // Priority 3: Horizontal drag (not fullscreen left side) = channel switch
                                            else if (!(isFullScreenMode && startX < width * 0.5) && 
                                                     totalDeltaX > minDragDistance && 
                                                     totalDeltaX > totalDeltaY * 1.5) {
                                                dragMode = "channel"
                                                isChannelDrag = true
                                                
                                                // Switch channel only once when drag mode is detected
                                                // Left swipe = next channel, Right swipe = previous channel
                                                if (deltaX < -10) {
                                                    nextChannel() // Swiped left = next channel
                                                } else if (deltaX > 10) {
                                                    previousChannel() // Swiped right = previous channel
                                                }
                                            }
                                        }
                                        
                                        // Handle volume control (only if volume mode is active)
                                        if (dragMode === "volume" && isVolumeDrag) {
                                            var delta = lastY - mouse.y
                                            var change = delta / height * 2.0
                                            
                                            var newVol = player.audioOutput.volume + change
                                            if (newVol > 1.0) newVol = 1.0
                                            if (newVol < 0.0) newVol = 0.0
                                            
                                            player.audioOutput.volume = newVol
                                            volumeSlider.value = newVol
                                            
                                            lastY = mouse.y
                                        }
                                        
                                        // Note: Channel switching happens only once when dragMode is set to "channel"
                                        // No continuous channel switching during drag
                                    }
                                    
                                    onDoubleClicked: {
                                        isDoubleClick = true // Set flag to prevent channel switching
                                        isFullScreenMode = !isFullScreenMode
                                    }
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
                                
                                // Channel Name Overlay (bottom center)
                                Rectangle {
                                    id: channelOverlay
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 40
                                    width: Math.min(parent.width - 40, channelNameText.implicitWidth + 40)
                                    height: channelNameText.implicitHeight + 20
                                    color: "#cc000000" // Semi-transparent black
                                    radius: 8
                                    visible: false
                                    
                                    property Timer hideTimer: Timer {
                                        interval: 3000 // 3 seconds
                                        onTriggered: channelOverlay.visible = false
                                    }
                                    
                                    function showChannel(index) {
                                        var channelName = playlistModel.getChannelName(index)
                                        channelNameText.text = channelName
                                        visible = true
                                        hideTimer.restart() // Restart timer, will hide after 3 seconds
                                    }
                                    
                                    Text {
                                        id: channelNameText
                                        anchors.centerIn: parent
                                        text: ""
                                        color: "white"
                                        font.pixelSize: 18
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width - 20
                                        horizontalAlignment: Text.AlignHCenter
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
