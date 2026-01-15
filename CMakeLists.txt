cmake_minimum_required(VERSION 3.16)

project(iptv_player VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Multimedia Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appiptv_player
    main.cpp
    playlistmodel.cpp
    playlistmodel.h
)

qt_add_qml_module(appiptv_player
    URI iptv_player
    QML_FILES
        Main.qml
        icons/play.svg
        icons/pause.svg
        icons/stop.svg
        icons/pin.svg
        icons/unpin.svg
        icons/menu.svg
        icons/back.svg
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appiptv_player PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appiptv_player
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appiptv_player
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appiptv_player
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
