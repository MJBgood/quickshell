// HierarchicalDemo.qml - Working example demonstrating the hierarchical component interface
import Quickshell
import Quickshell.Widgets
import QtQuick
import "../components/base"
import "../components/overlays"

ShellRoot {
    id: demo
    
    // Demo window to showcase the hierarchical navigation
    PanelWindow {
        id: demoWindow
        
        screen: Quickshell.screens[0]
        anchors {
            top: true
            left: true
            right: true
        }
        
        implicitHeight: 60
        color: "#313244"
        
        Row {
            anchors.centerIn: parent
            spacing: 20
            
            // Performance Component Demo
            Rectangle {
                id: performanceDemo
                width: 200
                height: 40
                radius: 8
                color: "#45475a"
                border.width: 1
                border.color: "#585b70"
                
                // GraphicalComponent interface implementation
                property string componentId: "performance"
                property string parentComponentId: "system"
                property var childComponentIds: ["cpu", "ram", "storage"]
                property string menuPath: "performance"
                
                Text {
                    anchors.centerIn: parent
                    text: "📊 Performance Monitor"
                    color: "#cdd6f4"
                    font.pixelSize: 12
                }
                
                // Interface methods
                function menu(anchorWindow, x, y, startPath) {
                    console.log(`[${componentId}] Opening hierarchical menu`)
                    
                    menuLoader.active = true
                    if (menuLoader.item) {
                        const windowToUse = anchorWindow || demoWindow
                        const globalPos = performanceDemo.mapToItem(null, x || 0, y || 0)
                        menuLoader.item.show(windowToUse, globalPos.x, globalPos.y, startPath || menuPath)
                    }
                }
                
                function list_children() {
                    return childComponentIds.map(id => ComponentRegistry.getComponent(id)).filter(comp => comp !== null)
                }
                
                function get_parent() {
                    return ComponentRegistry.getComponent(parentComponentId)
                }
                
                function get_child(id) {
                    return ComponentRegistry.getComponent(id)
                }
                
                // Menu loader
                Loader {
                    id: menuLoader
                    source: "../components/overlays/HierarchicalContextMenu.qml"
                    active: false
                    
                    onLoaded: {
                        item.configService = Qt.binding(() => ConfigPersistence)
                        item.themeService = null // Would be actual theme service in real implementation
                        item.sourceComponent = performanceDemo
                        
                        item.closed.connect(function() {
                            menuLoader.active = false
                        })
                    }
                }
                
                // Right-click to show menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            parent.menu(demoWindow, mouse.x, mouse.y)
                        }
                    }
                }
                
                // Component registration
                function registerComponent() {
                    ComponentRegistry.registerComponent(componentId, performanceDemo)
                    console.log(`[${componentId}] Registered with hierarchy`)
                }
                
                Component.onCompleted: {
                    registerComponent()
                }
            }
            
            // CPU Component Demo (child of Performance)
            Rectangle {
                id: cpuDemo
                width: 150
                height: 40
                radius: 8
                color: "#49414e"
                border.width: 1
                border.color: "#585b70"
                
                // GraphicalComponent interface implementation
                property string componentId: "cpu"
                property string parentComponentId: "performance"
                property var childComponentIds: []
                property string menuPath: "cpu"
                
                Text {
                    anchors.centerIn: parent
                    text: "💻 CPU Monitor"
                    color: "#cdd6f4"
                    font.pixelSize: 11
                }
                
                // Interface methods
                function menu(anchorWindow, x, y, startPath) {
                    console.log(`[${componentId}] Opening hierarchical menu`)
                    
                    // CPU uses parent's menu with its specific path
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
                
                // Right-click to show menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            parent.menu(demoWindow, mouse.x, mouse.y)
                        }
                    }
                }
                
                function registerComponent() {
                    ComponentRegistry.registerComponent(componentId, cpuDemo)
                    console.log(`[${componentId}] Registered with hierarchy`)
                }
                
                Component.onCompleted: {
                    registerComponent()
                }
            }
            
            // RAM Component Demo (child of Performance)
            Rectangle {
                id: ramDemo
                width: 150
                height: 40
                radius: 8
                color: "#49414e"
                border.width: 1
                border.color: "#585b70"
                
                // GraphicalComponent interface implementation
                property string componentId: "ram"
                property string parentComponentId: "performance"
                property var childComponentIds: []
                property string menuPath: "ram"
                
                Text {
                    anchors.centerIn: parent
                    text: "🧠 RAM Monitor"
                    color: "#cdd6f4"
                    font.pixelSize: 11
                }
                
                // Interface methods (same pattern as CPU)
                function menu(anchorWindow, x, y, startPath) {
                    const parent = get_parent()
                    if (parent && typeof parent.menu === 'function') {
                        parent.menu(anchorWindow, x, y, startPath || menuPath)
                    }
                }
                
                function list_children() { return [] }
                function get_parent() { return ComponentRegistry.getComponent(parentComponentId) }
                function get_child(id) { return null }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            mouse.accepted = true
                            parent.menu(demoWindow, mouse.x, mouse.y)
                        }
                    }
                }
                
                function registerComponent() {
                    ComponentRegistry.registerComponent(componentId, ramDemo)
                }
                
                Component.onCompleted: {
                    registerComponent()
                }
            }
        }
        
        // Instructions
        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            text: "Right-click any component to open hierarchical context menu"
            color: "#bac2de"
            font.pixelSize: 10
        }
    }
    
    // Test the hierarchy on startup
    Component.onCompleted: {
        // Wait a moment for components to register
        Qt.callLater(function() {
            console.log("=== Hierarchical Component Interface Demo ===")
            
            // Test component registry
            ComponentRegistry.logRegistry()
            ComponentRegistry.validateHierarchy()
            
            // Test navigation
            const performance = ComponentRegistry.getComponent("performance")
            const cpu = ComponentRegistry.getComponent("cpu")
            
            if (performance) {
                console.log("✓ Performance component found")
                console.log("  Children:", performance.list_children().map(c => c.componentId))
            }
            
            if (cpu) {
                console.log("✓ CPU component found")
                console.log("  Parent:", cpu.get_parent()?.componentId || "None")
            }
            
            // Test configuration persistence
            console.log("=== Configuration Persistence Demo ===")
            console.log("CPU enabled:", ConfigPersistence.getSetting("cpu", "enabled", true))
            console.log("Performance layout:", ConfigPersistence.getSetting("performance", "layout", "horizontal"))
            
            // Test setting a value
            ConfigPersistence.setSetting("cpu", "precision", 2)
            console.log("Updated CPU precision to:", ConfigPersistence.getSetting("cpu", "precision", 1))
            
            console.log("=== Demo Ready ===")
            console.log("Right-click components to test hierarchical navigation!")
        })
    }
}