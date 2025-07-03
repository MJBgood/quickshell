import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: menuItem
    
    property string text: ""
    property bool enabled: true
    property var themeService: null
    
    signal clicked()
    
    height: 24
    color: mouseArea.containsMouse && enabled ? 
           (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") :
           "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        text: menuItem.text
        font.pixelSize: 11
        color: enabled ?
               (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") :
               (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
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