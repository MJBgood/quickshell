import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../shared"

PopupWindow {
    id: audioContextMenu
    
    // Window properties
    implicitWidth: 200
    implicitHeight: Math.min(300, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Properties
    property var audioService: null
    property var configService: ConfigService
    
    // Anchor configuration
    anchor {
        window: null
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins {
            left: 8
            right: 8
            top: 8
            bottom: 8
        }
    }
    
    // Focus grab for dismissing when clicking outside
    HyprlandFocusGrab {
        id: focusGrab
        windows: [audioContextMenu]
        onCleared: hide()
    }
    
    // Main container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        property real contentHeight: scrollView.contentHeight
        
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            Column {
                id: column
                width: scrollView.availableWidth
                spacing: 12
                
                // Header
                Text {
                    text: "Audio Settings"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                // Device info
                Text {
                    text: audioService ? `Device: ${audioService.deviceName}` : "Device: Unknown"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: configService ? configService.getThemeProperty("colors", "textAlt") || "#a6adc8" : "#a6adc8"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                
                // Volume control
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Volume:"
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Slider {
                        id: volumeSlider
                        width: parent.width
                        height: 20
                        from: 0.0
                        to: 1.0
                        value: audioService ? audioService.volume : 0.0
                        
                        onValueChanged: {
                            if (audioService && Math.abs(value - audioService.volume) > 0.01) {
                                audioService.setVolume(value)
                            }
                        }
                    }
                }
                
                // Mute toggle
                CheckBox {
                    id: muteCheckbox
                    text: "Mute"
                    checked: audioService ? audioService.muted : false
                    font.family: "Inter"
                    font.pixelSize: 12
                    
                    onToggled: {
                        if (audioService) {
                            audioService.toggleMute()
                        }
                    }
                }
                
                // Quick volume presets
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Quick Settings:"
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#a6adc8" : "#a6adc8"
                    }
                    
                    Row {
                        width: parent.width
                        spacing: 4
                        
                        Button {
                            text: "25%"
                            font.pixelSize: 10
                            implicitWidth: 35
                            implicitHeight: 20
                            onClicked: audioService?.setVolume(0.25)
                        }
                        
                        Button {
                            text: "50%"
                            font.pixelSize: 10
                            implicitWidth: 35
                            implicitHeight: 20
                            onClicked: audioService?.setVolume(0.50)
                        }
                        
                        Button {
                            text: "75%"
                            font.pixelSize: 10
                            implicitWidth: 35
                            implicitHeight: 20
                            onClicked: audioService?.setVolume(0.75)
                        }
                        
                        Button {
                            text: "100%"
                            font.pixelSize: 10
                            implicitWidth: 40
                            implicitHeight: 20
                            onClicked: audioService?.setVolume(1.0)
                        }
                    }
                }
            }
        }
    }
    
    // Functions
    function show(anchorWindow, x, y) {
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 20)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 20)
            
            popupX = Math.max(20, popupX)
            popupY = Math.max(20, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
        }
        
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
    }
}