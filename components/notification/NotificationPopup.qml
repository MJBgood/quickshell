import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../shared"

PopupWindow {
    id: notificationPopup
    
    // Configuration
    property var notification: null
    property var configService: ConfigService
    
    // Popup properties
    implicitWidth: 400
    implicitHeight: Math.min(200, contentColumn.implicitHeight + 32)
    visible: false
    color: "transparent"
    
    // Positioning
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Right
        gravity: Edges.Top | Edges.Right
        adjustment: PopupAdjustment.SlideY
        margins { left: 16; right: 16; top: 16; bottom: 16 }
    }
    
    // Auto-dismiss timer
    Timer {
        id: dismissTimer
        interval: getDismissTimeout()
        running: false
        onTriggered: hide()
    }
    
    // Focus grab for manual dismissal
    HyprlandFocusGrab {
        id: focusGrab
        windows: [notificationPopup]
        onCleared: hide()
    }
    
    // Main content container
    Rectangle {
        id: contentContainer
        anchors.fill: parent
        radius: configService ? configService.scaled(12) : 12
        color: getBackgroundColor()
        border.color: getBorderColor()
        border.width: 1
        
        
        // Progress indicator for auto-dismiss
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 2
            radius: 0
            color: "transparent"
            
            Rectangle {
                id: progressIndicator
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                radius: parent.radius
                color: getAccentColor()
                opacity: 0.3
                
                NumberAnimation {
                    id: progressAnimation
                    target: progressIndicator
                    property: "width"
                    from: progressBar.width
                    to: 0
                    duration: getDismissTimeout()
                    running: false
                }
            }
        }
        
        // Content layout
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: configService ? configService.spacing("sm", "notificationPopup") : 8
            
            // Header row with app info and close button
            Row {
                width: parent.width
                spacing: configService ? configService.spacing("sm", "notificationPopup") : 8
                
                // App icon
                Rectangle {
                    width: 32
                    height: 32
                    radius: configService ? configService.scaled(6) : 6
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    visible: notification && notification.appIcon
                    
                    Image {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: notification ? notification.appIcon || "" : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: true
                        asynchronous: true
                        
                        // Fallback text
                        Text {
                            visible: parent.status === Image.Error || parent.status === Image.Null
                            anchors.centerIn: parent
                            text: notification ? notification.appName.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                    }
                }
                
                // App name and timestamp
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: parent.width - 100  // Leave space for close button
                    
                    Text {
                        text: notification ? notification.appName : ""
                        font.pixelSize: configService ? configService.typography("sm", "notificationPopup") : 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "textSecondary") || "#a6adc8" : "#a6adc8"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    Text {
                        text: getFormattedTime()
                        font.pixelSize: configService ? configService.typography("xs", "notificationPopup") : 10
                        color: configService ? configService.getThemeProperty("colors", "textTertiary") || "#6c7086" : "#6c7086"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
                
                // Spacer
                Item { 
                    width: parent.width - 100
                    height: 1
                }
                
                // Close button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: closeButtonMouse.containsMouse ? 
                           (configService ? configService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8") :
                           (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: closeButtonMouse.containsMouse ? "#ffffff" : 
                               (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                    }
                    
                    MouseArea {
                        id: closeButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hide()
                    }
                }
            }
            
            // Summary text
            Text {
                width: parent.width
                text: notification ? notification.summary : ""
                font.pixelSize: configService ? configService.typography("md", "notificationPopup") : 14
                font.weight: Font.DemiBold
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0
            }
            
            // Body text
            Text {
                width: parent.width
                text: notification ? notification.body || "" : ""
                font.pixelSize: configService ? configService.typography("sm", "notificationPopup") : 12
                color: configService ? configService.getThemeProperty("colors", "textSecondary") || "#a6adc8" : "#a6adc8"
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: text.length > 0
            }
            
            // Notification image
            Rectangle {
                width: parent.width
                height: Math.min(120, notificationImage.implicitHeight)
                radius: configService ? configService.scaled(8) : 8
                color: "transparent"
                visible: notification && notification.image
                clip: true
                
                Image {
                    id: notificationImage
                    anchors.centerIn: parent
                    width: parent.width
                    source: notification ? notification.image || "" : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    cache: true
                    asynchronous: true
                }
            }
            
            // Action buttons
            Row {
                width: parent.width
                spacing: configService ? configService.spacing("sm", "notificationPopup") : 8
                visible: notification && notification.actions && notification.actions.length > 0
                
                Repeater {
                    model: notification ? notification.actions : []
                    
                    delegate: Rectangle {
                        height: 32
                        width: Math.max(80, actionText.implicitWidth + 16)
                        radius: configService ? configService.scaled(6) : 6
                        color: actionMouse.containsMouse ? 
                               (configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") :
                               (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244")
                        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        border.width: 1
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text || modelData.id || ""
                            font.pixelSize: configService ? configService.typography("sm", "notificationPopup") : 12
                            font.weight: Font.Medium
                            color: actionMouse.containsMouse ? "#000000" :
                                   (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                        }
                        
                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[NotificationPopup] Action clicked:", modelData.id)
                                if (notification && notification.quickshellNotification) {
                                    notification.quickshellNotification.invokeAction(modelData.id)
                                }
                                hide()
                            }
                        }
                    }
                }
            }
        }
        
        // Swipe-to-dismiss gesture
        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            
            property real startX: 0
            property real startY: 0
            property bool isDragging: false
            
            onPressed: function(mouse) {
                startX = mouse.x
                startY = mouse.y
                isDragging = false
                mouse.accepted = false
            }
            
            onPositionChanged: function(mouse) {
                if (pressed) {
                    const deltaX = mouse.x - startX
                    const deltaY = Math.abs(mouse.y - startY)
                    
                    if (Math.abs(deltaX) > 10 && deltaY < 50) {
                        isDragging = true
                        contentContainer.x = Math.min(0, deltaX)
                        contentContainer.opacity = Math.max(0.3, 1.0 - Math.abs(deltaX) / width)
                    }
                }
            }
            
            onReleased: function(mouse) {
                if (isDragging) {
                    const deltaX = mouse.x - startX
                    if (Math.abs(deltaX) > width * 0.3) {
                        // Swipe threshold reached - dismiss
                        hide()
                    } else {
                        // Snap back
                        snapBackAnimation.restart()
                    }
                }
                isDragging = false
            }
            
            NumberAnimation {
                id: snapBackAnimation
                target: contentContainer
                properties: "x,opacity"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
                
                onFinished: {
                    contentContainer.opacity = 1.0
                }
            }
        }
    }
    
    // Show animation
    SequentialAnimation {
        id: showAnimation
        running: false
        
        PropertyAnimation {
            target: contentContainer
            property: "scale"
            from: 0.95
            to: 1.0
            duration: 200
            easing.type: Easing.OutBack
        }
    }
    
    // Hide animation
    SequentialAnimation {
        id: hideAnimation
        running: false
        
        PropertyAnimation {
            target: contentContainer
            property: "scale"
            from: 1.0
            to: 0.95
            duration: 200
            easing.type: Easing.InBack
        }
        
        onFinished: {
            visible = false
            notificationPopup.closed()
        }
    }
    
    function show(anchorWindow, notificationData) {
        notification = notificationData
        anchor.window = anchorWindow
        
        visible = true
        showAnimation.restart()
        
        // Start auto-dismiss timer and progress animation
        if (shouldAutoDismiss()) {
            dismissTimer.restart()
            progressAnimation.restart()
        }
    }
    
    function hide() {
        dismissTimer.stop()
        progressAnimation.stop()
        hideAnimation.restart()
    }
    
    function shouldAutoDismiss() {
        if (!notification) return true
        
        // Most notifications should auto-dismiss
        // Only keep critical notifications with actions open
        const urgency = notification.urgency || 1
        if (urgency >= 2 && notification.actions && notification.actions.length > 0) {
            return false  // Critical with actions - keep open
        }
        
        return true  // Auto-dismiss everything else
    }
    
    function getDismissTimeout() {
        if (!notification) return 5000
        
        const urgency = notification.urgency || 1
        switch (urgency) {
            case 0: return 3000   // Low priority - quick dismiss
            case 1: return 5000   // Normal priority
            case 2: return 10000  // Critical - longer display
            default: return 5000
        }
    }
    
    function getBackgroundColor() {
        if (!configService) return "#313244"
        
        const urgency = notification ? notification.urgency || 1 : 1
        switch (urgency) {
            case 0:  // Low
                return configService.getThemeProperty("colors", "surface") || "#313244"
            case 1:  // Normal  
                return configService.getThemeProperty("colors", "surface") || "#313244"
            case 2:  // Critical
                return configService.getThemeProperty("colors", "error") || "#f38ba8"
            default:
                return configService.getThemeProperty("colors", "surface") || "#313244"
        }
    }
    
    function getBorderColor() {
        if (!configService) return "#585b70"
        
        const urgency = notification ? notification.urgency || 1 : 1
        switch (urgency) {
            case 0:  // Low
                return configService.getThemeProperty("colors", "border") || "#585b70"
            case 1:  // Normal
                return configService.getThemeProperty("colors", "accent") || "#a6e3a1"
            case 2:  // Critical
                return "#ffffff"
            default:
                return configService.getThemeProperty("colors", "border") || "#585b70"
        }
    }
    
    function getAccentColor() {
        if (!configService) return "#a6e3a1"
        return configService.getThemeProperty("colors", "accent") || "#a6e3a1"
    }
    
    function getFormattedTime() {
        if (!notification || !notification.timestamp) return ""
        
        const now = new Date()
        const notificationTime = new Date(notification.timestamp)
        const diffMs = now - notificationTime
        const diffMinutes = Math.floor(diffMs / 60000)
        
        if (diffMinutes < 1) return "now"
        if (diffMinutes === 1) return "1 min ago"
        if (diffMinutes < 60) return `${diffMinutes} mins ago`
        
        const diffHours = Math.floor(diffMinutes / 60)
        if (diffHours === 1) return "1 hour ago"
        if (diffHours < 24) return `${diffHours} hours ago`
        
        return notificationTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
    
    // Signal emitted when popup is closed
    signal closed()
    
    Component.onCompleted: {
        console.log("[NotificationPopup] Initialized")
    }
}