import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"

Rectangle {
    id: menuItem
    
    property string text: ""
    property bool enabled: true
    property var configService: ConfigService
    
    signal clicked()
    
    height: 24
    color: mouseArea.containsMouse && enabled ? 
           (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") :
           "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        text: menuItem.text
        font.pixelSize: 11
        color: enabled ?
               (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") :
               (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: menuItem.enabled
        
        onClicked: {
            if (menuItem.enabled) {
                menuItem.clicked()
            }
        }
    }
    
    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
}