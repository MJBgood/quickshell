import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtCore

ShellRoot {
    id: root
    
    // Logging category for shell operations
    LoggingCategory {
        id: logCategory
        name: "quickshell.shell"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Initialize core services using loaders
    Loader {
        id: themeServiceLoader
        source: "./services/ThemeService.qml"
        onLoaded: {
            // Connect the config service
            item.configService = configServiceLoader.item
        }
    }
    
    Loader {
        id: configServiceLoader  
        source: "./services/ConfigService.qml"
    }
    
    Loader {
        id: hyprlandServiceLoader
        source: "./services/HyprlandService.qml"
        onLoaded: {
            console.log("HyprlandService loaded successfully")
            console.log("HyprlandService initialized:", item.initialized)
            console.log("HyprlandService connected:", item.isConnected)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load HyprlandService:", sourceComponent.errorString)
            }
        }
    }
    
    // Initialize stores using loaders
    Loader {
        id: windowStoreLoader
        source: "./stores/WindowStore.qml"
    }
    
    Loader {
        id: workspaceStoreLoader
        source: "./stores/WorkspaceStore.qml"
    }
    
    Loader {
        id: systemMonitorServiceLoader
        source: "./services/SystemMonitorService.qml"
        onLoaded: {
            console.log("SystemMonitorService loaded successfully")
            console.log("SystemMonitorService initialized:", item.initialized)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load SystemMonitorService:", sourceComponent.errorString)
            }
        }
    }
    
    Loader {
        id: windowTrackerLoader
        source: "./services/HyprlandWindowTracker.qml"
        onLoaded: {
            console.log("HyprlandWindowTracker loaded successfully")
            console.log("WindowTracker initialized:", item.initialized)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load HyprlandWindowTracker:", sourceComponent.errorString)
            }
        }
    }
    
    Loader {
        id: iconResolverLoader
        source: "./services/ApplicationIconResolver.qml"
        onLoaded: {
            console.log("ApplicationIconResolver loaded successfully")
            console.log("IconResolver initialized:", item.initialized)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load ApplicationIconResolver:", sourceComponent.errorString)
            }
        }
    }
    
    // Convenience aliases
    property alias themeService: themeServiceLoader.item
    property alias configService: configServiceLoader.item
    property alias hyprlandService: hyprlandServiceLoader.item
    property alias windowStore: windowStoreLoader.item
    property alias workspaceStore: workspaceStoreLoader.item
    property alias systemMonitorService: systemMonitorServiceLoader.item
    property alias windowTracker: windowTrackerLoader.item
    property alias iconResolver: iconResolverLoader.item
    
    // Global function to show settings overlay
    function showSettings(anchorWindow, anchorRect) {
        settingsOverlayLoader.active = true
        if (settingsOverlayLoader.item) {
            settingsOverlayLoader.item.show(anchorWindow, anchorRect)
        }
    }
    
    // Global function to toggle settings overlay
    function toggleSettings(anchorWindow, anchorRect) {
        if (settingsOverlayLoader.active && settingsOverlayLoader.item && settingsOverlayLoader.item.visible) {
            settingsOverlayLoader.item.hide()
        } else {
            showSettings(anchorWindow, anchorRect)
        }
    }
    
    // Main UI components - Single bar for primary screen
    Loader {
        id: mainBarLoader
        source: "./components/bars/Bar.qml"
        
        // Only load when all services are initialized AND theme is loaded
        active: themeServiceLoader.item && 
                configServiceLoader.item && 
                hyprlandServiceLoader.item &&
                systemMonitorServiceLoader.item &&
                windowTrackerLoader.item &&
                iconResolverLoader.item &&
                themeServiceLoader.item.currentThemeData !== null
        
        onLoaded: {
            console.log("Main bar loaded")
            
            // Pass primary screen and services to the loaded component
            item.modelData = Quickshell.screens[0] || null
            item.themeService = themeServiceLoader.item
            item.configService = configServiceLoader.item
            item.systemMonitorService = systemMonitorServiceLoader.item
            item.windowTracker = windowTrackerLoader.item
            item.iconResolver = iconResolverLoader.item
            item.sessionOverlay = sessionWindow.sessionOverlay  // Pass session overlay
            item.shellRoot = root  // Pass reference to shell for global functions
            
            console.log("Services passed to main bar")
        }
        
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load main bar")
            }
        }
    }
    
    // Settings Overlay - Lazy loaded only when needed
    Loader {
        id: settingsOverlayLoader
        source: "./components/overlays/SettingsOverlay.qml"
        active: false  // Only load when settings is requested
        
        onLoaded: {
            console.log("SettingsOverlay loaded on demand")
            item.themeService = themeServiceLoader.item
            item.configService = configServiceLoader.item
            item.shellRoot = root
            
            // Auto-hide when closed
            item.closed.connect(function() {
                settingsOverlayLoader.active = false
            })
        }
    }
    
    // Session Overlay - For power menu (dedicated window like temp-repos)
    PanelWindow {
        id: sessionWindow
        
        property var sessionOverlay: sessionOverlayLoader.item
        
        screen: Quickshell.screens[0]
        color: "transparent"
        visible: sessionOverlayLoader.item ? sessionOverlayLoader.item.sessionVisible : false
        
        anchors {
            top: true
            bottom: true
            left: true
        }
        
        implicitWidth: sessionOverlayLoader.item ? sessionOverlayLoader.item.implicitWidth : 0
        
        // Focus grab for click-outside-to-close (CRITICAL)
        HyprlandFocusGrab {
            id: sessionFocusGrab
            active: sessionOverlayLoader.item ? sessionOverlayLoader.item.sessionVisible : false
            windows: [sessionWindow]
            onCleared: {
                if (sessionOverlayLoader.item) {
                    sessionOverlayLoader.item.sessionVisible = false
                }
            }
        }
        
        // Semi-transparent background when session is visible
        Rectangle {
            anchors.fill: parent
            color: "#80000000"  // Semi-transparent black
            opacity: sessionOverlayLoader.item && sessionOverlayLoader.item.sessionVisible ? 0.5 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (sessionOverlayLoader.item) {
                        sessionOverlayLoader.item.sessionVisible = false
                    }
                }
            }
        }
        
        Loader {
            id: sessionOverlayLoader
            source: "./components/overlays/SessionOverlay.qml"
            active: true
            
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            
            onLoaded: {
                console.log("SessionOverlay loaded")
                item.themeService = themeServiceLoader.item
                item.configService = configServiceLoader.item
            }
            
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load SessionOverlay:", sourceComponent.errorString)
                }
            }
        }
    }
    
    // Theme Dropdown - Global overlay
    Loader {
        id: globalThemeDropdownLoader
        source: "./components/overlays/ThemeDropdown.qml"
        active: false
        
        onLoaded: {
            console.log(logCategory, "Global ThemeDropdown loaded")
            item.themeService = themeServiceLoader.item
            item.configService = configServiceLoader.item
            
            // Auto-hide when closed
            item.closed.connect(function() {
                console.log(logCategory, "Global ThemeDropdown closed")
                globalThemeDropdownLoader.active = false
            })
            
            // Show immediately after loading
            item.show(mainBarLoader.item)
        }
        
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error(logCategory, "Failed to load global ThemeDropdown:", sourceComponent.errorString)
            }
        }
    }
    
    // Global function to show theme dropdown
    function showThemeDropdown() {
        console.log(logCategory, "showThemeDropdown() called")
        
        // Ensure themes are loaded before showing dropdown
        if (themeServiceLoader.item) {
            themeServiceLoader.item.loadAllThemes()
        }
        
        globalThemeDropdownLoader.active = true
    }
    
    Component.onCompleted: {
        console.log(logCategory, "Quickshell Hyprland Interface - Initialization Complete")
        console.log(logCategory, "Architecture: Modern QML with Separation of Concerns")
    }
}