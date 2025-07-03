import Quickshell
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
    
    // Convenience aliases
    property alias themeService: themeServiceLoader.item
    property alias configService: configServiceLoader.item
    property alias hyprlandService: hyprlandServiceLoader.item
    property alias windowStore: windowStoreLoader.item
    property alias workspaceStore: workspaceStoreLoader.item
    property alias systemMonitorService: systemMonitorServiceLoader.item
    
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
                themeServiceLoader.item.currentThemeData !== null
        
        onLoaded: {
            console.log("Main bar loaded")
            
            // Pass primary screen and services to the loaded component
            item.modelData = Quickshell.screens[0] || null
            item.themeService = themeServiceLoader.item
            item.configService = configServiceLoader.item
            item.systemMonitorService = systemMonitorServiceLoader.item
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
        globalThemeDropdownLoader.active = true
    }
    
    Component.onCompleted: {
        console.log(logCategory, "Quickshell Hyprland Interface - Initialization Complete")
        console.log(logCategory, "Architecture: Modern QML with Separation of Concerns")
    }
}