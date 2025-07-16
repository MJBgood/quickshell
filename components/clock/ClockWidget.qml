import QtQuick
import Quickshell
import "../shared"
import "../shared"

Rectangle {
    id: clock
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null  // Should be set to the PanelWindow (bar)
    
    // Entity ID for configuration
    property string entityId: "clockWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "clock"
    property string parentComponentId: "system"
    property var childComponentIds: []
    property string menuPath: "system.clock"
    
    implicitWidth: clockText.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12)
    implicitHeight: configService ? configService.getWidgetHeight(entityId, clockText.implicitHeight) : clockText.implicitHeight
    
    color: configService ? configService.getEntityStyle(entityId, "backgroundColor", "auto", "transparent") : "transparent"
    
    // Current time properties
    property string separator: configService ? configService.getEntityProperty(entityId, "separator", "|") : "|"
    property bool showDate: configService ? configService.getEntityProperty(entityId, "showDate", true) : true
    property string timeFormat: configService ? configService.getEntityProperty(entityId, "timeFormat", "HH:mm") : "HH:mm"
    property string dateFormat: configService ? configService.getEntityProperty(entityId, "dateFormat", "yyyy-MM-dd") : "yyyy-MM-dd"
    
    // System clock for proper time handling
    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }
    
    // Clock display
    Text {
        id: clockText
        anchors.centerIn: parent
        text: {
            if (showDate) {
                return Qt.formatDateTime(systemClock.date, timeFormat) + " " + separator + " " + Qt.formatDateTime(systemClock.date, dateFormat)
            } else {
                return Qt.formatDateTime(systemClock.date, timeFormat)
            }
        }
        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
        font.weight: Font.Medium
        color: configService ? configService.getEntityStyle(entityId, "textColor", "auto", configService.getThemeProperty("colors", "text") || "#cdd6f4") : "#cdd6f4"
    }
    
    // Clock menu interaction
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                showClockMenu(mouse.x, mouse.y)
                mouse.accepted = true
            } else if (mouse.button === Qt.LeftButton) {
                mouse.accepted = true  
            }
        }
    }
    
    // Clock context menu loader
    Loader {
        id: clockMenuLoader
        source: "./ClockContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = clock.configService
            
            item.closed.connect(function() {
                clockMenuLoader.active = false
            })
        }
    }
    
    
    // Clock menu functions
    function showClockMenu(x, y) {
        if (!clockMenuLoader.active) {
            clockMenuLoader.active = true
        }
        
        if (clockMenuLoader.item) {
            const globalPos = mapToItem(null, x, y)
            
            if (anchorWindow) {
                clockMenuLoader.item.show(anchorWindow, globalPos.x, globalPos.y)
            } else {
                console.error("Clock: No anchorWindow provided - clock menu cannot be shown")
            }
        }
    }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        showClockMenu(width / 2, height / 2)
    }
    
    function getParent() {
        // Return parent component reference if available
        return null
    }
    
    function getChildren() {
        // Return child components array
        return []
    }
    
    function navigateToParent() {
        // Navigate to parent menu if available
        if (getParent()) {
            getParent().menu()
        }
    }
    
    function navigateToChild(childId) {
        // Navigate to child menu - no children for clock
        console.log("Clock has no child components")
    }
    
    Component.onCompleted: {
        console.log("Clock widget loaded with SystemClock")
    }
}