import QtQuick
import "../monitors"
import "../overlays"
import "../base"

Rectangle {
    id: performanceWidget
    
    // GraphicalComponent interface implementation
    property string componentId: "performance"
    property string parentComponentId: "system"
    property var childComponentIds: ["cpu", "ram", "storage"]
    property string menuPath: "performance"
    
    // Services
    property var systemMonitorService: null
    property var configService: null
    property var themeService: null
    property var barWindow: null
    
    // Display configuration from ConfigService
    property string layout: configService ? configService.getValue("performance.layout", "horizontal") : "horizontal"
    property string displayMode: configService ? configService.getValue("performance.displayMode", "compact") : "compact"
    property bool showCpu: configService ? configService.getValue("performance.cpu.enabled", true) : true
    property bool showRam: configService ? configService.getValue("performance.ram.enabled", true) : true
    property bool showStorage: configService ? configService.getValue("performance.storage.enabled", true) : true
    
    // Individual monitor display settings
    property bool cpuShowIcon: configService ? configService.getValue("performance.cpu.showIcon", true) : true
    property bool cpuShowLabel: configService ? configService.getValue("performance.cpu.showLabel", false) : false
    property bool cpuShowPercentage: configService ? configService.getValue("performance.cpu.showPercentage", true) : true
    property bool cpuShowFrequency: configService ? configService.getValue("performance.cpu.showFrequency", false) : false
    property int cpuPrecision: configService ? configService.getValue("performance.cpu.precision", 1) : 1
    
    property bool ramShowIcon: configService ? configService.getValue("performance.ram.showIcon", true) : true
    property bool ramShowLabel: configService ? configService.getValue("performance.ram.showLabel", false) : false
    property bool ramShowPercentage: configService ? configService.getValue("performance.ram.showPercentage", true) : true
    property bool ramShowFrequency: configService ? configService.getValue("performance.ram.showFrequency", false) : false
    property int ramPrecision: configService ? configService.getValue("performance.ram.precision", 0) : 0
    
    property bool storageShowIcon: configService ? configService.getValue("performance.storage.showIcon", true) : true
    property bool storageShowLabel: configService ? configService.getValue("performance.storage.showLabel", false) : false
    property bool storageShowPercentage: configService ? configService.getValue("performance.storage.showPercentage", true) : true
    property bool storageShowBytes: configService ? configService.getValue("performance.storage.showBytes", false) : false
    property int storagePrecision: configService ? configService.getValue("performance.storage.precision", 0) : 0
    
    // Global label visibility (derived from individual monitor label settings)
    property bool showLabels: cpuShowLabel || ramShowLabel || storageShowLabel
    
    // Visual styling - reactive to content size and display mode changes  
    implicitWidth: performanceContent.implicitWidth + 12  // Reduced padding for bar
    implicitHeight: performanceContent.implicitHeight + 8
    radius: 6
    color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
    border.width: 1
    border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
    
    // Layout container
    Item {
        id: performanceContent
        anchors.centerIn: parent
        
        // Horizontal layout (default for bar integration)
        Row {
            id: horizontalLayout
            visible: layout === "horizontal"
            spacing: 6  // Increased spacing for visual separation
            
            // CPU Monitor Container
            Rectangle {
                id: cpuContainer
                implicitWidth: cpuMonitor.visible ? cpuMonitor.implicitWidth + 8 : 28
                implicitHeight: cpuMonitor.visible ? cpuMonitor.implicitHeight + 4 : 22
                radius: 6
                color: cpuMonitor.visible ? (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                // Disabled state indicator
                Text {
                    visible: !cpuMonitor.visible
                    anchors.centerIn: parent
                    text: "🖥️"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                CpuMonitor {
                    id: cpuMonitor
                    anchors.centerIn: parent
                    visible: showCpu
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: cpuShowIcon
                    showText: true
                    showLabel: cpuShowLabel
                    showPercentage: cpuShowPercentage
                    showFrequency: cpuShowFrequency
                    precisionDigits: cpuPrecision
                }
                
                // Parent context menu handler
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: cpuMonitor.visible ? 5 : 15  // Higher z-order when disabled
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
            
            // RAM Monitor Container
            Rectangle {
                id: ramContainer
                implicitWidth: ramMonitor.visible ? ramMonitor.implicitWidth + 8 : 28
                implicitHeight: ramMonitor.visible ? ramMonitor.implicitHeight + 4 : 22
                radius: 6
                color: ramMonitor.visible ? (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                // Disabled state indicator
                Text {
                    visible: !ramMonitor.visible
                    anchors.centerIn: parent
                    text: "🧠"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                RamMonitor {
                    id: ramMonitor
                    anchors.centerIn: parent
                    visible: showRam
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: ramShowIcon
                    showText: true
                    showLabel: ramShowLabel
                    showPercentage: ramShowPercentage
                    showFrequency: ramShowFrequency
                    precisionDigits: ramPrecision
                }
                
                // Parent context menu handler
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: ramMonitor.visible ? 5 : 15  // Higher z-order when disabled
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
            
            // Storage Monitor Container
            Rectangle {
                id: storageContainer
                implicitWidth: storageMonitor.visible ? storageMonitor.implicitWidth + 8 : 28
                implicitHeight: storageMonitor.visible ? storageMonitor.implicitHeight + 4 : 22
                radius: 6
                color: storageMonitor.visible ? (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244") : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                // Disabled state indicator
                Text {
                    visible: !storageMonitor.visible
                    anchors.centerIn: parent
                    text: "💾"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                StorageMonitor {
                    id: storageMonitor
                    anchors.centerIn: parent
                    visible: showStorage
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: storageShowIcon
                    showText: true
                    showLabel: storageShowLabel
                    showPercentage: storageShowPercentage
                    showBytes: storageShowBytes
                    precisionDigits: storagePrecision
                }
                
                // Parent context menu handler
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: storageMonitor.visible ? 5 : 15  // Higher z-order when disabled
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
        }
        
        // Vertical layout
        Column {
            id: verticalLayout
            visible: layout === "vertical"
            spacing: 4
            
            // Header (if labels are enabled)
            Text {
                visible: showLabels
                text: "Performance"
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
            
            // Monitor components
            Rectangle {
                id: cpuContainerVertical
                width: verticalLayout.width
                implicitHeight: cpuMonitorVertical.visible ? cpuMonitorVertical.implicitHeight : 20
                radius: 4
                color: cpuMonitorVertical.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: cpuMonitorVertical.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !cpuMonitorVertical.visible
                    anchors.centerIn: parent
                    text: "🖥️ CPU Disabled"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 9
                    opacity: 0.5
                }
                
                CpuMonitor {
                    id: cpuMonitorVertical
                    visible: showCpu
                    width: parent.width
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: cpuShowIcon
                    showText: true
                    showPercentage: cpuShowPercentage
                    precisionDigits: cpuPrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: cpuMonitorVertical.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            const globalPos = cpuContainerVertical.mapToItem(null, mouse.x, mouse.y)
                            showContextMenu(globalPos.x, globalPos.y)
                        }
                    }
                }
            }
            
            Rectangle {
                id: ramContainerVertical
                width: verticalLayout.width
                implicitHeight: ramMonitorVertical.visible ? ramMonitorVertical.implicitHeight : 20
                radius: 4
                color: ramMonitorVertical.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: ramMonitorVertical.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !ramMonitorVertical.visible
                    anchors.centerIn: parent
                    text: "🧠 RAM Disabled"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 9
                    opacity: 0.5
                }
                
                RamMonitor {
                    id: ramMonitorVertical
                    visible: showRam
                    width: parent.width
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: ramShowIcon
                    showText: true
                    showPercentage: ramShowPercentage
                    precisionDigits: ramPrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: ramMonitorVertical.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            const globalPos = ramContainerVertical.mapToItem(null, mouse.x, mouse.y)
                            showContextMenu(globalPos.x, globalPos.y)
                        }
                    }
                }
            }
            
            Rectangle {
                id: storageContainerVertical
                width: verticalLayout.width
                implicitHeight: storageMonitorVertical.visible ? storageMonitorVertical.implicitHeight : 20
                radius: 4
                color: storageMonitorVertical.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: storageMonitorVertical.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !storageMonitorVertical.visible
                    anchors.centerIn: parent
                    text: "💾 Storage Disabled"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 9
                    opacity: 0.5
                }
                
                StorageMonitor {
                    id: storageMonitorVertical
                    visible: showStorage
                    width: parent.width
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: storageShowIcon
                    showText: true
                    showPercentage: storageShowPercentage
                    precisionDigits: storagePrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: storageMonitorVertical.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            const globalPos = storageContainerVertical.mapToItem(null, mouse.x, mouse.y)
                            showContextMenu(globalPos.x, globalPos.y)
                        }
                    }
                }
            }
        }
        
        // Grid layout (2x2 with flexible arrangement)
        Grid {
            id: gridLayout
            visible: layout === "grid"
            columns: 2
            spacing: 4
            
            // Header spanning two columns
            Text {
                visible: showLabels
                text: "System Performance"
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                width: 120  // Fixed width to avoid circular dependency
            }
            
            // Monitor components in grid
            Rectangle {
                id: cpuContainerGrid
                implicitWidth: cpuMonitorGrid.visible ? cpuMonitorGrid.implicitWidth + 4 : 50
                implicitHeight: cpuMonitorGrid.visible ? cpuMonitorGrid.implicitHeight : 20
                radius: 4
                color: cpuMonitorGrid.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: cpuMonitorGrid.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !cpuMonitorGrid.visible
                    anchors.centerIn: parent
                    text: "🖥️"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                CpuMonitor {
                    id: cpuMonitorGrid
                    anchors.centerIn: parent
                    visible: showCpu
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: cpuShowIcon
                    showText: true
                    showPercentage: cpuShowPercentage
                    precisionDigits: cpuPrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: cpuMonitorGrid.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
            
            Rectangle {
                id: ramContainerGrid
                implicitWidth: ramMonitorGrid.visible ? ramMonitorGrid.implicitWidth + 4 : 50
                implicitHeight: ramMonitorGrid.visible ? ramMonitorGrid.implicitHeight : 20
                radius: 4
                color: ramMonitorGrid.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: ramMonitorGrid.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !ramMonitorGrid.visible
                    anchors.centerIn: parent
                    text: "🧠"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                RamMonitor {
                    id: ramMonitorGrid
                    anchors.centerIn: parent
                    visible: showRam
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: ramShowIcon
                    showText: true
                    showPercentage: ramShowPercentage
                    precisionDigits: ramPrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: ramMonitorGrid.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
            
            Rectangle {
                id: storageContainerGrid
                implicitWidth: storageMonitorGrid.visible ? storageMonitorGrid.implicitWidth + 4 : 50
                implicitHeight: storageMonitorGrid.visible ? storageMonitorGrid.implicitHeight : 20
                radius: 4
                color: storageMonitorGrid.visible ? "transparent" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                border.width: storageMonitorGrid.visible ? 0 : 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                
                Text {
                    visible: !storageMonitorGrid.visible
                    anchors.centerIn: parent
                    text: "💾"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    font.pixelSize: 10
                    opacity: 0.5
                }
                
                StorageMonitor {
                    id: storageMonitorGrid
                    anchors.centerIn: parent
                    visible: showStorage
                    systemMonitorService: performanceWidget.systemMonitorService
                    themeService: performanceWidget.themeService
                    configService: performanceWidget.configService
                    anchorWindow: performanceWidget.barWindow
                    displayMode: displayMode
                    showIcon: storageShowIcon
                    showText: true
                    showPercentage: storageShowPercentage
                    precisionDigits: storagePrecision
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    z: storageMonitorGrid.visible ? 5 : 15
                    
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            menu(performanceWidget.barWindow, mouse.x, mouse.y)
                        }
                    }
                }
            }
            
            // Placeholder for future monitors (Network, Temperature, etc.)
            Rectangle {
                visible: false  // Hidden for now
                width: 60
                height: 20
                radius: 4
                color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                
                Text {
                    anchors.centerIn: parent
                    text: "..."
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    font.family: "Inter"
                    font.pixelSize: 8
                }
            }
        }
        
        // Update layout dimensions
        implicitWidth: {
            if (layout === "horizontal") return horizontalLayout.implicitWidth
            if (layout === "vertical") return Math.max(120, verticalLayout.implicitWidth)
            if (layout === "grid") return gridLayout.implicitWidth
            return 120
        }
        
        implicitHeight: {
            if (layout === "horizontal") return horizontalLayout.implicitHeight
            if (layout === "vertical") return verticalLayout.implicitHeight
            if (layout === "grid") return gridLayout.implicitHeight
            return 24
        }
    }
    
    // Click handler for mode cycling
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        
        onClicked: {
            // Cycle through display modes on click
            if (displayMode === "compact") {
                setDisplayMode("detailed")
            } else if (displayMode === "detailed") {
                setDisplayMode("minimal")
            } else {
                setDisplayMode("compact")
            }
        }
    }
    
    // Public API for configuration
    function setDisplayMode(mode) {
        if (["compact", "detailed", "minimal"].includes(mode)) {
            if (configService) {
                configService.setValue("performance.displayMode", mode)
            }
        }
    }
    
    function setLayout(layoutType) {
        if (["horizontal", "vertical", "grid"].includes(layoutType)) {
            if (configService) {
                configService.setValue("performance.layout", layoutType)
            }
        }
    }
    
    function toggleMonitor(monitor) {
        if (!configService) return
        
        switch (monitor) {
            case "cpu":
                configService.setValue("performance.cpu.enabled", !showCpu)
                break
            case "ram":
                configService.setValue("performance.ram.enabled", !showRam)
                break
            case "storage":
                configService.setValue("performance.storage.enabled", !showStorage)
                break
        }
    }
    
    function setPrecision(monitor, precision) {
        if (!configService) return
        
        const validPrecision = Math.max(0, Math.min(precision, 3)) // Clamp between 0-3
        configService.setValue(`performance.${monitor}.precision`, validPrecision)
    }
    
    function setMonitorDisplay(monitor, property, value) {
        if (!configService) return
        
        const validProperties = ["showIcon", "showLabel", "showPercentage"]
        if (validProperties.includes(property)) {
            configService.setValue(`performance.${monitor}.${property}`, value)
        }
    }
    
    function enableAllMonitors() {
        if (!configService) return
        
        configService.setValue("performance.cpu.enabled", true)
        configService.setValue("performance.ram.enabled", true)
        configService.setValue("performance.storage.enabled", true)
    }
    
    function disableAllMonitors() {
        if (!configService) return
        
        configService.setValue("performance.cpu.enabled", false)
        configService.setValue("performance.ram.enabled", false)
        configService.setValue("performance.storage.enabled", false)
    }
    
    // GraphicalComponent interface: menu() function
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu at path: ${startPath || menuPath}`)
        
        // Use hierarchical context menu
        if (!hierarchicalMenuLoader.active) {
            hierarchicalMenuLoader.active = true
        }
        
        if (hierarchicalMenuLoader.item) {
            const windowToUse = anchorWindow || barWindow || performanceWidget
            const globalPos = performanceWidget.mapToItem(null, x || 0, y || 0)
            hierarchicalMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y, startPath || menuPath)
        }
    }
    
    // Dedicated loader for HierarchicalContextMenu
    Loader {
        id: hierarchicalMenuLoader
        source: "../overlays/HierarchicalContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = performanceWidget.configService
            item.themeService = performanceWidget.themeService
            item.sourceComponent = performanceWidget
            
            item.closed.connect(function() {
                hierarchicalMenuLoader.active = false
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
            ComponentRegistry.registerComponent(componentId, performanceWidget)
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
        // Performance widget initialized
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
}