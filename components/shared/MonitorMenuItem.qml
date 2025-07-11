import QtQuick

Rectangle {
    id: menuItem
    
    property string text: ""
    property bool enabled: true
    property bool checkable: false
    property bool checked: false
    property var configService: ConfigService
    
    signal clicked()
    
    height: 28
    color: mouseArea.containsMouse && enabled ? 
           (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") :
           "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        spacing: 8
        
        // Checkmark for checkable items
        Text {
            text: checkable ? (checked ? "✓" : "✗") : ""
            font.pixelSize: 11
            color: checked ? 
                   (configService ? configService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                   (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            anchors.verticalCenter: parent.verticalCenter
            visible: checkable
        }
        
        Text {
            text: menuItem.text
            font.pixelSize: 11
            color: enabled ?
                   (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") :
                   (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: menuItem.enabled
        
        onClicked: {
            if (menuItem.enabled) {
                if (menuItem.checkable) {
                    menuItem.checked = !menuItem.checked
                }
                menuItem.clicked()
            }
        }
    }
    
    Behavior on color {
        ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
}