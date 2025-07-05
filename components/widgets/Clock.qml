import QtQuick
import "../../services"

Rectangle {
    id: clock
    
    // Services
    property var configService: null
    property var themeService: null
    
    implicitWidth: 80
    implicitHeight: 24
    
    color: "transparent"
    
    // Clock display
    Text {
        anchors.centerIn: parent
        text: getCurrentTime()
        font.pixelSize: 11
        font.weight: Font.Medium
        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
    }
    
    // Update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.children[0].text = getCurrentTime()
    }
    
    function getCurrentTime() {
        const now = new Date()
        return Qt.formatTime(now, "hh:mm")
    }
    
    Component.onCompleted: {
        console.log("Clock widget loaded")
    }
}