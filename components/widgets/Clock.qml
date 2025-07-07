import QtQuick
import "../../services"

Rectangle {
    id: clock
    
    // Services
    property var configService: ConfigService
    
    // GraphicalComponent interface implementation
    property string componentId: "clock"
    property string parentComponentId: "system"
    property var childComponentIds: []
    property string menuPath: "system.clock"
    
    implicitWidth: configService ? configService.scaled(80) : 80
    implicitHeight: configService ? configService.scaledFontMedium() + configService.scaledMarginNormal() : 24
    
    color: "transparent"
    
    // Current time state
    property string currentTime: getCurrentTime()
    
    // Clock display
    Text {
        id: clockText
        anchors.centerIn: parent
        text: clock.currentTime
        font.pixelSize: configService ? configService.scaledFontMedium() : 12
        font.weight: Font.Medium
        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
    }
    
    // Update timer
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clock.currentTime = getCurrentTime()
        }
    }
    
    function getCurrentTime() {
        try {
            const now = new Date()
            // Use simple string formatting that's more reliable in QML
            let hours = now.getHours()
            let minutes = now.getMinutes()
            
            // Format with leading zeros
            if (hours < 10) hours = "0" + hours
            if (minutes < 10) minutes = "0" + minutes
            
            return hours + ":" + minutes
        } catch (error) {
            console.error("Clock: Error getting current time:", error)
            return "--:--"
        }
    }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        // Clock widget has no menu implementation yet
        console.log("Clock menu not implemented yet")
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
        console.log("Clock widget loaded, initial time:", getCurrentTime())
        console.log("Clock widget configService:", configService)
        console.log("Clock widget dimensions:", implicitWidth, "x", implicitHeight)
    }
}