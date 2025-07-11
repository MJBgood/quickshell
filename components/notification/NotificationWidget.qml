import QtQuick
import QtQuick.Controls
import "../shared"
import "../shared"

Rectangle {
    id: notificationWidget
    
    // Entity ID for configuration
    property string entityId: "notificationWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "notifications"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    property string menuPath: "notifications"
    
    // Services
    property var configService: ConfigService
    property var notificationService: NotificationService
    property var anchorWindow: null
    
    // Configuration properties
    property bool enabled: configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showCount: configService ? configService.getEntityProperty(entityId, "showCount", true) : true
    property bool showUnreadOnly: configService ? configService.getEntityProperty(entityId, "showUnreadOnly", true) : true
    property bool animateChanges: configService ? configService.getEntityProperty(entityId, "animateChanges", true) : true
    
    // Visual properties
    visible: enabled
    color: getBackgroundColor()
    radius: configService ? configService.getEntityStyle(entityId, "borderRadius", "auto", configService.scaled(6)) : 6
    
    // Auto-size based on content
    implicitWidth: Math.max(32, contentRow.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12))
    implicitHeight: configService ? configService.getWidgetHeight(entityId, contentRow.implicitHeight) : contentRow.implicitHeight
    
    // Reactive notification data
    property int displayCount: notificationService ? (showUnreadOnly ? notificationService.unreadCount : notificationService.totalCount) : 0
    property bool hasNotifications: notificationService ? notificationService.totalCount > 0 : false
    property bool hasUnread: notificationService ? notificationService.unreadCount > 0 : false
    
    
    function getBackgroundColor() {
        if (!configService) return "#313244"
        
        if (hasUnread) {
            return configService.getThemeProperty("colors", "accent") || "#a6e3a1"
        } else if (hasNotifications) {
            return configService.getThemeProperty("colors", "surfaceAlt") || "#45475a"
        } else {
            return configService.getThemeProperty("colors", "surface") || "#313244"
        }
    }
    
    // Smooth color transitions
    Behavior on color {
        enabled: animateChanges
        ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Content layout
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        // Notification bell icon (simple emoji)
        Text {
            id: bellIcon
            visible: showIcon
            text: "🔔"
            font.pixelSize: configService ? configService.icon("sm", entityId) : 20
            anchors.verticalCenter: parent.verticalCenter
            color: getIconColor()
            
            // Icon animation for new notifications
            SequentialAnimation {
                id: bellAnimation
                running: false
                
                NumberAnimation {
                    target: bellIcon
                    property: "scale"
                    from: 1.0
                    to: 1.3
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                
                NumberAnimation {
                    target: bellIcon
                    property: "scale"
                    from: 1.3
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            
            // Attention indicator dot (overlay on top of SVG)
            Rectangle {
                visible: hasUnread
                width: parent.width * 0.3
                height: parent.height * 0.3
                anchors.top: parent.top
                anchors.right: parent.right
                color: configService ? configService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                radius: width / 2
                border.width: 1
                border.color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
            }
            
        }
        
        // Notification count badge
        Rectangle {
            visible: showCount && displayCount > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(16, countText.implicitWidth + 6)
            height: 16
            radius: 8
            color: hasUnread ? "#f38ba8" : "#89b4fa"
            
            Text {
                id: countText
                anchors.centerIn: parent
                text: displayCount > 99 ? "99+" : displayCount.toString()
                color: "#ffffff"
                font.family: "Inter"
                font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                font.weight: Font.DemiBold
            }
            
            // Count badge animation
            Behavior on scale {
                enabled: animateChanges
                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
            }
            
            // Animate on count changes
            onVisibleChanged: {
                if (visible && animateChanges) {
                    scaleAnimation.restart()
                }
            }
            
            NumberAnimation {
                id: scaleAnimation
                target: parent
                property: "scale"
                from: 0.1
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
            }
        }
    }
    
    function getIconColor() {
        if (!configService) return "#89b4fa"
        
        if (hasUnread) {
            return configService.getThemeProperty("colors", "accent") || "#a6e3a1"
        } else {
            return configService.getThemeProperty("colors", "primary") || "#89b4fa"
        }
    }
    
    // Mouse interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                showNotificationCenter()
            } else if (mouse.button === Qt.RightButton) {
                showContextMenu(mouse.x, mouse.y)
            }
        }
        
        // Hover effect
        onContainsMouseChanged: {
            if (animateChanges) {
                hoverAnimation.restart()
            }
        }
        
        NumberAnimation {
            id: hoverAnimation
            target: notificationWidget
            property: "scale"
            to: mouseArea.containsMouse ? 1.05 : 1.0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    
    
    
    
    
    // Context menu loader
    Loader {
        id: contextMenuLoader
        source: "../overlays/NotificationContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = notificationWidget.configService
            item.notificationService = notificationWidget.notificationService
            
            item.closed.connect(function() {
                contextMenuLoader.active = false
            })
        }
    }
    
    // Notification center loader
    Loader {
        id: notificationCenterLoader
        source: "../overlays/NotificationCenter.qml"
        active: false
        
        onLoaded: {
            item.configService = notificationWidget.configService
            item.notificationService = notificationWidget.notificationService
            
            item.closed.connect(function() {
                notificationCenterLoader.active = false
            })
        }
    }
    
    // React to notification changes
    Connections {
        target: notificationService
        function onNotificationsChanged() {
            // Properties will update automatically due to binding
            // Just trigger animation for new notifications
            if (showIcon && animateChanges && hasUnread) {
                bellAnimation.restart()
            }
        }
        
        function onTotalCountChanged() {
            // Properties will update automatically due to binding
            console.log("[NotificationWidget] Total count changed to:", notificationService.totalCount)
        }
        
        function onUnreadCountChanged() {
            // Properties will update automatically due to binding
            console.log("[NotificationWidget] Unread count changed to:", notificationService.unreadCount)
            
            // Trigger bell animation for new unread notifications
            if (showIcon && animateChanges && notificationService.unreadCount > 0) {
                bellAnimation.restart()
            }
        }
        
        function onNotificationPopupRequested(notification) {
            // Handle popup request if this widget should manage popups
        }
    }
    
    // Functions for mouse interaction
    function showNotificationCenter() {
        if (!notificationCenterLoader.active) {
            notificationCenterLoader.active = true
        }
        
        if (notificationCenterLoader.item) {
            let parentWindow = notificationWidget.parent
            while (parentWindow && !parentWindow.hasOwnProperty("__qs_window")) {
                parentWindow = parentWindow.parent
            }
            
            const globalPos = notificationWidget.mapToItem(null, 0, 0)
            notificationCenterLoader.item.show(parentWindow || anchorWindow, globalPos.x, globalPos.y)
        }
    }
    
    function showContextMenu(x, y) {
        if (!contextMenuLoader.active) {
            contextMenuLoader.active = true
        }
        
        if (contextMenuLoader.item) {
            // Find the proper window - traverse up the parent chain
            let parentWindow = notificationWidget.parent
            while (parentWindow && !parentWindow.hasOwnProperty("__qs_window")) {
                parentWindow = parentWindow.parent
            }
            
            const globalPos = notificationWidget.mapToItem(null, x, y)
            contextMenuLoader.item.show(parentWindow || anchorWindow, globalPos.x, globalPos.y)
        }
    }
    
    Component.onCompleted: {
        // Widget initialized - ready for use
    }
}