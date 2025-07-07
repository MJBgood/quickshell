import QtQuick
import "../../services"
import "../base"

Rectangle {
    id: ramMonitor
    
    // GraphicalComponent interface implementation
    property string componentId: "ram_widget"
    property string parentComponentId: "widget_container"
    property var childComponentIds: []
    property string menuPath: "widgets.ram"
    
    // Services
    property var configService: ConfigService
    property var systemMonitorService: null
    
    implicitWidth: configService ? configService.scaled(60) : 60
    implicitHeight: configService ? configService.scaled(24) : 24
    
    color: "transparent"
    
    // RAM usage display
    Row {
        anchors.centerIn: parent
        spacing: configService ? configService.scaledMarginSmall() : 4
        
        Text {
            text: "🧠"
            font.pixelSize: configService ? configService.scaledFontMedium() : 12
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: getRamUsage()
            font.pixelSize: configService ? configService.scaledFontNormal() : 10
            font.weight: Font.Medium
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    function getRamUsage() {
        // Placeholder - in real implementation would get from systemMonitorService
        return "67%"
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu at path: ${startPath || menuPath}`)
        
        // Use parent's menu with our specific path
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            parent.menu(anchorWindow, x, y, startPath || menuPath)
        }
    }
    
    function list_children() {
        return []  // RAM widget has no children
    }
    
    function get_parent() {
        if (!parentComponentId) return null
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null  // RAM widget has no children
    }
    
    function registerComponent() {
        if (componentId) {
            ComponentRegistry.registerComponent(componentId, ramMonitor)
            console.log(`[${componentId}] Registered component with hierarchy: parent=${parentComponentId}`)
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
        
        // Initialize scaling if not already done
        if (configService && !configService.initialized) {
            configService.initializeScaling()
        }
        
        console.log("RamMonitor widget loaded with scaling support")
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
}