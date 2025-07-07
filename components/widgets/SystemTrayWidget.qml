import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../../services"
import "../base"

Rectangle {
    id: systemTrayWidget
    
    // Services
    property var configService: ConfigService
    
    // Configuration properties
    property bool enabled: configService ? configService.getValue("widgets.systray.enabled", true) : true
    property int iconSize: configService ? configService.getValue("widgets.systray.iconSize", 20) : 20
    property int spacing: configService ? configService.getValue("widgets.systray.spacing", 4) : 4
    property bool showTooltips: configService ? configService.getValue("widgets.systray.showTooltips", true) : true
    property string layout: configService ? configService.getValue("widgets.systray.layout", "horizontal") : "horizontal"
    
    // Visual properties
    property bool alwaysShow: configService ? configService.getValue("widgets.systray.alwaysShow", true) : true
    property bool showEmpty: configService ? configService.getValue("widgets.systray.showEmpty", true) : true
    visible: enabled && (alwaysShow || (SystemTray.items ? SystemTray.items.count > 0 : false))
    color: "transparent"
    
    // Auto-size based on content and layout  
    implicitWidth: Math.max(iconSize, layout === "horizontal" ? systrayFlow.implicitWidth : iconSize)
    implicitHeight: Math.max(iconSize, layout === "vertical" ? systrayFlow.implicitHeight : iconSize)
    width: implicitWidth
    height: implicitHeight
    
    // Signals
    signal itemClicked(var item)
    signal itemRightClicked(var item)
    signal menuRequested(var item, var anchorItem)
    
    Flow {
        id: systrayFlow
        anchors.fill: parent
        spacing: systemTrayWidget.spacing
        flow: layout === "horizontal" ? Flow.LeftToRight : Flow.TopToBottom
        
        Repeater {
            model: SystemTray.items
            
            delegate: Rectangle {
                id: systrayItem
                width: iconSize
                height: iconSize
                color: itemMouse.containsMouse ? 
                       (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                       "transparent"
                radius: configService ? configService.scaled(4) : 4
                
                // Status indicator border
                border.color: {
                    if (!modelData) return "transparent"
                    switch (modelData.status) {
                        case SystemTray.Status.Active: return "#a6e3a1"
                        case SystemTray.Status.NeedsAttention: return "#f38ba8"
                        case SystemTray.Status.Passive: return "transparent"
                        default: return "transparent"
                    }
                }
                border.width: border.color !== "transparent" ? 1 : 0
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
                
                // Tray icon
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: Math.max(8, iconSize - 4)
                    height: Math.max(8, iconSize - 4)
                    source: modelData ? modelData.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                    asynchronous: true
                    
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.warn("SystemTray: Failed to load icon for", modelData ? modelData.title : "unknown item")
                        }
                    }
                    
                    // Fallback for missing icons
                    Rectangle {
                        visible: trayIcon.status === Image.Error || trayIcon.status === Image.Null
                        anchors.fill: parent
                        color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        radius: 2
                        
                        Text {
                            anchors.centerIn: parent
                            text: "?"
                            font.pixelSize: Math.max(8, parent.height * 0.6)
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.weight: Font.Bold
                        }
                    }
                }
                
                // Mouse interaction
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            console.log("SystemTray: Left clicked item:", modelData ? modelData.title : "unknown")
                            itemClicked(modelData)
                            
                            // Handle activation based on item properties
                            if (modelData) {
                                if (modelData.onlyMenu && modelData.hasMenu) {
                                    // Item only offers menu
                                    menuRequested(modelData, systrayItem)
                                } else {
                                    // Try to activate the item (this may not be available in Quickshell API)
                                    console.log("SystemTray: Activating item:", modelData.title)
                                    // Note: The activate() method might not be available - check Quickshell docs
                                }
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            console.log("SystemTray: Right clicked item:", modelData ? modelData.title : "unknown")
                            itemRightClicked(modelData)
                            
                            if (modelData && modelData.hasMenu) {
                                menuRequested(modelData, systrayItem)
                            }
                        }
                    }
                    
                    // Tooltip
                    ToolTip {
                        visible: showTooltips && itemMouse.containsMouse && (tooltipTitle.length > 0 || tooltipText.length > 0)
                        delay: configService ? configService.hoverDelay : 800
                        
                        property string tooltipTitle: modelData ? (modelData.tooltipTitle || modelData.title || "") : ""
                        property string tooltipText: modelData ? (modelData.tooltipDescription || "") : ""
                        
                        text: {
                            if (tooltipTitle.length > 0 && tooltipText.length > 0) {
                                return tooltipTitle + "\n" + tooltipText
                            } else if (tooltipTitle.length > 0) {
                                return tooltipTitle
                            } else if (tooltipText.length > 0) {
                                return tooltipText
                            } else {
                                return ""
                            }
                        }
                        
                        background: Rectangle {
                            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            border.width: 1
                            radius: configService ? configService.scaled(6) : 6
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: configService ? configService.scaledFontSmall() : 10
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                
                // Visual feedback for NeedsAttention status
                Rectangle {
                    visible: modelData && modelData.status === SystemTray.Status.NeedsAttention
                    width: 6
                    height: 6
                    radius: 3
                    color: "#f38ba8"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 1
                    
                    SequentialAnimation {
                        running: parent.visible
                        loops: Animation.Infinite
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            from: 1.0
                            to: 0.3
                            duration: 1000
                        }
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            from: 0.3
                            to: 1.0
                            duration: 1000
                        }
                    }
                }
            }
        }
        
        // Empty state indicator - Always visible when showEmpty is true
        Rectangle {
            visible: showEmpty && (!SystemTray.items || SystemTray.items.count === 0)
            width: iconSize
            height: iconSize
            color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            border.width: 1
            radius: configService ? configService.scaled(4) : 4
            opacity: 0.8
            
            Text {
                anchors.centerIn: parent
                text: "📱"
                font.pixelSize: Math.max(8, parent.height * 0.6)
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                opacity: 0.8
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        console.log("SystemTray: Empty tray right-clicked for configuration")
                        if (!systrayMenuLoader.active) {
                            systrayMenuLoader.active = true
                        }
                        
                        if (systrayMenuLoader.item) {
                            const globalPos = mapToItem(null, mouse.x, mouse.y)
                            WindowUtils.showPopup(systrayMenuLoader.item, parent, globalPos.x, globalPos.y)
                        }
                    }
                }
            }
        }
    }
    
    // Context menu for the widget itself (not individual items)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1  // Behind the individual item mouse areas
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // Show system tray widget configuration menu
                console.log("SystemTray: Widget right-clicked for configuration")
                if (!systrayMenuLoader.active) {
                    systrayMenuLoader.active = true
                }
                
                if (systrayMenuLoader.item) {
                    const globalPos = systemTrayWidget.mapToItem(null, mouse.x, mouse.y)
                    WindowUtils.showPopup(systrayMenuLoader.item, systemTrayWidget, globalPos.x, globalPos.y)
                }
            }
        }
    }
    
    // Context menu loader
    Loader {
        id: systrayMenuLoader
        source: "../../components/overlays/SystemTrayContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = systemTrayWidget.configService
            
            item.closed.connect(function() {
                systrayMenuLoader.active = false
            })
        }
    }
    
    // Debug information
    Component.onCompleted: {
        console.log("SystemTrayWidget: Initialized with", SystemTray.items ? SystemTray.items.values.length : 0, "items")
        console.log("SystemTrayWidget: Configuration - enabled:", enabled, "iconSize:", iconSize, "spacing:", spacing)
        console.log("SystemTrayWidget: visible:", visible, "width:", width, "height:", height)
        console.log("SystemTrayWidget: SystemTray available:", !!SystemTray)
        console.log("SystemTrayWidget: SystemTray.items available:", !!SystemTray.items)
    }
    
    // Use reactive binding to monitor changes
    property int itemCount: SystemTray.items ? SystemTray.items.values.length : 0
    onItemCountChanged: {
        console.log("SystemTray: Item count changed to", itemCount)
    }
}