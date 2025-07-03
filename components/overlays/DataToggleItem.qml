import QtQuick

Rectangle {
    id: toggleItem
    
    property string label: ""
    property string value: ""
    property bool isActive: false
    property var themeService: null
    
    signal clicked()
    
    height: 24
    radius: 6
    color: hoverArea.containsMouse ? 
           (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") :
           "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        spacing: 8
        
        // Status indicator
        Rectangle {
            width: 8
            height: 8
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: isActive ? "#a6e3a1" : "#585b70"
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
        
        // Label
        Text {
            text: label + ":"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
        color: isActive ? 
               (themeService ? themeService.getThemeProperty("colors", "accent") || "#89b4fa" : "#89b4fa") :
               (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
        
        Component.onCompleted: {
            console.log("DataToggleItem value text:", text, "label:", toggleItem.label)
        }
        
        onTextChanged: function(newText) {
            console.log("DataToggleItem value changed:", newText, "for label:", toggleItem.label)
        }
    }
    
    // Hover and click area
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 1  // Ensure it's above the overlay's MouseArea
        onClicked: {
            console.log("DataToggleItem clicked:", label)
            toggleItem.clicked()
        }
    }
    
    // Hover effects
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}