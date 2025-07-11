import QtQuick
import "../../services"

Text {
    id: styledText
    
    // Animation properties
    property bool animate: false
    property string animateProp: "scale"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: 300
    
    // Base styling following caelestia pattern
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: ConfigService.getThemeProperty("colors", "onSurface") || "#cdd6f4"
    font.family: ConfigService.getThemeProperty("typography", "fontFamily") || "Inter, sans-serif"
    font.pointSize: ConfigService.getThemeProperty("typography", "fontSize") || 12
    
    // Color animations
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
    
    // Text animation behavior (caelestia pattern)
    Behavior on text {
        enabled: styledText.animate
        
        SequentialAnimation {
            NumberAnimation {
                target: styledText
                property: styledText.animateProp
                to: styledText.animateFrom
                duration: styledText.animateDuration / 2
                easing.type: Easing.OutCubic
            }
            PropertyAction {}
            NumberAnimation {
                target: styledText
                property: styledText.animateProp
                to: styledText.animateTo
                duration: styledText.animateDuration / 2
                easing.type: Easing.OutCubic
            }
        }
    }
}