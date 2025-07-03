import Quickshell
import QtQuick
import QtCore
import "." as Overlays

PopupWindow {
    id: contextMenu
    
    // Window properties
    implicitWidth: 200
    implicitHeight: 280  // Fixed height to ensure proper sizing
    visible: false
    color: "transparent"
    
    // Services
    property var configService: null
    property var themeService: null
    
    // Monitor-specific properties
    property string monitorType: "cpu"  // cpu, ram, or storage
    property string monitorName: "CPU"  // Display name
    property string monitorIcon: "💻"   // Display icon
    
    // Reactive config properties that update when config changes
    property bool configEnabled: configService ? configService.getValue("performance." + monitorType + ".enabled", true) : true
    property bool configShowIcon: configService ? configService.getValue("performance." + monitorType + ".showIcon", true) : true
    property bool configShowLabel: configService ? configService.getValue("performance." + monitorType + ".showLabel", false) : false
    property bool configShowPercentage: configService ? configService.getValue("performance." + monitorType + ".showPercentage", true) : true
    property bool configShowFrequency: configService ? configService.getValue("performance." + monitorType + ".showFrequency", false) : false
    property bool configShowBytes: configService ? configService.getValue("performance." + monitorType + ".showBytes", false) : false
    property int configPrecision: configService ? configService.getValue("performance." + monitorType + ".precision", monitorType === "cpu" ? 1 : 0) : 0
    
    // Signals
    signal closed()
    
    // Logging category
    LoggingCategory {
        id: logCategory
        name: "quickshell.performance.monitor.contextmenu"
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
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.All
        margins {
            left: 5
            right: 5
            top: 5
            bottom: 5
        }
    }
    
    // Auto-hide timer for menu dismissal  
    Timer {
        id: autoHideTimer
        interval: 5000  // 5 seconds
        repeat: false
        onTriggered: hide()
    }
    
    // Track mouse hover to reset auto-hide timer
    onVisibleChanged: {
        if (visible) {
            autoHideTimer.start()
        } else {
            autoHideTimer.stop()
        }
    }
    
    // Main menu container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        z: 1
        
        // Reset auto-hide timer on mouse hover
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: autoHideTimer.stop()
            onExited: autoHideTimer.start()
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            // Header
            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    spacing: 8
                    
                    Text {
                        text: monitorIcon
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: monitorName + " Monitor"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // Enable/Disable
            Overlays.MonitorMenuItem {
                width: parent.width
                text: "Enable " + monitorName
                checkable: true
                checked: configEnabled
                themeService: contextMenu.themeService
                onClicked: toggleConfig("enabled")
            }
            
            // Show Icon
            Overlays.MonitorMenuItem {
                width: parent.width
                text: "Show Icon"
                checkable: true
                checked: configShowIcon
                themeService: contextMenu.themeService
                onClicked: toggleConfig("showIcon")
            }
            
            // Show Label
            Overlays.MonitorMenuItem {
                width: parent.width
                text: "Show Label"
                checkable: true
                checked: configShowLabel
                themeService: contextMenu.themeService
                onClicked: toggleConfig("showLabel")
            }
            
            // Show Percentage
            Overlays.MonitorMenuItem {
                width: parent.width
                text: "Show Percentage"
                checkable: true
                checked: configShowPercentage
                themeService: contextMenu.themeService
                onClicked: toggleConfig("showPercentage")
            }
            
            // Show Frequency (CPU and RAM only)
            Overlays.MonitorMenuItem {
                visible: monitorType === "cpu" || monitorType === "ram"
                width: parent.width
                text: "Show Frequency"
                checkable: true
                checked: configShowFrequency
                themeService: contextMenu.themeService
                onClicked: toggleConfig("showFrequency")
            }
            
            // Show Bytes (Storage only)
            Overlays.MonitorMenuItem {
                visible: monitorType === "storage"
                width: parent.width
                text: "Show Bytes"
                checkable: true
                checked: configShowBytes
                themeService: contextMenu.themeService
                onClicked: toggleConfig("showBytes")
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // Precision submenu
            Overlays.MonitorMenuItem {
                width: parent.width
                text: "Precision: " + configPrecision + " decimal" + (configPrecision === 1 ? "" : "s")
                themeService: contextMenu.themeService
                onClicked: cyclePrecision()
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
        configPrecision = configService.getValue("performance." + monitorType + ".precision", monitorType === "cpu" ? 1 : 0)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "performance." + monitorType + "." + key
        const currentValue = configService.getValue(configKey, key === "showLabel" ? false : true)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
        
        updateConfigProperties()  // Update reactive properties
        
        console.log(logCategory, monitorName, key, "set to", newValue)
    }
    
    function cyclePrecision() {
        if (!configService) return
        
        const configKey = "performance." + monitorType + ".precision"
        const currentPrecision = configService.getValue(configKey, monitorType === "cpu" ? 1 : 0)
        const newPrecision = (currentPrecision + 1) % 4  // Cycle through 0, 1, 2, 3
        
        configService.setValue(configKey, newPrecision)
        configService.saveConfig()
        
        updateConfigProperties()  // Update reactive properties
        
        console.log(logCategory, monitorName, "precision set to", newPrecision)
    }
    
    // Functions
    function show(anchorWindow, x, y) {
        console.log(logCategory, "Show called with window:", anchorWindow, "position:", x, y)
        
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            // Position the popup near the click location but ensure it's visible
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            // Calculate position to ensure popup stays on screen
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 10)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 10)
            
            // Ensure minimum margins from screen edges
            popupX = Math.max(10, popupX)
            popupY = Math.max(10, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
            
            console.log(logCategory, "Final popup position:", popupX, popupY)
        }
        visible = true
    }
    
    function hide() {
        visible = false
        closed()
    }
    
    // Update config properties when configService changes
    onConfigServiceChanged: updateConfigProperties()
    
    // Initialize config properties when component completes
    Component.onCompleted: updateConfigProperties()
}