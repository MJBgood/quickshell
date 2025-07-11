import QtQuick
import "../../services"

Text {
    id: materialIcon
    
    // Material icon properties
    property real fill: 0
    property int grade: ConfigService.getThemeProperty("colors", "mode") === "light" ? 0 : -25
    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: 300
    
    // Base styling following caelestia pattern
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: ConfigService.getThemeProperty("colors", "onSurface") || "#cdd6f4"
    font.family: "Material Symbols Rounded" // Google Material Symbols font
    font.pointSize: 16
    
    // Material variable font axes (like caelestia)
    font.variableAxes: ({
        FILL: fill.toFixed(1),
        GRAD: grade,
        opsz: fontInfo.pixelSize,
        wght: fontInfo.weight
    })
    
    // Color animations
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    // Text animation behavior (caelestia pattern)
    Behavior on text {
        enabled: materialIcon.animate
        
        SequentialAnimation {
            NumberAnimation {
                target: materialIcon
                property: materialIcon.animateProp
                to: materialIcon.animateFrom
                duration: materialIcon.animateDuration / 2
                easing.type: Easing.OutCubic
            }
            PropertyAction {}
            NumberAnimation {
                target: materialIcon
                property: materialIcon.animateProp
                to: materialIcon.animateTo
                duration: materialIcon.animateDuration / 2
                easing.type: Easing.OutCubic
            }
        }
    }
}