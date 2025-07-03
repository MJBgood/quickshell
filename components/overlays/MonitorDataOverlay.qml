import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtCore
import "." as Overlays

PopupWindow {
    id: dataOverlay
    
    // Window properties
    implicitWidth: 320
    implicitHeight: Math.min(400, 280)  // Max height of 400, preferred 280
    visible: false
    color: "transparent"
    
    // Services
    property var configService: null
    property var themeService: null
    property var systemMonitorService: null
    
    // Monitor-specific properties
    property string monitorType: "cpu"  // cpu, ram, or storage
    property string monitorName: "CPU"  // Display name
    property string monitorIcon: "💻"   // Display icon
    
    // Live data properties
    property real currentUsage: 0.0
    property real totalAvailable: 0.0
    property real usagePercent: 0.0
    property string currentFrequency: ""
    property string displayValue: ""
    
    // Configuration properties (reactive)
    property bool configEnabled: configService ? configService.getValue("performance." + monitorType + ".enabled", true) : true
    property bool configShowIcon: configService ? configService.getValue("performance." + monitorType + ".showIcon", true) : true
    property bool configShowLabel: configService ? configService.getValue("performance." + monitorType + ".showLabel", false) : false
    property bool configShowPercentage: configService ? configService.getValue("performance." + monitorType + ".showPercentage", true) : true
    property bool configShowFrequency: configService ? configService.getValue("performance." + monitorType + ".showFrequency", false) : false
    property bool configShowBytes: configService ? configService.getValue("performance." + monitorType + ".showBytes", false) : false
    property bool configShowTotal: configService ? configService.getValue("performance." + monitorType + ".showTotal", true) : true
    property int configPrecision: configService ? configService.getValue("performance." + monitorType + ".precision", monitorType === "cpu" ? 1 : 0) : 0
    
    // Signals
    signal closed()
    
    // Functions for external control
    function cancelAutoHide() {
        autoHideTimer.stop()
        console.log(logCategory, "Auto-hide cancelled")
    }
    
    // Logging category
    LoggingCategory {
        id: logCategory
        name: "quickshell.performance.monitor.dataoverlay"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Anchor configuration
    anchor {
        window: null
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins {
            left: 8
            right: 8
            top: 8
            bottom: 8
        }
    }
    
    // Focus grab for dismissing when clicking outside (Hyprland)
    HyprlandFocusGrab {
        id: focusGrab
        windows: [dataOverlay]
        onCleared: {
            console.log(logCategory, "Focus grab cleared - hiding overlay")
            hide()
        }
    }
    
    // Auto-hide timer
    Timer {
        id: autoHideTimer
        interval: 2000  // 2 seconds when exiting
        repeat: false
        onTriggered: {
            console.log(logCategory, "Auto-hide timer triggered for", monitorName)
            hide()
        }
    }
    
    // Main container
    Rectangle {
        id: overlayContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        // Simple mouse area - overlay only hides when explicitly closed
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true  // Allow child MouseAreas to work
            
            onEntered: {
                // Stop any auto-hide timers when mouse enters overlay
                autoHideTimer.stop()
                console.log(logCategory, "Mouse ENTERED overlay - stopping auto-hide")
            }
        }
        
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                // Set scrollbar policies after component creation
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            // Custom scrollbar styling
            ScrollBar.vertical: ScrollBar {
                id: verticalScrollBar
                active: true
                policy: ScrollBar.AsNeeded
                size: 0.3
                width: 8
                
                background: Rectangle {
                    color: "transparent"
                    radius: 4
                }
                
                contentItem: Rectangle {
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    radius: 4
                    opacity: verticalScrollBar.active ? 0.8 : 0.4
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
            }
            
            Column {
                width: Math.max(parent.width - 16, 280)  // Ensure minimum width
                spacing: 12
            
            // Header
            Item {
                width: parent.width
                height: 32
                
                Text {
                    id: iconText
                    text: monitorIcon
                    font.pixelSize: 20
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Column {
                    anchors.left: iconText.right
                    anchors.leftMargin: 12
                    anchors.right: closeButton.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        text: monitorName + " Monitor"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        text: configEnabled ? "Enabled" : "Disabled"
                        font.pixelSize: 10
                        color: configEnabled ? "#a6e3a1" : "#f38ba8"
                    }
                }
                
                // Close button
                Rectangle {
                    id: closeButton
                    width: 24
                    height: 24
                    radius: 12
                    color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeArea.containsMouse ? "#1e1e2e" : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log(logCategory, "Close button clicked")
                            hide()
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // Interactive data components
            Column {
                width: parent.width
                spacing: 8
                
                // Enable/Disable toggle
                Overlays.DataToggleItem {
                    width: parent.width
                    label: "Monitor"
                    value: configEnabled ? "Enabled" : "Disabled"
                    isActive: configEnabled
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("enabled")
                }
                
                // Icon toggle
                Overlays.DataToggleItem {
                    width: parent.width
                    label: "Icon"
                    value: configShowIcon ? monitorIcon : "Hidden"
                    isActive: configShowIcon
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showIcon")
                }
                
                // Label toggle
                Overlays.DataToggleItem {
                    width: parent.width
                    label: "Label"
                    value: configShowLabel ? ("\"" + monitorName + "\"") : "Hidden"
                    isActive: configShowLabel
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showLabel")
                }
                
                // Total available toggle (for RAM only - Storage uses bytes format)
                Overlays.DataToggleItem {
                    visible: monitorType === "ram"
                    width: parent.width
                    label: "Show Total"
                    value: configShowTotal ? (totalAvailable.toFixed(1) + " GB") : "Hidden"
                    isActive: configShowTotal
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showTotal")
                }
                
                // Percentage toggle
                Overlays.DataToggleItem {
                    width: parent.width
                    label: "Percentage"
                    value: configShowPercentage ? (usagePercent.toFixed(configPrecision) + "%") : "Hidden"
                    isActive: configShowPercentage
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showPercentage")
                }
                
                // Frequency toggle (CPU and RAM only)
                Overlays.DataToggleItem {
                    visible: monitorType === "cpu" || monitorType === "ram"
                    width: parent.width
                    label: "Frequency"
                    value: configShowFrequency ? (currentFrequency || "N/A") : "Hidden"
                    isActive: configShowFrequency
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showFrequency")
                }
                
                // Bytes toggle (Storage only)
                Overlays.DataToggleItem {
                    visible: monitorType === "storage"
                    width: parent.width
                    label: "Bytes Format"
                    value: configShowBytes ? "x.x/y.y GB" : "Hidden"
                    isActive: configShowBytes
                    themeService: dataOverlay.themeService
                    onClicked: toggleConfig("showBytes")
                }
                
                // Precision
                Overlays.DataToggleItem {
                    width: parent.width
                    label: "Precision"
                    value: configPrecision + " decimal" + (configPrecision === 1 ? "" : "s")
                    isActive: true
                    themeService: dataOverlay.themeService
                    onClicked: cyclePrecision()
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // Live preview
            Column {
                width: parent.width
                spacing: 4
                
                Text {
                    text: "Current Display:"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                }
                
                Rectangle {
                    width: parent.width
                    height: previewText.implicitHeight + 8
                    color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    radius: 6
                    
                    Text {
                        id: previewText
                        anchors.centerIn: parent
                        text: displayValue
                        font.pixelSize: 11
                        font.family: "monospace"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                }
            }
            } // End Column
        } // End ScrollView
        
        // Scroll indicators
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            width: 30
            height: 4
            radius: 2
            color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            opacity: scrollView.contentHeight > scrollView.height ? 0.6 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 2
                radius: 1
                color: themeService ? themeService.getThemeProperty("colors", "accent") || "#89b4fa" : "#89b4fa"
            }
        }
    }
    
    // Helper functions
    function updateConfigProperties() {
        if (!configService) return
        
        configEnabled = configService.getValue("performance." + monitorType + ".enabled", true)
        configShowIcon = configService.getValue("performance." + monitorType + ".showIcon", true)
        configShowLabel = configService.getValue("performance." + monitorType + ".showLabel", false)
        configShowPercentage = configService.getValue("performance." + monitorType + ".showPercentage", true)
        configShowFrequency = configService.getValue("performance." + monitorType + ".showFrequency", false)
        configShowBytes = configService.getValue("performance." + monitorType + ".showBytes", false)
        configShowTotal = configService.getValue("performance." + monitorType + ".showTotal", true)
        configPrecision = configService.getValue("performance." + monitorType + ".precision", monitorType === "cpu" ? 1 : 0)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "performance." + monitorType + "." + key
        const currentValue = configService.getValue(configKey, key === "showLabel" ? false : true)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
        
        updateConfigProperties()
        
        console.log(logCategory, monitorName, key, "set to", newValue)
    }
    
    function cyclePrecision() {
        if (!configService) return
        
        const configKey = "performance." + monitorType + ".precision"
        const currentPrecision = configService.getValue(configKey, monitorType === "cpu" ? 1 : 0)
        const newPrecision = (currentPrecision + 1) % 4
        
        configService.setValue(configKey, newPrecision)
        configService.saveConfig()
        
        updateConfigProperties()
        
        console.log(logCategory, monitorName, "precision set to", newPrecision)
    }
    
    function show(anchorWindow, x, y) {
        console.log(logCategory, "Show data overlay for", monitorName, "at position:", x, y)
        
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 20)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 20)
            
            popupX = Math.max(20, popupX)
            popupY = Math.max(20, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
        }
        
        updateConfigProperties()
        
        // Stop any existing timers and activate focus grab
        autoHideTimer.stop()
        
        visible = true
        focusGrab.active = true
        
        console.log(logCategory, "Overlay shown - will dismiss when clicking outside")
    }
    
    function hide() {
        visible = false
        autoHideTimer.stop()
        focusGrab.active = false
        closed()
    }
    
    function startAutoHide() {
        // Only start auto-hide when explicitly called (from monitor exit)
        autoHideTimer.start()
        console.log(logCategory, "Starting auto-hide timer")
    }
    
    // Update display value when config changes
    onConfigEnabledChanged: updateDisplayValue()
    onConfigShowIconChanged: updateDisplayValue()
    onConfigShowLabelChanged: updateDisplayValue()
    onConfigShowPercentageChanged: updateDisplayValue()
    onConfigShowFrequencyChanged: updateDisplayValue()
    onConfigShowBytesChanged: updateDisplayValue()
    onConfigShowTotalChanged: updateDisplayValue()
    onConfigPrecisionChanged: updateDisplayValue()
    
    function updateDisplayValue() {
        // Calculate what would actually be displayed
        let parts = []
        
        if (configShowIcon) parts.push(monitorIcon)
        if (configShowLabel) parts.push(monitorName)
        
        if (monitorType === "cpu") {
            let cpuParts = []
            if (configShowPercentage) {
                cpuParts.push(currentUsage.toFixed(configPrecision) + "%")
            } else {
                cpuParts.push(currentUsage.toFixed(configPrecision))
            }
            if (configShowFrequency && currentFrequency) {
                cpuParts.push(currentFrequency)
            }
            if (cpuParts.length > 0) {
                parts.push(cpuParts.join(" | "))
            }
        } else if (monitorType === "ram") {
            let ramParts = []
            if (configShowPercentage) {
                ramParts.push(usagePercent.toFixed(configPrecision) + "%")
            }
            if (configShowTotal) {
                ramParts.push(currentUsage.toFixed(1) + "/" + totalAvailable.toFixed(1) + " GB")
            } else if (!configShowPercentage) {
                ramParts.push(currentUsage.toFixed(1) + " GB")
            }
            if (ramParts.length > 0) {
                parts.push(ramParts.join(" | "))
            }
            if (configShowFrequency && currentFrequency) {
                parts.push(currentFrequency)
            }
        } else if (monitorType === "storage") {
            let storageParts = []
            if (configShowPercentage) {
                storageParts.push(usagePercent.toFixed(configPrecision) + "%")
            }
            if (configShowBytes) {
                storageParts.push(currentUsage.toFixed(1) + "/" + totalAvailable.toFixed(1) + " GB")
            } else if (!configShowPercentage) {
                storageParts.push(currentUsage.toFixed(1) + " GB")
            }
            if (storageParts.length > 0) {
                parts.push(storageParts.join(" | "))
            }
        }
        
        displayValue = parts.join(" ")
    }
    
    Component.onCompleted: updateConfigProperties()
    onConfigServiceChanged: updateConfigProperties()
}