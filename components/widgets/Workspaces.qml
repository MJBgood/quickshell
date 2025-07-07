import QtQuick
import "../../services"

Row {
    id: workspaces
    
    // Services
    property var configService: ConfigService
    
    spacing: 2
    
    // Workspace indicators
    Repeater {
        model: 4  // Show 4 workspaces as placeholder
        
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: index === 0 ? (configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") : 
                                 (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            opacity: index === 0 ? 1.0 : 0.5
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("Workspaces widget loaded")
    }
}