import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"

Item {
    id: root
    
    // Services
    property var configService: ConfigService
    
    // Visibility control
    property bool sessionVisible: false
    
    visible: width > 0
    implicitWidth: 0
    implicitHeight: content.implicitHeight
    
    states: State {
        name: "visible"
        when: root.sessionVisible
        
        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }
    
    transitions: [
        Transition {
            from: ""
            to: "visible"
            
            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: 300
                easing.type: Easing.OutCubic
            }
        },
        Transition {
            from: "visible"
            to: ""
            
            NumberAnimation {
                target: root
                property: "implicitWidth"
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    ]
    
    Column {
        id: content
        
        padding: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 24
        
        SessionButton {
            id: logout
            
            icon: "🚪"
            label: "Log Out"
            command: ["loginctl", "terminate-user", ""]
            
            KeyNavigation.down: shutdown
            
            Component.onCompleted: {
                if (root.sessionVisible) {
                    focus = true
                }
            }
        }
        
        SessionButton {
            id: shutdown
            
            icon: "⚡"
            label: "Shut Down"
            command: ["systemctl", "poweroff"]
            
            KeyNavigation.up: logout
            KeyNavigation.down: hibernate
        }
        
        // Visual separator with animated icon
        Rectangle {
            width: 64
            height: 64
            radius: 32
            color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "⚡"
                font.pixelSize: 32
                color: configService ? configService.getThemeProperty("colors", "accent") || "#cba6f7" : "#cba6f7"
                
                SequentialAnimation on scale {
                    running: root.sessionVisible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.1; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }
        }
        
        SessionButton {
            id: hibernate
            
            icon: "💤"
            label: "Hibernate"
            command: ["systemctl", "hibernate"]
            
            KeyNavigation.up: shutdown
            KeyNavigation.down: reboot
        }
        
        SessionButton {
            id: reboot
            
            icon: "🔄"
            label: "Restart"
            command: ["systemctl", "reboot"]
            
            KeyNavigation.up: hibernate
        }
    }
    
    // Session button component
    component SessionButton: Rectangle {
        id: button
        
        required property string icon
        required property string label
        required property list<string> command
        
        implicitWidth: 64
        implicitHeight: 64
        
        radius: 16
        color: button.activeFocus ? 
            (configService ? configService.getThemeProperty("colors", "accent") || "#cba6f7" : "#cba6f7") :
            (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244")
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
        border.width: button.activeFocus ? 2 : 1
        
        Keys.onEnterPressed: executeCommand()
        Keys.onReturnPressed: executeCommand()
        Keys.onEscapePressed: root.sessionVisible = false
        
        function executeCommand() {
            console.log("[SessionOverlay] Executing command:", command)
            Quickshell.execDetached(command)
            root.sessionVisible = false
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 4
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.icon
                font.pixelSize: 24
                color: button.activeFocus ? 
                    (configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e") :
                    (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.label
                font.family: "Inter"
                font.pixelSize: 8
                font.weight: Font.Medium
                color: button.activeFocus ? 
                    (configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e") :
                    (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: button.executeCommand()
            onEntered: button.focus = true
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on scale {
            NumberAnimation { duration: 100 }
        }
        
        scale: button.activeFocus ? 1.05 : 1.0
    }
    
    // Background shape (similar to their Background.qml)
    Rectangle {
        anchors.fill: content
        anchors.margins: -8
        color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
        radius: 24
        opacity: 0.95
        z: -1
        
        // Subtle border
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
        border.width: 1
    }
}