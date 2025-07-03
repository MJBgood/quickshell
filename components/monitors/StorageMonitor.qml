import QtQuick
import "../overlays"
import "../base"

Rectangle {
    id: storageMonitor
    
    // GraphicalComponent interface implementation
    property string componentId: "storage"
    property string parentComponentId: "performance"
    property var childComponentIds: []
    property string menuPath: "performance.storage"
    
    // Services
    property var systemMonitorService: null
    property var configService: null
    property var themeService: null
    property var anchorWindow: null
    
    // Display configuration
    property bool showIcon: true
    property bool showText: true
    property bool showPercentage: true
    property bool showLabel: true  // Show "Disk" text label
    property bool showBytes: false  // Show byte values
    property bool showTotal: true  // Show total available storage
    property string displayMode: "compact" // "compact", "detailed", "minimal"
    property int precisionDigits: 0  // Decimal precision for storage percentage
    
    // Current storage data
    property real storageUsed: 0.0
    property real storageTotal: 0.0
    property real storageUsagePercent: 0.0
    property string storageDisplay: "0 GB"
    
    // Visual configuration
    implicitWidth: contentRow.implicitWidth + 12
    implicitHeight: 20
    radius: 4
    
    // Dynamic background color based on storage usage
    color: {
        if (!themeService) return "#313244"
        
        if (storageUsagePercent > 90) {
            return themeService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (storageUsagePercent > 80) {
            return themeService.getThemeProperty("colors", "warning") || "#f9e2af"
        } else {
            return themeService.getThemeProperty("colors", "surface") || "#313244"
        }
    }
    
    // Smooth color transitions
    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Content layout
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4
        
        // Storage icon
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "💾"  // Storage/disk icon
            color: {
                if (!themeService) return "#cdd6f4"
                
                // Dynamic icon color based on usage
                if (storageUsagePercent > 90) {
                    return themeService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return themeService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: 10
        }
        
        // Storage usage text
        Text {
            visible: showText && displayMode !== "minimal"
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                let labelText = showLabel ? "Disk " : ""
                
                if (labelText) parts.push(labelText.trim())
                
                let dataParts = []
                if (showPercentage) {
                    dataParts.push(storageUsagePercent.toFixed(precisionDigits) + "%")
                }
                if (showBytes) {
                    dataParts.push(storageUsed.toFixed(1) + "/" + storageTotal.toFixed(1) + " GB")
                } else if (!showPercentage) {
                    dataParts.push(storageUsed.toFixed(1) + " GB")
                }
                
                if (dataParts.length > 0) {
                    parts.push(dataParts.join(" | "))
                }
                
                return parts.join(" ")
            }
            color: {
                if (!themeService) return "#cdd6f4"
                
                // Dynamic text color based on usage
                if (storageUsagePercent > 90) {
                    return themeService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return themeService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: 9
            font.weight: storageUsagePercent > 85 ? Font.DemiBold : Font.Medium
        }
    }
    
    // Usage bar indicator (for minimal mode)
    Rectangle {
        visible: displayMode === "minimal"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        radius: 1
        
        color: {
            if (!themeService) return "#89b4fa"
            
            if (storageUsagePercent > 90) {
                return themeService.getThemeProperty("colors", "error") || "#f38ba8"
            } else if (storageUsagePercent > 80) {
                return themeService.getThemeProperty("colors", "warning") || "#f9e2af"
            } else {
                return themeService.getThemeProperty("colors", "accent") || "#a6e3a1"
            }
        }
        
        // Animated width based on usage
        width: parent.width * (storageUsagePercent / 100)
        
        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
    
    // Hover effects - Show interactive data overlay
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        Timer {
            id: hoverTimer
            interval: 800  // Show overlay after 800ms of hover
            repeat: false
            onTriggered: showDataOverlay()
        }
        
        onEntered: {
            storageMonitor.opacity = 0.8
            hoverTimer.start()
            if (dataOverlayLoader.item && dataOverlayLoader.item.visible) {
                // Cancel auto-hide if overlay is already visible
                dataOverlayLoader.item.cancelAutoHide()
                console.log("Storage monitor entered, cancelling overlay auto-hide")
            }
        }
        
        onExited: {
            storageMonitor.opacity = 1.0
            hoverTimer.stop()
            // Start auto-hide when leaving the monitor (only if overlay is visible)
            if (dataOverlayLoader.item && dataOverlayLoader.item.visible) {
                dataOverlayLoader.item.startAutoHide()
                console.log("Storage monitor exited, starting overlay auto-hide")
            }
        }
    }
    
    function showDataOverlay() {
        dataOverlayLoader.active = true
        if (dataOverlayLoader.item) {
            const windowToUse = anchorWindow || storageMonitor
            const globalPos = storageMonitor.mapToItem(null, storageMonitor.width / 2, storageMonitor.height)
            dataOverlayLoader.item.show(windowToUse, globalPos.x, globalPos.y)
        }
    }
    
    // Hover tooltip (for compact mode)
    Rectangle {
        id: hoverText
        visible: false
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        z: 1000
        
        width: hoverContent.implicitWidth + 8
        height: hoverContent.implicitHeight + 4
        radius: 4
        
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.width: 1
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        
        Text {
            id: hoverContent
            anchors.centerIn: parent
            text: `Storage: ${storageUsed.toFixed(1)}/${storageTotal.toFixed(1)} GB (${storageUsagePercent.toFixed(1)}%)`
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.family: "Inter"
            font.pixelSize: 8
        }
    }
    
    // Smooth opacity transitions
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    
    // Connect to system monitor service
    Connections {
        target: systemMonitorService
        function onStorageUpdated(used, total, percentage) {
            storageUsed = used
            storageTotal = total
            storageUsagePercent = percentage
            storageDisplay = used.toFixed(1) + "/" + total.toFixed(1) + " GB"
        }
    }
    
    // Update display on service change
    onSystemMonitorServiceChanged: {
        if (systemMonitorService) {
            const stats = systemMonitorService.getCurrentStats()
            storageUsed = stats.storage.used
            storageTotal = stats.storage.total
            storageUsagePercent = stats.storage.percent
            storageDisplay = stats.storage.display
        }
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu`)
        
        // Storage uses parent's menu with its specific path
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            parent.menu(anchorWindow, x, y, startPath || menuPath)
        }
    }
    
    function list_children() {
        return []
    }
    
    function get_parent() {
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null
    }

    // Right-click to show hierarchical menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: 10  // Higher z-order to override bar's MouseArea
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // Stop event propagation
                mouse.accepted = true
                
                // Show hierarchical menu instead of data overlay
                storageMonitor.menu(anchorWindow, mouse.x, mouse.y)
            }
        }
    }
    
    // Interactive Data Overlay - Lazy loaded
    Loader {
        id: dataOverlayLoader
        source: "../overlays/MonitorDataOverlay.qml"
        active: false
        
        onLoaded: {
            item.configService = storageMonitor.configService
            item.themeService = storageMonitor.themeService
            item.systemMonitorService = storageMonitor.systemMonitorService
            item.monitorType = "storage"
            item.monitorName = "Storage"
            item.monitorIcon = "💾"
            
            // Auto-hide when closed
            item.closed.connect(function() {
                dataOverlayLoader.active = false
            })
            
            // Keep data updated
            updateOverlayData()
        }
    }
    
    // Update overlay data
    function updateOverlayData() {
        if (dataOverlayLoader.item) {
            dataOverlayLoader.item.currentUsage = storageUsed
            dataOverlayLoader.item.totalAvailable = storageTotal
            dataOverlayLoader.item.usagePercent = storageUsagePercent
            dataOverlayLoader.item.updateDisplayValue()
        }
    }
    
    // Update overlay when data changes
    onStorageUsedChanged: updateOverlayData()
    onStorageTotalChanged: updateOverlayData()
    onStorageUsagePercentChanged: updateOverlayData()
    
    // Component registration
    function registerComponent() {
        ComponentRegistry.registerComponent(componentId, storageMonitor)
        console.log(`[${componentId}] Registered with hierarchy`)
    }

    Component.onCompleted: {
        // Register with ComponentRegistry
        registerComponent()
        
        // Initialize with current data if available
        if (systemMonitorService) {
            const stats = systemMonitorService.getCurrentStats()
            storageUsed = stats.storage.used
            storageTotal = stats.storage.total
            storageUsagePercent = stats.storage.percent
            storageDisplay = stats.storage.display
        }
    }
}