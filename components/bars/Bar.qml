import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../widgets"
import "../base"
import "../../services"

PanelWindow {
    id: bar
    
    // Required property for screen assignment
    property var modelData
    
    // Access to services (passed from parent)
    property var configService: ConfigService
    property var systemMonitorService: null
    property var windowTracker: null
    property var iconResolver: null
    property var sessionOverlay: null
    property var shellRoot: null
    property var wallpaperService: null
    property var widgetRegistry: null
    
    // Entity ID for configuration
    property string entityId: "barWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "bar"
    property string parentComponentId: ""
    property var childComponentIds: ["cpu", "ram", "storage", "gpu", "clock", "workspaces"]
    property string menuPath: "bar"
    
    // Panel configuration - position determined by config
    property string position: configService ? configService.getValue("panel.position", "top") : "top"
    
    // Set screen from modelData (for multi-monitor support)
    screen: modelData
    
    anchors {
        top: position === "top"
        bottom: position === "bottom"
        left: true
        right: true
    }
    
    // Use global scaling service with proper fallback
    implicitHeight: {
        if (configService && typeof configService.scaled === 'function') {
            const scaledHeight = configService.scaled(32)
            return scaledHeight > 0 ? scaledHeight : 32
        }
        return 32
    }
    color: "transparent"
    
    // Content - Using absolute positioning for reliable layout
    Item {
        anchors.fill: parent
        anchors.margins: {
            const baseMargin = configService ? configService.spacing("md", entityId) : 8
            const parentHeight = parent.height || 0
            // Only apply margins if parent has sufficient height
            return parentHeight > baseMargin * 2 ? baseMargin : Math.max(0, parentHeight / 4)
        }
        
        // Left section - App launcher icon (clickable)
        Rectangle {
            id: leftSection
            // Dynamic sizing based on content like other widgets
            implicitWidth: gearIcon.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8)
            implicitHeight: gearIcon.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4)
            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: configService ? configService.borderRadius : 8
            border.width: 1
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            
            // App launcher icon
            Text {
                id: gearIcon
                anchors.centerIn: parent
                text: "⚙"  // Settings gear icon as placeholder
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.pixelSize: configService ? configService.typography(configService.getEntityProperty(entityId, "fontSize", "md"), entityId) : 14
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    if (bar.shellRoot) {
                        var anchorRect = {
                            x: leftSection.x,
                            y: leftSection.y,
                            width: leftSection.width,
                            height: leftSection.height
                        }
                        bar.shellRoot.toggleSettings(bar, anchorRect)
                    }
                }
                
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
        
        // Center section - Workspace indicator (left-aligned after launcher)
        Rectangle {
            id: centerSection
            // Dynamic sizing based on workspace content like other widgets
            implicitWidth: workspaceRow.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8)
            implicitHeight: workspaceRow.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4)
            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: configService ? configService.borderRadius : 8
            border.width: 1
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            
            // GraphicalComponent interface implementation
            property string componentId: "workspaces"
            property string parentComponentId: "bar"
            property var childComponentIds: []
            property string menuPath: "workspaces"
            
            anchors {
                left: leftSection.right
                leftMargin: configService ? configService.spacing("lg", entityId) : 12
                verticalCenter: parent.verticalCenter
            }
            
            Row {
                id: workspaceRow
                anchors.centerIn: parent
                
                // Reactive binding to config - updates automatically
                spacing: {
                    if (!configService) return 4
                    const spacingMode = configService.getValue("workspaces.workspaceSpacing", "normal")
                    return spacingMode === "tight" ? (configService ? configService.marginTiny() : 2) : 
                           spacingMode === "loose" ? (configService ? configService.spacing("md", entityId) : 8) : 
                           (configService ? configService.spacing("xs", entityId) : 4)
                }
                
                Repeater {
                    model: Hyprland.workspaces
                    
                    Rectangle {
                        // Entity ID for workspaces configuration
                        property string workspaceEntityId: "workspacesWidget"
                        
                        // Config-dependent properties - direct bindings like performance monitors
                        property string workspaceSizeMode: configService ? configService.getValue("workspaces.workspaceSize", "medium") : "medium"
                        property string workspaceRadiusMode: configService ? configService.getValue("workspaces.cornerRadius", "medium") : "medium"
                        property bool workspaceShowOnlyActive: configService ? configService.getValue("workspaces.showOnlyActive", false) : false
                        property bool workspaceAutoHideEmpty: configService ? configService.getValue("workspaces.autoHideEmpty", false) : false
                        
                        visible: {
                            if (!modelData) return false
                            
                            if (workspaceShowOnlyActive) {
                                // Only show the currently focused workspace
                                return modelData.focused
                            } else if (workspaceAutoHideEmpty) {
                                // In Hyprland, we should show workspaces that have content or are currently in use
                                // Since we can't easily detect window count, let's be less aggressive and show:
                                // 1. The focused workspace (obviously has focus)
                                // 2. Active workspaces (currently displayed on monitors)  
                                // 3. For now, show all workspaces since we can't reliably detect "empty"
                                // TODO: Implement proper window counting via Hyprland IPC
                                return true  // Temporarily disable auto-hide until we can detect window count
                            }
                            return true
                        }
                        
                        // Dynamic width based on content, with minimum based on size mode (scaled)
                        property var workspaceSize: configService ? configService.workspaceSize(workspaceSizeMode) : {width: 32, height: 24}
                        width: Math.max(contentRow.implicitWidth + (configService ? configService.widgetSpacing() : 4), workspaceSize.width)
                        height: workspaceSize.height
                        radius: workspaceRadiusMode === "none" ? 0 : 
                                workspaceRadiusMode === "small" ? (configService ? configService.scaled(2) : 2) : 
                                workspaceRadiusMode === "large" ? (configService ? configService.scaled(8) : 8) : 
                                (configService ? configService.borderRadius : 8)
                        
                        color: modelData && modelData.focused ? 
                               (configService ? configService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                               (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                        
                        // Hover effect with smooth transition
                        opacity: workspaceMouseArea.containsMouse ? 0.8 : 1.0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        // Content based on configuration
                        Item {
                            anchors.fill: parent
                            
                            // Window count notification badge
                            Rectangle {
                                id: windowCountBadge
                                
                                property int windowCount: {
                                    if (!windowTracker) return 0
                                    const workspaceId = modelData ? modelData.id : (index + 1)
                                    return windowTracker.getWindowCountForWorkspace(workspaceId)
                                }
                                
                                property bool showWindowCount: configService ? configService.getValue("workspaces.showWindowCount", false) : false
                                
                                visible: windowCount > 0 && showWindowCount
                                
                                // Position in bottom-right corner for more subtle appearance
                                anchors {
                                    bottom: parent.bottom
                                    right: parent.right
                                    bottomMargin: configService ? configService.scaled(-3) : -3
                                    rightMargin: configService ? configService.scaled(-3) : -3
                                }
                                
                                // Smaller badge - should never exceed workspace size
                                width: Math.max(windowCountText.implicitWidth + (configService ? configService.badgePadding() : 4), configService ? configService.badgeSize() : 14)
                                height: configService ? configService.badgeSize() : 14
                                radius: configService ? configService.badgeRadius() : 7
                                
                                // Subtle badge styling - using theme colors
                                color: configService ? configService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                                border.width: 1
                                border.color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                                
                                // Subtle shadow/glow effect
                                opacity: 0.9
                                
                                // Window count text
                                Text {
                                    id: windowCountText
                                    anchors.centerIn: parent
                                    text: windowCountBadge.windowCount.toString()
                                    color: configService ? configService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e"
                                    font.family: "Inter"
                                    font.pixelSize: configService ? configService.fontTiny() : 8
                                    font.weight: Font.Medium
                                }
                                
                                // Smooth appearance/disappearance
                                Behavior on opacity {
                                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }
                            }
                            
                            Row {
                                id: contentRow
                                anchors.centerIn: parent
                                spacing: configService ? configService.marginTiny() : 2
                                
                                // Workspace number/name
                                Text {
                                    id: workspaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    // Config-dependent properties for text display - direct bindings
                                    property bool workspaceShowNumbers: configService ? configService.getValue("workspaces.showNumbers", true) : true
                                    property bool workspaceShowNames: configService ? configService.getValue("workspaces.showNames", false) : false
                                    property bool workspaceShowWindowCount: configService ? configService.getValue("workspaces.showWindowCount", false) : false
                                    property bool workspaceShowApplicationIcons: configService ? configService.getValue("workspaces.showApplicationIcons", true) : true
                                    
                                    text: {
                                        let displayText = ""
                                        
                                        if (workspaceShowNames && modelData && modelData.name) {
                                            displayText = modelData.name
                                        } else if (workspaceShowNumbers) {
                                            displayText = modelData ? modelData.id : (index + 1)
                                        }
                                        
                                        // Window count is now displayed as a notification badge instead of in parentheses
                                        
                                        return displayText || "?"
                                    }
                                    
                                    color: modelData && modelData.focused ? 
                                           (configService ? configService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                                           (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                                    font.family: "Inter"
                                    font.pixelSize: configService ? configService.typography(configService.getEntityProperty(parent.parent.parent.workspaceEntityId, "fontSize", "xs"), parent.parent.parent.workspaceEntityId) : 10
                                    font.weight: modelData && modelData.focused ? Font.DemiBold : Font.Medium
                                }
                                
                                // Application icons row
                                Row {
                                    id: applicationIconsRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: configService ? configService.marginTiny() : 2
                                    visible: workspaceText.workspaceShowApplicationIcons && iconResolver && windowTracker
                                    
                                    // Update when window data changes
                                    property var iconData: []
                                    
                                    Connections {
                                        target: windowTracker
                                        function onWindowsUpdated() {
                                            applicationIconsRow.updateIconData()
                                        }
                                    }
                                    
                                    Connections {
                                        target: configService
                                        function onConfigChanged() {
                                            applicationIconsRow.updateIconData()
                                        }
                                    }
                                    
                                    function updateIconData() {
                                        if (!iconResolver || !windowTracker) return
                                        
                                        const workspaceId = modelData ? modelData.id : (index + 1)
                                        const maxIcons = configService ? configService.getValue("workspaces.maxApplicationIcons", 3) : 3
                                        iconData = iconResolver.getSortedIconsForWorkspace(workspaceId, windowTracker.windowsByWorkspace, maxIcons)
                                    }
                                    
                                    Component.onCompleted: {
                                        // Delay initial update to ensure services are ready
                                        Qt.callLater(updateIconData)
                                    }
                                    
                                    Repeater {
                                        model: parent.iconData
                                        
                                        Item {
                                            width: configService ? configService.icon(configService.getEntityProperty(parent.parent.parent.parent.workspaceEntityId, "iconSize", "sm"), parent.parent.parent.parent.workspaceEntityId) : 14
                                            height: width
                                            
                                            // Show either image or emoji based on icon type
                                            Image {
                                                anchors.fill: parent
                                                source: modelData.isEmoji ? "" : modelData.iconPath
                                                fillMode: Image.PreserveAspectFit
                                                visible: !modelData.isEmoji
                                                smooth: true
                                                asynchronous: true
                                                cache: true
                                                sourceSize.width: width
                                                sourceSize.height: height
                                                
                                                onStatusChanged: {
                                                    if (status === Image.Error) {
                                                        console.warn(`[WorkspaceIcons] Failed to load icon: ${modelData.iconPath}`)
                                                    }
                                                }
                                            }
                                            
                                            // Emoji fallback
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.isEmoji ? modelData.iconPath : "◯"
                                                visible: modelData.isEmoji || (parent.children[0].status === Image.Error)
                                                font.pixelSize: parent.width * 0.8
                                                color: configService ? 
                                                      configService.getThemeProperty("colors", "text") || "#cdd6f4" : 
                                                      "#cdd6f4"
                                            }
                                            
                                            // Count indicator
                                            Text {
                                                visible: modelData.count > 1
                                                anchors.bottom: parent.bottom
                                                anchors.right: parent.right
                                                text: modelData.count
                                                font.pixelSize: parent.width * 0.4
                                                font.weight: Font.Bold
                                                color: configService ? 
                                                      configService.getThemeProperty("colors", "accent") || "#89b4fa" : 
                                                      "#89b4fa"
                                                
                                                // Small background for better visibility
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: parent.implicitWidth + (configService ? configService.marginTiny() : 2)
                                                    height: parent.implicitHeight + (configService ? configService.scaled(1) : 1)
                                                    radius: width / 2
                                                    color: configService ? 
                                                          configService.getThemeProperty("colors", "surface") || "#313244" : 
                                                          "#313244"
                                                    z: -1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            id: workspaceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            
                            onClicked: {
                                if (!configService) return
                                
                                const clickToSwitch = configService.getValue("workspaces.clickToSwitch", true)
                                if (!clickToSwitch) return
                                
                                const workspaceId = modelData ? modelData.id : (index + 1)
                                console.log(`[Workspaces] Switching to workspace ${workspaceId}`)
                                Hyprland.dispatch(`workspace ${workspaceId}`)
                            }
                            
                            onWheel: wheel => {
                                if (!configService) return
                                
                                const scrollToSwitch = configService.getValue("workspaces.scrollToSwitch", true)
                                if (!scrollToSwitch) return
                                
                                // Get current workspace index
                                const currentId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
                                let targetId = currentId
                                
                                if (wheel.angleDelta.y > 0) {
                                    // Scroll up - previous workspace
                                    targetId = Math.max(1, currentId - 1)
                                } else {
                                    // Scroll down - next workspace
                                    targetId = currentId + 1
                                }
                                
                                console.log(`[Workspaces] Scrolling from workspace ${currentId} to ${targetId}`)
                                Hyprland.dispatch("workspace", targetId.toString())
                            }
                            
                            onEntered: {
                                // Future: Could implement workspace preview on hover here
                            }
                        }
                    }
                }
            }
            
            // Right-click context menu for workspace settings
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                z: 10
                
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        mouse.accepted = true
                        centerSection.menu(bar, mouse.x, mouse.y)
                    }
                }
            }
            
            // GraphicalComponent interface: menu() function
            function menu(anchorWindow, x, y, startPath) {
                console.log(`[${componentId}] Opening workspaces context menu`)
                
                // Use dedicated workspaces context menu
                if (!workspacesMenuLoader.active) {
                    workspacesMenuLoader.active = true
                }
                
                if (workspacesMenuLoader.item) {
                    const windowToUse = anchorWindow || bar
                    const globalPos = centerSection.mapToItem(null, x || 0, y || 0)
                    workspacesMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y)
                }
            }
            
            // Dedicated loader for WorkspacesContextMenu
            Loader {
                id: workspacesMenuLoader
                source: "../overlays/WorkspacesContextMenu.qml"
                active: false
                
                onLoaded: {
                    item.configService = bar.configService
                    // themeService removed - now integrated into configService
                    
                    item.closed.connect(function() {
                        workspacesMenuLoader.active = false
                    })
                }
            }
            
            // GraphicalComponent interface methods
            function registerComponent() {
                if (componentId) {
                    ComponentRegistry.registerComponent(componentId, centerSection)
                    console.log(`[${componentId}] Registered component with hierarchy: parent=${parentComponentId}, children=[${childComponentIds.join(', ')}]`)
                }
            }
            
            function unregisterComponent() {
                if (componentId) {
                    ComponentRegistry.unregisterComponent(componentId)
                    console.log(`[${componentId}] Unregistered component`)
                }
            }
            
            Component.onCompleted: {
                registerComponent()
            }
            
            Component.onDestruction: {
                unregisterComponent()
            }
        }
        
        // Individual monitoring widgets section
        Row {
            id: monitoringSection
            spacing: configService ? configService.spacing("xs", entityId) : 4
            visible: cpuMonitor.visible || ramMonitor.visible || storageMonitor.visible
            
            anchors {
                right: rightSection.left
                rightMargin: visible ? configService ? configService.spacing("xs", entityId) : 4 : 0
                verticalCenter: parent.verticalCenter
            }
            
            // CPU Monitor
            Rectangle {
                id: cpuContainer
                implicitWidth: cpuMonitor.visible ? cpuMonitor.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: cpuMonitor.visible ? cpuMonitor.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: cpuMonitor.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: cpuMonitor.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: cpuMonitor.visible
                
                CpuMonitor {
                    id: cpuMonitor
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("cpu.enabled", true) : true
                    
                    // Services
                    systemMonitorService: bar.systemMonitorService
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    displayMode: "compact"
                    showIcon: configService ? configService.getValue("cpu.showIcon", true) : true
                    showText: true
                    showLabel: configService ? configService.getValue("cpu.showLabel", false) : false
                    showPercentage: configService ? configService.getValue("cpu.showPercentage", true) : true
                    showFrequency: configService ? configService.getValue("cpu.showFrequency", false) : false
                }
            }
            
            // RAM Monitor
            Rectangle {
                id: ramContainer
                implicitWidth: ramMonitor.visible ? ramMonitor.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: ramMonitor.visible ? ramMonitor.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: ramMonitor.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: ramMonitor.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: ramMonitor.visible
                
                RamMonitor {
                    id: ramMonitor
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("ram.enabled", true) : true
                    
                    // Services
                    systemMonitorService: bar.systemMonitorService
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    displayMode: "compact"
                    showIcon: configService ? configService.getValue("ram.showIcon", true) : true
                    showText: true
                    showLabel: configService ? configService.getValue("ram.showLabel", false) : false
                    showPercentage: configService ? configService.getValue("ram.showPercentage", true) : true
                    showFrequency: configService ? configService.getValue("ram.showFrequency", false) : false
                    showTotal: configService ? configService.getValue("ram.showTotal", true) : true
                }
            }
            
            // Storage Monitor
            Rectangle {
                id: storageContainer
                implicitWidth: storageMonitor.visible ? storageMonitor.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: storageMonitor.visible ? storageMonitor.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: storageMonitor.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: storageMonitor.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: storageMonitor.visible
                
                StorageMonitor {
                    id: storageMonitor
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("storage.enabled", true) : true
                    
                    // Services
                    systemMonitorService: bar.systemMonitorService
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    displayMode: "compact"
                    showIcon: configService ? configService.getValue("storage.showIcon", true) : true
                    showText: true
                    showLabel: configService ? configService.getValue("storage.showLabel", false) : false
                    showPercentage: configService ? configService.getValue("storage.showPercentage", true) : true
                    showBytes: configService ? configService.getValue("storage.showBytes", false) : false
                }
            }
            
            // GPU Monitor
            Rectangle {
                id: gpuContainer
                implicitWidth: gpuMonitor.visible ? gpuMonitor.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: gpuMonitor.visible ? gpuMonitor.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: gpuMonitor.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: gpuMonitor.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: gpuMonitor.visible
                
                GpuMonitor {
                    id: gpuMonitor
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("gpu.enabled", true) : true
                    
                    // Services
                    systemMonitorService: bar.systemMonitorService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    displayMode: "compact"
                    showIcon: configService ? configService.getValue("gpu.showIcon", true) : true
                    showText: true
                    showLabel: configService ? configService.getValue("gpu.showLabel", false) : false
                    showPercentage: configService ? configService.getValue("gpu.showPercentage", true) : true
                    showMemory: configService ? configService.getValue("gpu.showMemory", false) : false
                    showClocks: configService ? configService.getValue("gpu.showClocks", false) : false
                }
            }
        }
        
        // Widget section - Audio, Brightness, Temperature, and Battery controls
        Row {
            id: widgetSection
            spacing: configService ? configService.spacing("xs", entityId) : 4
            visible: audioWidget.visible || brightnessWidget.visible || cpuTempWidget.visible || gpuTempWidget.visible || batteryWidget.visible
            
            anchors {
                right: monitoringSection.left
                rightMargin: visible ? configService ? configService.spacing("xs", entityId) : 4 : 0
                verticalCenter: parent.verticalCenter
            }
            
            // Audio Widget
            Rectangle {
                id: audioContainer
                implicitWidth: audioWidget.visible ? audioWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: audioWidget.visible ? audioWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: audioWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: audioWidget.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: audioWidget.visible
                
                AudioWidget {
                    id: audioWidget
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("audio.enabled", true) : true
                    
                    // Services
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    showIcon: configService ? configService.getValue("audio.showIcon", true) : true
                    showPercentage: configService ? configService.getValue("audio.showPercentage", true) : true
                    showSlider: configService ? configService.getValue("audio.showSlider", false) : false
                }
            }
            
            // Brightness Widget
            Rectangle {
                id: brightnessContainer
                implicitWidth: brightnessWidget.visible ? brightnessWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: brightnessWidget.visible ? brightnessWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: brightnessWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: brightnessWidget.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: brightnessWidget.visible
                
                BrightnessWidget {
                    id: brightnessWidget
                    anchors.centerIn: parent
                    visible: configService ? configService.getValue("brightness.enabled", true) : true
                    
                    // Services
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    showIcon: configService ? configService.getValue("brightness.showIcon", true) : true
                    showPercentage: configService ? configService.getValue("brightness.showPercentage", true) : true
                    showSlider: configService ? configService.getValue("brightness.showSlider", false) : false
                }
            }
            
            
            
            // Battery Widget
            Rectangle {
                id: batteryContainer
                implicitWidth: batteryWidget.visible ? batteryWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
                implicitHeight: batteryWidget.visible ? batteryWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
                radius: configService ? configService.borderRadius : 8
                color: batteryWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
                border.width: batteryWidget.visible ? 1 : 0
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                visible: batteryWidget.visible
                
                BatteryWidget {
                    id: batteryWidget
                    anchors.centerIn: parent
                    visible: configService ? configService.getBatteryEnabled() : true
                    
                    // Services
                    // themeService removed - now integrated into configService
                    configService: bar.configService
                    anchorWindow: bar
                    
                    // Display configuration
                    showIcon: configService ? configService.getValue("battery.showIcon", true) : true
                    showPercentage: configService ? configService.getValue("battery.showPercentage", true) : true
                    showTime: configService ? configService.getValue("battery.showTime", false) : false
                }
            }
        }
        
        // Right section - Clock (anchored to right)
        Rectangle {
            id: rightSection
            // Use same dynamic sizing pattern as other widgets
            implicitWidth: clockWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8)
            implicitHeight: clockWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4)
            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: configService ? configService.borderRadius : 8
            border.width: 1
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            
            anchors {
                right: notificationSection.visible ? notificationSection.left : (systraySection.visible ? systraySection.left : powerSection.left)
                rightMargin: configService ? configService.spacing("md", entityId) : 8
                verticalCenter: parent.verticalCenter
            }
            
            Clock {
                id: clockWidget
                anchors.centerIn: parent
                configService: bar.configService
                anchorWindow: bar
            }
        }
        
        // Notification section - Between clock and system tray
        Rectangle {
            id: notificationSection
            implicitWidth: notificationWidget.visible ? notificationWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
            implicitHeight: notificationWidget.visible ? notificationWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
            radius: configService ? configService.borderRadius : 8
            color: notificationWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
            border.width: notificationWidget.visible ? 1 : 0
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            visible: notificationWidget.visible
            
            anchors {
                right: systraySection.left
                rightMargin: visible ? configService ? configService.spacing("md", entityId) : 8 : 0
                verticalCenter: parent.verticalCenter
            }
            
            NotificationWidget {
                id: notificationWidget
                anchors.centerIn: parent
                
                // Services
                configService: bar.configService
                notificationService: NotificationService
                anchorWindow: bar
                
                // Widget configuration from config service
                enabled: configService ? configService.getEntityProperty("notificationWidget", "enabled", true) : true
                showIcon: configService ? configService.getEntityProperty("notificationWidget", "showIcon", true) : true
                showCount: configService ? configService.getEntityProperty("notificationWidget", "showCount", true) : true
                showUnreadOnly: configService ? configService.getEntityProperty("notificationWidget", "showUnreadOnly", true) : true
                animateChanges: configService ? configService.getEntityProperty("notificationWidget", "animateChanges", true) : true
            }
        }
        
        // System Tray section - Between notifications and power button
        Rectangle {
            id: systraySection
            implicitWidth: systrayWidget.visible ? systrayWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
            implicitHeight: systrayWidget.visible ? systrayWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
            radius: configService ? configService.borderRadius : 8
            color: systrayWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
            border.width: systrayWidget.visible ? 1 : 0
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            visible: systrayWidget.visible
            
            anchors {
                right: powerSection.left
                rightMargin: visible ? configService ? configService.spacing("md", entityId) : 8 : 0
                verticalCenter: parent.verticalCenter
            }
            
            SystemTrayWidget {
                id: systrayWidget
                anchors.centerIn: parent
                
                // Services
                configService: bar.configService
                
                // Widget configuration from config service
                enabled: configService ? configService.getValue("widgets.systray.enabled", true) : true
                iconSize: configService ? configService.getValue("widgets.systray.iconSize", 20) : 20
                spacing: configService ? configService.getValue("widgets.systray.spacing", 4) : 4
                layout: configService ? configService.getValue("widgets.systray.layout", "horizontal") : "horizontal"
                showTooltips: configService ? configService.getValue("widgets.systray.showTooltips", true) : true
                
                // Handle tray item interactions
                onItemClicked: (item) => {
                    console.log("Bar: System tray item clicked:", item ? item.title : "unknown")
                }
                
                onItemRightClicked: (item) => {
                    console.log("Bar: System tray item right-clicked:", item ? item.title : "unknown")
                }
                
                onMenuRequested: (item, anchorItem) => {
                    console.log("Bar: System tray menu requested for:", item ? item.title : "unknown")
                    // The SystemTrayWidget will handle the menu display
                    if (item && item.hasMenu && item.menu) {
                        // Use Quickshell's menu system to display the tray item's menu
                        // This might need adjustment based on the actual Quickshell API
                        try {
                            item.menu.display(anchorItem, 0, anchorItem.height)
                        } catch (error) {
                            console.warn("Bar: Failed to display tray menu:", error)
                        }
                    }
                }
            }
        }
        
        // Power section - Far right power button
        Rectangle {
            id: powerSection
            implicitWidth: powerSectionWidget.visible ? powerSectionWidget.implicitWidth + (configService ? configService.spacing("sm", entityId) : 8) : 0
            implicitHeight: powerSectionWidget.visible ? powerSectionWidget.implicitHeight + (configService ? configService.spacing("xs", entityId) : 4) : 0
            radius: configService ? configService.borderRadius : 8
            color: powerSectionWidget.visible ? (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : "transparent"
            border.width: powerSectionWidget.visible ? 1 : 0
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            visible: powerSectionWidget.visible
            
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            
            PowerWidget {
                id: powerSectionWidget
                anchors.centerIn: parent
                visible: configService ? configService.getValue("power.enabled", true) : true
                
                // Services
                // themeService removed - now integrated into configService
                configService: bar.configService
                sessionOverlay: bar.sessionOverlay
                anchorWindow: bar
                
                // Display configuration - only show icon for far right placement
                showIcon: true
                showText: false
            }
        }
    }
    
    // Quick menu popup (inline definition)
    PopupWindow {
        id: quickMenu
        implicitWidth: configService ? configService.scaled(200) : 200
        implicitHeight: configService ? configService.scaled(150) : 150
        visible: false
        
        anchor {
            window: bar
            rect {
                x: 0
                y: configService ? configService.scaled(32) : 32
                width: 1
                height: 1
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: configService ? configService.borderRadius : 8
            border.width: 1
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            
            Column {
                anchors.fill: parent
                anchors.margins: configService ? configService.spacing("md", entityId) : 8
                spacing: configService ? configService.spacing("xs", entityId) : 4
                
                Text {
                    text: "Quick Settings"
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.family: "Inter"
                    font.pixelSize: configService ? configService.fontMedium() : 12
                    font.weight: Font.DemiBold
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Theme toggle button
                Rectangle {
                    width: parent.width
                    height: configService ? configService.scaled(24) : 24
                    color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: configService ? configService.borderRadius : 8
                    border.width: 1
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🌓 Toggle Mode"
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("sm", entityId) : 10
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (configService) {
                                configService.toggleDarkMode()
                            }
                            quickMenu.visible = false
                        }
                        
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                // Cycle theme button
                Rectangle {
                    width: parent.width
                    height: configService ? configService.scaled(24) : 24
                    color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: configService ? configService.borderRadius : 8
                    border.width: 1
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🎨 Theme Settings"
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("sm", entityId) : 10
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            // Theme cycling functionality removed - manage themes via config
                            console.log("Theme cycling not implemented in ConfigService approach")
                            quickMenu.visible = false
                        }
                        
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
    
    // Right-click context menu for bar configuration (lower z-order so monitors can override)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        z: -1  // Lower z-order so monitor MouseAreas can override
        onClicked: mouse => {
            console.log(`[${componentId}] Mouse click detected - button:`, mouse.button, "at:", mouse.x, mouse.y)
            if (mouse.button === Qt.RightButton) {
                console.log(`[${componentId}] Right-click detected, showing bar context menu`)
                menu(bar, mouse.x, mouse.y)
            }
        }
    }
    
    // GraphicalComponent interface: menu() function
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening bar context menu`)
        
        // Use dedicated bar context menu
        if (!barMenuLoader.active) {
            barMenuLoader.active = true
        }
        
        if (barMenuLoader.item) {
            const windowToUse = anchorWindow || bar
            // Use the provided coordinates directly since they're already relative to the window
            barMenuLoader.item.show(windowToUse, x || 0, y || 0)
        }
    }
    
    // Dedicated loader for BarContextMenu
    Loader {
        id: barMenuLoader
        source: "../overlays/BarContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = bar.configService
            // themeService removed - now integrated into configService
            item.wallpaperService = bar.wallpaperService
            item.widgetRegistry = bar.widgetRegistry
            item.shellRoot = bar.shellRoot
            
            item.closed.connect(function() {
                barMenuLoader.active = false
            })
        }
    }
    
    // GraphicalComponent interface methods
    function list_children() {
        return childComponentIds.map(id => ComponentRegistry.getComponent(id)).filter(comp => comp !== null)
    }
    
    function get_parent() {
        if (!parentComponentId) return null
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return ComponentRegistry.getComponent(id)
    }
    
    function navigateToParent() {
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            console.log(`[${componentId}] Navigating to parent: ${parentComponentId}`)
            parent.menu()
        } else {
            console.log(`[${componentId}] No parent component found or parent doesn't implement menu()`)
        }
    }
    
    function navigateToChild(childId) {
        const child = get_child(childId)
        if (child && typeof child.menu === 'function') {
            console.log(`[${componentId}] Navigating to child: ${childId}`)
            child.menu()
        } else {
            console.log(`[${componentId}] Child component ${childId} not found or doesn't implement menu()`)
        }
    }
    
    function registerComponent() {
        if (componentId) {
            ComponentRegistry.registerComponent(componentId, bar)
            console.log(`[${componentId}] Registered component with hierarchy: parent=${parentComponentId}, children=[${childComponentIds.join(', ')}]`)
        }
    }
    
    function unregisterComponent() {
        if (componentId) {
            ComponentRegistry.unregisterComponent(componentId)
            console.log(`[${componentId}] Unregistered component`)
        }
    }

    Component.onCompleted: {
        registerComponent()
        // Bar initialized
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
}