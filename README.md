# IPTV Player

A modern, cross-platform IPTV (Internet Protocol Television) player built with Qt 6 and QML. This application provides a user-friendly interface for watching IPTV channels from M3U/M3U8 playlist files.

![Qt Version](https://img.shields.io/badge/Qt-6.8-blue.svg)
![License](https://img.shields.io/badge/license-Open%20Source-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)

## Features

### Core Functionality

- 📺 **Playlist Support**: Load and play channels from M3U/M3U8 playlist files
- 📂 **Category Organization**: Automatically organizes channels by categories (groups)
- 🔍 **Search Functionality**: Search channels by name within selected categories
- ▶️ **Video Playback**: High-quality video playback with Qt Multimedia

### User Interface

- 🎨 **Modern Dark Theme**: Clean and modern dark-themed interface
- 📱 **Responsive Layout**: Adjustable sidebar and video player split view
- 🔲 **Fullscreen Mode**: Immersive fullscreen viewing experience with frameless window
- 📌 **Window Pinning**: Keep the player window on top of other applications
- 👁️ **Sidebar Toggle**: Show or hide the channel list sidebar

### Video Controls

- ⏯️ **Play/Pause**: Standard playback controls
- ⏹️ **Stop**: Stop video playback
- 🔊 **Volume Control**: Adjustable volume slider and mouse drag control on video
- 🖱️ **Mouse Gestures**:
  - Double-click video to toggle fullscreen
  - Drag on video (right side in fullscreen, anywhere in windowed mode) to adjust volume
  - Drag on left side of video in fullscreen to move window

### Window Management

- 🔲 **Frameless Fullscreen**: True frameless fullscreen mode with resizing handles
- 🔄 **Window Resizing**: Resize the window from edges and corners in fullscreen mode
- 🪟 **System Integration**: Native window controls and behaviors

## Requirements

### Build Requirements

- **CMake** 3.16 or higher
- **Qt 6.8** or higher with the following components:
  - Qt Quick
  - Qt Multimedia
  - Qt Network

### Runtime Requirements

- Operating System: Windows, Linux, or macOS
- Qt 6 runtime libraries
- Video codecs supported by Qt Multimedia

## Building from Source

### Prerequisites

1. Install Qt 6.8+ from [qt.io](https://www.qt.io/download)
2. Install CMake 3.16+
3. Ensure Qt is in your PATH or set `CMAKE_PREFIX_PATH`

### Build Instructions

#### Windows

```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

#### Linux

```bash
mkdir build
cd build
cmake ..
make -j$(nproc)
```

#### macOS

```bash
mkdir build
cd build
cmake ..
make -j$(sysctl -n hw.ncpu)
```

The executable will be in the `build` directory (or `build/Release` on Windows).

## Usage

### Loading a Playlist

1. Launch the application
2. Click **"Pleylistni Ochish"** (Open Playlist) button on the main screen
3. Select an M3U or M3U8 playlist file
4. The application will parse and organize channels by categories

### Watching Channels

1. **Select a Category**: Click on a category from the list to view its channels
2. **Search Channels**: Use the search box to filter channels by name
3. **Play a Channel**: Click on any channel name to start playback
4. **Control Playback**: Use the bottom control bar for play/pause/stop
5. **Adjust Volume**:
   - Use the volume slider at the bottom
   - Or drag your mouse up/down on the video area

### Fullscreen Mode

- **Enter Fullscreen**: Double-click on the video area
- **Exit Fullscreen**: Double-click again, or press Escape (if available)
- **Move Window**: Drag from the left side of the video in fullscreen mode
- **Resize Window**: Drag from window edges or corners in fullscreen mode

### Additional Features

- **Pin Window**: Click the pin icon to keep the window on top
- **Toggle Sidebar**: Click the menu icon to show/hide the channel list

## Playlist Format

The application supports standard M3U/M3U8 playlist formats with the following tags:

- `#EXTINF`: Channel information line containing channel name and metadata
- `#EXTGRP:`: Category/group assignment (alternative to `group-title` attribute)
- `group-title="..."`: Category/group assignment within EXTINF line
- URL lines: Direct video stream URLs

### Example Playlist Entry

```
#EXTINF:0 tvg-rec="0",Channel Name
#EXTGRP:Entertainment
http://example.com/stream.m3u8
```

If `group-title` is not specified, channels will be grouped under "Boshqa (Others)".

## Project Structure

```
iptv_player/
├── CMakeLists.txt          # CMake build configuration
├── main.cpp                # Application entry point
├── Main.qml                # Main QML UI file
├── playlistmodel.h         # Playlist model header
├── playlistmodel.cpp       # Playlist model implementation
├── icons/                  # SVG icons for UI controls
│   ├── back.svg
│   ├── menu.svg
│   ├── pause.svg
│   ├── pin.svg
│   ├── play.svg
│   ├── stop.svg
│   └── unpin.svg
├── test_playlist.m3u       # Example playlist file
└── README.md               # This file
```

## Architecture

### Components

- **PlaylistModel**: C++ model class that manages playlist data, category filtering, and channel search
- **Main.qml**: QML interface with StackView navigation, video player, and controls
- **MediaPlayer**: Qt Multimedia component for video playback
- **VideoOutput**: Qt Multimedia component for video rendering

### Design Patterns

- **Model-View Architecture**: Uses QAbstractListModel for efficient data management
- **Component-based UI**: Modular QML components for maintainability
- **Signal-Slot Communication**: Qt's signal-slot mechanism for component interaction

## Contributing

This is an open-source project. Contributions are welcome! Please feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## License

This project is open source. Please refer to the license file for details.

## Acknowledgments

- Built with [Qt Framework](https://www.qt.io/)
- Uses Qt Multimedia for video playback
- SVG icons for UI elements

## Troubleshooting

### Playlist Won't Load

- Ensure the playlist file is in valid M3U/M3U8 format
- Check file path permissions
- Verify the playlist file encoding (UTF-8 recommended)

### Video Won't Play

- Check that the stream URL is accessible
- Verify your network connection
- Ensure Qt Multimedia supports the video codec
- Check system audio/video drivers

### Build Errors

- Verify Qt 6.8+ is installed and detected by CMake
- Ensure all required Qt components (Quick, Multimedia, Network) are available
- Check CMake version (3.16+ required)

## Future Enhancements

Potential features for future releases:

- EPG (Electronic Program Guide) support
- Recording functionality
- Favorites/bookmarks system
- Multiple playlist support
- Keyboard shortcuts
- Playlist editor
- Channel logos support
- Subtitle support

---

**Note**: The application interface is currently in Uzbek language, but the codebase is well-documented and can be localized easily.
