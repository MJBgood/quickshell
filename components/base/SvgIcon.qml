import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: svgIcon
    
    // Public properties
    property string iconName: ""
    property color iconColor: "#cdd6f4"
    property real iconSize: 16
    property bool enabled: true
    
    // Auto-size to iconSize
    width: iconSize
    height: iconSize
    
    // SVG Image
    Image {
        id: svgImage
        anchors.fill: parent
        source: iconName ? `../../assets/icons/${iconName}.svg` : ""
        sourceSize: Qt.size(iconSize, iconSize)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false // Hidden so ColorOverlay can recolor it
        
        onStatusChanged: {
            if (status === Image.Error) {
                console.warn("SvgIcon: Failed to load icon:", iconName)
            }
        }
    }
    
    // Color overlay to apply iconColor
    ColorOverlay {
        anchors.fill: svgImage
        source: svgImage
        color: enabled ? iconColor : Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0.5)
        visible: svgImage.status === Image.Ready
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Fallback for missing icons - geometric shape
    Rectangle {
        visible: svgImage.status === Image.Error || svgImage.status === Image.Null
        anchors.centerIn: parent
        width: Math.max(4, parent.width * 0.6)
        height: width
        color: iconColor
        radius: width / 2
        opacity: 0.7
    }
}