import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtCore
import "./services"

ShellRoot {
    id: root
    
    // Logging category for shell operations
    LoggingCategory {
        id: logCategory
        name: "quickshell.shell"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Initialize core services using loaders
    // ConfigService is now a singleton - no loader needed
    // DisplayScalingService is a singleton - trigger initialization
    property var displayScalingService: DisplayScalingService
    
    // Initialize mouse interaction and border services
    property var mouseInteractionService: MouseInteractionService
    property var borderOverlayService: BorderOverlayService
    
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
            // Connect config service directly
            console.log("Connecting ConfigService to SystemMonitorService")
            item.configService = ConfigService
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
    
    Loader {
        id: wallpaperServiceLoader
        source: "./services/WallpaperService.qml"
        onLoaded: {
            console.log("WallpaperService loaded successfully")
            console.log("WallpaperService initialized:", item.initialized)
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load WallpaperService:", sourceComponent.errorString)
            }
        }
    }
    
    Loader {
        id: widgetRegistryLoader
        source: "./services/WidgetRegistry.qml"
        onLoaded: {
            console.log("WidgetRegistry loaded successfully")
            console.log("WidgetRegistry initialized:", item.initialized)
            // Connect config service to widget registry
            Qt.callLater(() => {
                // ConfigService is now a singleton - directly accessible
                item.configService = ConfigService
            })
        }
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load WidgetRegistry:", sourceComponent.errorString)
            }
        }
    }
    
    
    // Convenience aliases
    // themeService removed - theme functionality integrated into configService
    property var configService: ConfigService
    property alias hyprlandService: hyprlandServiceLoader.item
    property alias windowStore: windowStoreLoader.item
    property alias workspaceStore: workspaceStoreLoader.item
    property alias systemMonitorService: systemMonitorServiceLoader.item
    property alias windowTracker: windowTrackerLoader.item
    property alias iconResolver: iconResolverLoader.item
    property alias wallpaperService: wallpaperServiceLoader.item
    property alias widgetRegistry: widgetRegistryLoader.item
    
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
    
    // Wallpaper service handles wallpapers via Hyprland native functionality
    // No custom background windows needed
    
    // Main UI components - Single bar for primary screen
    Loader {
        id: mainBarLoader
        source: "./components/bars/Bar.qml"
        
        // Only load when all services are initialized AND theme is loaded
        active: ConfigService && 
                hyprlandServiceLoader.item &&
                systemMonitorServiceLoader.item &&
                windowTrackerLoader.item &&
                iconResolverLoader.item &&
                wallpaperServiceLoader.item &&
                widgetRegistryLoader.item &&
                ConfigService.currentThemeData !== null
        
        onLoaded: {
            console.log("Main bar loaded")
            
            // Pass primary screen and services to the loaded component
            item.modelData = Quickshell.screens[0] || null
            // themeService removed - theme functionality integrated into configService
            item.configService = ConfigService
            item.systemMonitorService = systemMonitorServiceLoader.item
            item.windowTracker = windowTrackerLoader.item
            item.iconResolver = iconResolverLoader.item
            item.sessionOverlay = sessionWindow.sessionOverlay  // Pass session overlay
            item.shellRoot = root  // Pass reference to shell for global functions
            item.wallpaperService = wallpaperServiceLoader.item
            item.widgetRegistry = widgetRegistryLoader.item
            
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
            // themeService removed - theme functionality integrated into configService
            item.configService = ConfigService
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
        
        implicitWidth: (sessionOverlayLoader.item && sessionOverlayLoader.item.sessionVisible) ? sessionOverlayLoader.item.implicitWidth : 0
        
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
                // themeService removed - theme functionality integrated into configService
                item.configService = ConfigService
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
            // themeService removed - theme functionality integrated into configService
            item.configService = ConfigService
            
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
    
    // Wallpaper Selector - Global overlay (same pattern as theme dropdown)
    Loader {
        id: globalWallpaperSelectorLoader
        source: "./components/widgets/WallpaperSelector.qml"
        active: false
        
        onLoaded: {
            console.log(logCategory, "Global WallpaperSelector loaded")
            item.wallpaperService = wallpaperServiceLoader.item
            item.configService = ConfigService
            
            // Auto-hide when closed
            item.closed.connect(function() {
                console.log(logCategory, "Global WallpaperSelector closed")
                globalWallpaperSelectorLoader.active = false
            })
            
            // Show immediately after loading with main bar as anchor
            item.show(mainBarLoader.item)
        }
        
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error(logCategory, "Failed to load global WallpaperSelector:", sourceComponent.errorString)
            }
        }
    }

    // Global function to show theme dropdown
    function showThemeDropdown() {
        console.log(logCategory, "showThemeDropdown() called")
        
        // Theme functionality now integrated into ConfigService
        // (Theme loading happens automatically in ConfigService)
        
        globalThemeDropdownLoader.active = true
    }

    // Global function to show wallpaper selector
    function showWallpaperSelector() {
        console.log(logCategory, "showWallpaperSelector() called")
        console.log(logCategory, "globalWallpaperSelectorLoader.active:", globalWallpaperSelectorLoader.active)
        console.log(logCategory, "wallpaperServiceLoader.item:", wallpaperServiceLoader.item)
        
        // Ensure wallpapers are loaded before showing selector
        if (wallpaperServiceLoader.item) {
            wallpaperServiceLoader.item.discoverWallpapers()
        }
        
        console.log(logCategory, "Setting globalWallpaperSelectorLoader.active = true")
        globalWallpaperSelectorLoader.active = true
        console.log(logCategory, "globalWallpaperSelectorLoader.active after:", globalWallpaperSelectorLoader.active)
    }

    // Scaling Menu - Global overlay (same pattern as theme dropdown and wallpaper selector)
    Loader {
        id: globalScalingMenuLoader
        source: "./components/overlays/ScalingContextMenu.qml"
        active: false
        
        onLoaded: {
            console.log(logCategory, "Global ScalingContextMenu loaded")
            item.configService = ConfigService
            
            // Auto-hide when closed
            item.closed.connect(function() {
                console.log(logCategory, "Global ScalingContextMenu closed")
                globalScalingMenuLoader.active = false
            })
            
            // Show immediately after loading with main bar as anchor
            item.show(mainBarLoader.item)
        }
        
        onStatusChanged: {
            if (status === Loader.Error) {
                console.error(logCategory, "Failed to load global ScalingContextMenu:", sourceComponent.errorString)
            }
        }
    }

    // Global function to show scaling menu
    function showScalingMenu() {
        console.log(logCategory, "showScalingMenu() called")
        globalScalingMenuLoader.active = true
    }
    
    // Screen border visual only
    PanelWindow {
        id: borderWindow
        screen: Quickshell.screens[0]
        color: "transparent"
        visible: true
        
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        
        // Use Wayland layer shell properties for proper behavior
        WlrLayershell.exclusionMode: ExclusionMode.Ignore  // Don't reserve space
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // Don't steal keyboard focus
        WlrLayershell.layer: WlrLayer.Bottom  // Below other windows
        
        // Screen border visual
        Loader {
            id: screenBorderLoader
            source: "./components/overlays/ScreenBorder.qml"
            active: true
            anchors.fill: parent
            
            onLoaded: {
                console.log("ScreenBorder loaded")
                item.configService = ConfigService
                item.borderOverlayService = borderOverlayService
            }
        }
    }
    
    
    // Mouse interaction window (caelestia pattern - no click blocking)
    PanelWindow {
        id: mouseInteractionWindow
        screen: Quickshell.screens[0]
        color: "transparent"
        visible: true
        
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Top
        
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        
        // Mouse detection that doesn't block clicks
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton // CRITICAL: Don't block clicks!
            hoverEnabled: true
            
            onPositionChanged: mouse => {
                if (mouseInteractionService) {
                    mouseInteractionService.updateMousePosition(mouse.x, mouse.y)
                }
            }
        }
    }
    
    // Dashboard overlay window - separate from mouse detection
    PanelWindow {
        id: dashboardWindow
        screen: Quickshell.screens[0]
        color: "transparent"
        visible: dashboardState.visible
        
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell-dashboard"
        
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        
        // Dashboard state
        PersistentProperties {
            id: dashboardState
            property bool visible: false
        }
        
        // Dashboard wrapper with height animation (like caelestia)
        Item {
            id: dashboardWrapper
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8 // Border thickness offset
            
            width: 600
            implicitHeight: 0 // Start collapsed
            
            // Height animation states (caelestia pattern)
            states: State {
                name: "visible"
                when: dashboardState.visible
                PropertyChanges {
                    dashboardWrapper.implicitHeight: dashboardContent.implicitHeight
                }
            }
            
            // Caelestia-style transitions with custom curves
            transitions: [
                Transition {
                    from: ""
                    to: "visible"
                    NumberAnimation {
                        target: dashboardWrapper
                        property: "implicitHeight"
                        duration: 500 // expressiveDefaultSpatial timing
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1] // Caelestia's expressive curve
                    }
                },
                Transition {
                    from: "visible"
                    to: ""
                    NumberAnimation {
                        target: dashboardWrapper
                        property: "implicitHeight"
                        duration: 400 // normal timing
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1] // Emphasized curve
                    }
                }
            ]
            
            // Background shape that integrates with border
            Rectangle {
                id: dashboardBackground
                anchors.fill: parent
                anchors.topMargin: -8 // Merge with border
                color: ConfigService.getThemeProperty("colors", "surface") || "#313244"
                radius: 25 // Match border rounding
                
                // Only visible when wrapper has height
                opacity: dashboardWrapper.implicitHeight > 0 ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
            
            // Dashboard content
            Loader {
                id: dashboardContent
                source: "./components/overlays/TopCenterMenu.qml"
                active: true // Always active for height calculation
                
                anchors.fill: parent
                anchors.margins: 16
                
                // Only show when animating or visible
                opacity: dashboardWrapper.implicitHeight > 0 ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                
                onLoaded: {
                    console.log("TopCenterMenu loaded with caelestia-style animation")
                    item.configService = ConfigService
                }
                
                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.error("Failed to load TopCenterMenu:", sourceComponent.errorString)
                    }
                }
            }
        }
    }
    
    // Mouse interaction detection window (Caelestia pattern)
    PanelWindow {
        id: mouseInteractionWindow
        screen: Quickshell.screens[0]
        color: "transparent"
        visible: true
        
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Top // Above other windows but below overlays
        WlrLayershell.namespace: "quickshell-interactions"
        
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        
        // Caelestia-style mouse interaction detection
        MouseArea {
            id: globalMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton // Don't block any clicks!
            
            onContainsMouseChanged: {
                if (!containsMouse) {
                    // Hide dashboard when mouse leaves screen area
                    if (!dashboardState.visible) return
                    
                    // Only hide if not in shortcut mode
                    if (!mouseInteractionService.shortcutModeActive) {
                        dashboardState.visible = false
                    }
                }
            }
            
            onPositionChanged: mouse => {
                // Update mouse position in service
                if (mouseInteractionService) {
                    mouseInteractionService.updateMousePosition(mouse.x, mouse.y)
                }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("ConfigService loaded successfully")
        
        // Initialize NotificationPopupManager with shell services
        NotificationPopupManager.initialize(ConfigService, mainBarLoader.item)
        
        // Initialize mouse interaction and border services
        if (mouseInteractionService) {
            mouseInteractionService.bindConfigService(ConfigService)
            mouseInteractionService.updateScreenDimensions(
                borderWindow.screen ? borderWindow.screen.width : 1920,
                borderWindow.screen ? borderWindow.screen.height : 1080,
                borderWindow
            )
            
            // Connect dashboard toggle signal
            mouseInteractionService.dashboardToggled.connect(function() {
                dashboardState.visible = mouseInteractionService.topCenterMenuVisible
                console.log("Dashboard state set to:", dashboardState.visible)
            })
        }
        
        if (borderOverlayService) {
            borderOverlayService.bindConfigService(ConfigService)
            borderOverlayService.updateScreenDimensions(
                borderWindow.screen ? borderWindow.screen.width : 1920,
                borderWindow.screen ? borderWindow.screen.height : 1080,
                borderWindow
            )
            
            // Update bar width when main bar is loaded
            Qt.callLater(() => {
                if (mainBarLoader.item) {
                    borderOverlayService.updateBarWidth(mainBarLoader.item.implicitWidth || 0)
                }
            })
        }
        
        // Connect to SystemMonitorService when it's ready
        Qt.callLater(() => {
            if (systemMonitorServiceLoader.item) {
                console.log("Connecting ConfigService to SystemMonitorService")
                systemMonitorServiceLoader.item.configService = ConfigService
            }
        })
        
        console.log(logCategory, "Quickshell Hyprland Interface - Initialization Complete")
        console.log(logCategory, "Architecture: Modern QML with Separation of Concerns")
        console.log(logCategory, "Mouse Interaction and Border Overlay enabled")
    }
    
    // Global shortcut to test top center menu  
    GlobalShortcut {
        appid: "quickshell"
        name: "show-dashboard"
        description: "Show top center dashboard menu"
        
        onPressed: {
            console.log("[GlobalShortcut] Dashboard shortcut (Super+D) pressed!")
            if (mouseInteractionService) {
                console.log("[GlobalShortcut] Calling toggleTopCenterMenu")
                mouseInteractionService.toggleTopCenterMenu()
            } else {
                console.log("[GlobalShortcut] mouseInteractionService is null!")
            }
        }
    }
}