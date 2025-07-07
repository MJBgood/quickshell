import QtQuick
import "../../services"

Rectangle {
    id: displayItem
    
    property string label: ""
    property string value: ""
    property var configService: ConfigService
    
    height: 24
    radius: 6
    color: "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        spacing: 8
        
        // Info indicator
        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: configService ? configService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
        }
        
        // Label
        Text {
            text: label + ":"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    // Value (right-aligned)
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 8
        text: value
        font.pixelSize: 11
        font.family: "monospace"
        font.weight: Font.DemiBold
        color: configService ? configService.getThemeProperty("colors", "accent") || "#89b4fa" : "#89b4fa"
    }
}