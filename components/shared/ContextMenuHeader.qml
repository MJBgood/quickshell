import QtQuick

Rectangle {
    id: header
    
    property string title: ""
    property var configService: null
    
    width: parent.width
    height: 28
    color: "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 8
        text: title
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
    }
}