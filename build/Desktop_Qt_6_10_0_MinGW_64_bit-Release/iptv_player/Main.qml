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
    // visible: true // Removed to avoid conflict with visibility binding
    title: qsTr("IPTV Player (Uzbek)")
    
    property bool isPinned: false
    property bool isFramelessMode: false        // Toggled by Double-Click (Hides UI, Frameless)
    property bool isMonitorFullScreen: false    // Toggled by F11/Ctrl+F (Real Fullscreen)
    
    // Helper to check if we should hide UI
    readonly property bool isMinimalView: isFramelessMode || isMonitorFullScreen

    property bool sidebarVisible: true
    
    // Visibility: Only "Real" Fullscreen uses Window.FullScreen
    visibility: isMonitorFullScreen ? Window.FullScreen : Window.Windowed
    
    // Flags: Both modes require frameless look. 
    // If MonitorFullscreen, Qt handles borders usually, but FramelessWindowHint ensures no decorations.
    flags: (isFramelessMode || isMonitorFullScreen)
           ? (Qt.Window | Qt.FramelessWindowHint | (isPinned ? Qt.WindowStaysOnTopHint : 0))
           : (Qt.Window | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint | (isPinned ? Qt.WindowStaysOnTopHint : 0))

    Shortcut {
        sequence: "F11"
        onActivated: isMonitorFullScreen = !isMonitorFullScreen
    }
    
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: isMonitorFullScreen = !isMonitorFullScreen
    }
    
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
        onLoadError: (errorMessage) => {
            errorDialog.text = errorMessage
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        title: "Xatolik (Error)"
        anchors.centerIn: parent
        width: 400
        height: 150
        
        property string text: ""
        
        background: Rectangle {
            color: "#2b2b2b"
            border.color: "#444"
            border.width: 1
            radius: 5
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            Text {
                text: errorDialog.text
                color: "white"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignRight
                onClicked: errorDialog.close()
            }
        }
    }


    FileDialog {
        id: fileDialog
        title: "Pleylistni tanlang (Select Playlist)"
        nameFilters: ["Playlist files (*.m3u *.m3u8)", "All files (*)"]
        onAccepted: {
            playlistModel.loadPlaylist(selectedFile)
        }
    }

    Dialog {
        id: urlDialog
        title: "URL orqali ochish (Open from URL)"
        anchors.centerIn: parent
        width: 600
        height: 150
        
        property string urlText: ""
        
        background: Rectangle {
            color: "#2b2b2b"
            border.color: "#444"
            border.width: 1
            radius: 5
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            
            TextField {
                id: urlInput
                Layout.fillWidth: true
                placeholderText: "Playlist URL kiriting (Enter playlist URL)"
                text: urlDialog.urlText
                onTextChanged: urlDialog.urlText = text
                color: "white"
                background: Rectangle {
                    color: "#1e1e1e"
                    border.color: "#444"
                    border.width: 1
                    radius: 3
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                
                Button {
                    text: "Bekor qilish (Cancel)"
                    onClicked: urlDialog.close()
                }
                
                Button {
                    text: "Yuklash (Load)"
                    highlighted: true
                    enabled: urlInput.text.trim() !== ""
                    onClicked: {
                        if (urlInput.text.trim() !== "") {
                            playlistModel.loadPlaylist(urlInput.text.trim())
                            urlDialog.close()
                            urlInput.text = ""
                        }
                    }
                }
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: playlistSelectionComp

        // Define pages as Components
        Component {
            id: playlistSelectionComp
            
            Rectangle {
                color: "#2b2b2b"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: "#333"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Pleylistlar (Playlists)"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 18
                        }
                        
                        Button {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 10
                            text: "Qo'shish (Add)"
                            onClicked: addPlaylistDialog.openDialog()
                        }
                    }
                    
                    ListView {
                        id: playlistListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: playlistManager
                        
                        delegate: ItemDelegate {
                            width: parent.width
                            height: 60
                            
                            contentItem: RowLayout {
                                spacing: 10
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: model.name
                                        color: "white"
                                        font.bold: true
                                        font.pixelSize: 16
                                    }
                                    
                                    Text {
                                        text: model.source
                                        color: "#aaa"
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }
                                
                                Button {
                                    text: "Edit"
                                    onClicked: {
                                        addPlaylistDialog.openDialog(index, model.name, model.source)
                                    }
                                }
                                
                                Button {
                                    text: "O'chirish"

                                    onClicked: {
                                        deleteConfirmationDialog.deleteIndex = index
                                        deleteConfirmationDialog.open()
                                    }
                                }
                            }
                            
                            background: Rectangle {
                                color: parent.highlighted ? "#0078d7" : "#333333"
                                border.color: "#444"
                                border.width: 1
                            }
                            
                            onClicked: {
                                playlistModel.loadPlaylist(model.source)
                                stackView.push(categoryParams) // Go to categories
                            }
                        }
                        ScrollBar.vertical: ScrollBar {}
                    }
                }

                // Add/Edit Dialog
                Dialog {
                    id: addPlaylistDialog
                    title: isEdit ? "Tahrirlash (Edit)" : "Yangi Pleylist (New Playlist)"
                    anchors.centerIn: parent
                    width: 400
                    height: 250
                    
                    property bool isEdit: false
                    property int editIndex: -1
                    
                    function openDialog(index = -1, name = "", source = "") {
                        isEdit = (index !== -1)
                        editIndex = index
                        nameInput.text = name
                        sourceInput.text = source
                        open()
                    }
                    
                    background: Rectangle {
                        color: "#2b2b2b"
                        border.color: "#444"
                        radius: 5
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15
                        
                        TextField {
                            id: nameInput
                            Layout.fillWidth: true
                            placeholderText: "Nomi (Name)"
                            color: "white"
                            background: Rectangle { color: "#1e1e1e"; border.color: "#444"; radius: 3 }
                        }
                        
                        RowLayout {
                             Layout.fillWidth: true
                             TextField {
                                 id: sourceInput
                                 Layout.fillWidth: true
                                 placeholderText: "URL yoki Fayl (URL or File)"
                                 color: "white"
                                 background: Rectangle { color: "#1e1e1e"; border.color: "#444"; radius: 3 }
                             }
                             Button {
                                 text: "..."
                                 onClicked: fileDialog.open()
                                 
                                 Connections {
                                     target: fileDialog
                                     function onAccepted() {
                                         sourceInput.text = fileDialog.selectedFile
                                     }
                                 }
                             }
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight
                            
                            Button {
                                text: "Bekor qilish (Cancel)"
                                onClicked: addPlaylistDialog.close()
                            }
                            
                            Button {
                                text: "Saqlash (Save)"
                                highlighted: true
                                enabled: nameInput.text !== "" && sourceInput.text !== ""
                                onClicked: {
                                    if (addPlaylistDialog.isEdit) {
                                        playlistManager.editPlaylist(addPlaylistDialog.editIndex, nameInput.text, sourceInput.text)
                                    } else {
                                        playlistManager.addPlaylist(nameInput.text, sourceInput.text)
                                    }
                                    addPlaylistDialog.close()
                                }
                            }
                        }
                    }
                }


                // Delete Confirmation Dialog
                Dialog {
                    id: deleteConfirmationDialog
                    title: "Tasdiqlash (Confirm Deletion)"
                    anchors.centerIn: parent
                    width: 350
                    height: 150
                    
                    property int deleteIndex: -1
                    
                    background: Rectangle {
                        color: "#2b2b2b"
                        border.color: "#444"
                        radius: 5
                    }
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15
                        
                        Text {
                            text: "Siz haqiqatdan ham ushbu pleylistni o'chirmoqchimisiz? (Ar you sure you want to delete this playlist?)"
                            color: "white"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                             Layout.fillWidth: true
                             Layout.alignment: Qt.AlignRight
                             spacing: 15
                             
                             Button {
                                 text: "Yo'q (No)"
                                 onClicked: deleteConfirmationDialog.close()
                             }
                             
                             Button {
                                 text: "Ha (Yes)"
                                 highlighted: true
                                 
                                 background: Rectangle {
                                     color: parent.down ? "#ba0000" : "#d00000"
                                     radius: 3
                                 }
                                 palette.buttonText: "white"
                                 
                                 onClicked: {
                                     if (deleteConfirmationDialog.deleteIndex !== -1) {
                                         playlistManager.removePlaylist(deleteConfirmationDialog.deleteIndex)
                                     }
                                     deleteConfirmationDialog.close()
                                 }
                             }
                        }
                    }
                }
            }
        }
        Component {
            id: categoryParams
            
            Rectangle {
                color: "#2b2b2b"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        
                        Button {
                            icon.source: "icons/back.svg"
                            icon.color: "white"
                            display: AbstractButton.IconOnly
                            background: Item {} // Transparent background
                            
                            onClicked: stackView.pop()
                        }
                        
                        Text {
                            text: "Kategoriyalar (Categories)"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 20
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        // Spacer to balance the back button
                        Item { width: 40; height: 1 }
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
                    visible: !isMinimalView
                    
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
                            visible: mainWindow.sidebarVisible && !mainWindow.isMinimalView

                            ListView {
                                id: channelListView
                                anchors.fill: parent
                                model: playlistModel
                                clip: true

                                delegate: ItemDelegate {
                                    width: ListView.view.width
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
                                    property string dragMode: "" // "volume", "channel", "window", "channelList"
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
                                        // 3. Channel list is showing (keep it visible)
                                        if (isDoubleClick || (deltaX < 10 && deltaY < 10)) {
                                            // Reset states and return - this was a click, not a drag
                                            // But keep channel list visible if it was opened
                                            if (dragMode !== "channelList") {
                                                isVolumeDrag = false
                                                isChannelDrag = false
                                                isWindowMove = false
                                                dragMode = ""
                                                volumeOverlay.visible = false
                                                lastSwitchedIndex = -1
                                            }
                                            return
                                        }
                                        
                                        // If channel list was opened, keep it visible (don't close on release)
                                        if (dragMode === "channelList") {
                                            // Keep channelsListOverlay visible
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
                                        
                                        // Reset all states (except channel list)
                                        if (dragMode !== "channelList") {
                                            isVolumeDrag = false
                                            isChannelDrag = false
                                            isWindowMove = false
                                            dragMode = ""
                                            volumeOverlay.visible = false
                                            lastSwitchedIndex = -1
                                        }
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
                                            // Priority 1: Fullscreen + top 20% + horizontal = window move
                                            if (isMinimalView && startY < height * 0.2) {
                                                if (totalDeltaX > 30 && totalDeltaX > totalDeltaY * 1.2) {
                                                    dragMode = "window"
                                                    isWindowMove = true
                                                    mainWindow.startSystemMove()
                                                    return // Window move started, exit
                                                }
                                            }
                                            
                                            // Priority 2: Center area (30-70% width) + downward drag = channel list
                                            if (startX > width * 0.3 && startX < width * 0.7 && 
                                                totalDeltaY > 30 && totalDeltaY > totalDeltaX) {
                                                dragMode = "channelList"
                                                channelsListOverlay.visible = true
                                            }
                                            // Priority 3: Right side 30% + vertical drag = volume control
                                            else if (startX > width * 0.7 && totalDeltaY > 15 && totalDeltaY > totalDeltaX) {
                                                dragMode = "volume"
                                                isVolumeDrag = true
                                                volumeOverlay.visible = true
                                                lastY = startY // Reset for accurate volume calculation
                                            }
                                            // Priority 4: Horizontal drag (not top 20% in fullscreen, not right 30% for volume, not center for list) = channel switch
                                            else if (!(isMinimalView && startY < height * 0.2) && 
                                                     !(startX > width * 0.7) &&
                                                     !(startX > width * 0.3 && startX < width * 0.7) &&
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
                                        
                                        // Handle volume control (only if volume mode is active and in right 30%)
                                        if (dragMode === "volume" && isVolumeDrag && startX > width * 0.7) {
                                            var delta = lastY - mouse.y
                                            var change = delta / height * 2.0
                                            
                                            var newVol = player.audioOutput.volume + change
                                            if (newVol > 1.0) newVol = 1.0
                                            if (newVol < 0.0) newVol = 0.0
                                            
                                            volumeSlider.value = newVol
                                            
                                            lastY = mouse.y
                                        }
                                        
                                        // Note: Channel switching happens only once when dragMode is set to "channel"
                                        // No continuous channel switching during drag
                                    }
                                    
                                    onDoubleClicked: {
                                        isDoubleClick = true // Set flag to prevent channel switching
                                        isFramelessMode = !isFramelessMode
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
                                
                                // Channels List Overlay (shown when dragging down from center)
                                Rectangle {
                                    id: channelsListOverlay
                                    anchors.fill: parent
                                    color: "#ee000000" // Semi-transparent black background
                                    visible: false
                                    z: 100 // Above video but below other overlays
                                    
                                    // Close on click outside the list
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: channelsListOverlay.visible = false
                                    }
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width * 0.8, 600)
                                        height: Math.min(parent.height * 0.7, 500)
                                        color: "#2b2b2b"
                                        radius: 10
                                        border.color: "#444"
                                        border.width: 2
                                        
                                        // Prevent clicks inside the list from closing the overlay
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {} // Do nothing, just prevent event propagation
                                        }
                                        
                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 20
                                            
                                            Text {
                                                text: "Kanallar ro'yxati (Channels List)"
                                                color: "white"
                                                font.bold: true
                                                font.pixelSize: 20
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.bottomMargin: 10
                                            }
                                            
                                            ScrollView {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                
                                                ListView {
                                                    id: channelsOverlayListView
                                                    model: playlistModel
                                                    clip: true
                                                    
                                                    delegate: ItemDelegate {
                                                        width: channelsOverlayListView.width
                                                        height: 50
                                                        
                                                        Rectangle {
                                                            anchors.fill: parent
                                                            color: parent.highlighted ? "#0078d7" : (index % 2 === 0 ? "#333333" : "#2b2b2b")
                                                            
                                                            Text {
                                                                anchors.left: parent.left
                                                                anchors.leftMargin: 15
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: model.name
                                                                color: "white"
                                                                font.pixelSize: 16
                                                                elide: Text.ElideRight
                                                                width: parent.width - 30
                                                            }
                                                        }
                                                        
                                                        highlighted: ListView.isCurrentItem || channelListView.currentIndex === index
                                                        
                                                        onClicked: {
                                                            channelsOverlayListView.currentIndex = index
                                                            channelListView.currentIndex = index
                                                            var channelUrl = playlistModel.getChannelUrl(index)
                                                            if (channelUrl.toString() !== "") {
                                                                player.source = channelUrl
                                                                player.play()
                                                                channelOverlay.showChannel(index)
                                                                channelsListOverlay.visible = false
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Button {
                                                text: "Yopish (Close)"
                                                Layout.fillWidth: true
                                                onClicked: channelsListOverlay.visible = false
                                            }
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
                        visible: !isMinimalView

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
    // Only active when isMinimalView is true (Frameless or Fullscreen)
    // Note: In Window.FullScreen, these might not be needed or might act weird, but it's safe to have them if the OS allows resizing 
    // (though usually Fullscreen is fixed).
    
    // Right Edge
    MouseArea {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 10
        cursorShape: Qt.SizeHorCursor
        enabled: isMinimalView
        visible: isMinimalView
        onPressed: {
            mainWindow.startSystemResize(Qt.RightEdge)
        }
    }

    // Left Edge
    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: 10
        cursorShape: Qt.SizeHorCursor
        enabled: isMinimalView
        visible: isMinimalView
        onPressed: {
            mainWindow.startSystemResize(Qt.LeftEdge)
        }
    }

    // Bottom Edge
    MouseArea {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 10
        cursorShape: Qt.SizeVerCursor
        enabled: isMinimalView
        visible: isMinimalView
        onPressed: {
            mainWindow.startSystemResize(Qt.BottomEdge)
        }
    }

    // Top Edge
    MouseArea {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 10
        cursorShape: Qt.SizeVerCursor
        enabled: isMinimalView
        visible: isMinimalView
        onPressed: {
            mainWindow.startSystemResize(Qt.TopEdge)
        }
    }

    // Bottom-Right Corner
    MouseArea {
        anchors { right: parent.right; bottom: parent.bottom }
        width: 20; height: 20
        cursorShape: Qt.SizeFDiagCursor
        enabled: isMinimalView
        visible: isMinimalView
        onPressed: {
            mainWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
        }
    }
}
