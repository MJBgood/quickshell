pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: popupManager
    
    // Configuration
    property var configService: null
    property int maxConcurrentPopups: 5
    property int popupSpacing: 16
    property string stackDirection: "down"  // "up" or "down"
    
    // Active popups tracking
    property var activePopups: []
    property var popupQueue: []
    
    // Position management
    property int baseX: 32
    property int baseY: 32
    property var anchorWindow: null
    
    function initialize(configServiceInstance, mainWindow) {
        configService = configServiceInstance
        anchorWindow = mainWindow
        
        console.log("[NotificationPopupManager] Initialized with anchor window")
    }
    
    function showNotificationPopup(notification) {
        console.log("[NotificationPopupManager] Request to show popup for:", notification.summary)
        
        // Check if we're at the popup limit
        if (activePopups.length >= maxConcurrentPopups) {
            console.log("[NotificationPopupManager] At popup limit, queueing notification")
            popupQueue.push(notification)
            return
        }
        
        // Create and show popup
        createAndShowPopup(notification)
    }
    
    function createAndShowPopup(notification) {
        // Create popup component
        const popupComponent = Qt.createComponent("../components/overlays/NotificationPopup.qml")
        
        if (popupComponent.status !== Component.Ready) {
            console.error("[NotificationPopupManager] Failed to create popup component:", popupComponent.errorString())
            return
        }
        
        // Create popup instance
        const popup = popupComponent.createObject(popupManager, {
            configService: configService
        })
        
        if (!popup) {
            console.error("[NotificationPopupManager] Failed to create popup instance")
            return
        }
        
        // Calculate position for this popup
        const position = calculatePopupPosition(activePopups.length)
        
        // Connect to popup closed signal
        popup.closed.connect(function() {
            onPopupClosed(popup)
        })
        
        // Add to active popups before showing
        activePopups.push({
            popup: popup,
            notification: notification,
            position: position
        })
        
        // Position and show popup
        popup.anchor.rect.x = position.x
        popup.anchor.rect.y = position.y
        popup.show(anchorWindow, notification)
        
        console.log(`[NotificationPopupManager] Created popup at position (${position.x}, ${position.y})`)
    }
    
    function onPopupClosed(popup) {
        console.log("[NotificationPopupManager] Popup closed, cleaning up")
        
        // Remove from active popups
        activePopups = activePopups.filter(item => item.popup !== popup)
        
        // Destroy the popup
        popup.destroy()
        
        // Reposition remaining popups
        repositionActivePopups()
        
        // Show next queued popup if any
        if (popupQueue.length > 0) {
            const nextNotification = popupQueue.shift()
            createAndShowPopup(nextNotification)
        }
    }
    
    function calculatePopupPosition(index) {
        if (!anchorWindow) {
            return { x: baseX, y: baseY }
        }
        
        const popupHeight = 200  // Approximate popup height
        const totalSpacing = popupSpacing + popupHeight
        
        let x = anchorWindow.width - 432  // popup width + margin
        let y = baseY
        
        if (stackDirection === "down") {
            y = baseY + (index * totalSpacing)
        } else {
            y = anchorWindow.height - baseY - ((index + 1) * totalSpacing)
        }
        
        // Ensure popup stays on screen
        x = Math.max(32, Math.min(x, anchorWindow.width - 432))
        y = Math.max(32, Math.min(y, anchorWindow.height - popupHeight - 32))
        
        return { x: x, y: y }
    }
    
    function repositionActivePopups() {
        console.log("[NotificationPopupManager] Repositioning", activePopups.length, "active popups")
        
        for (let i = 0; i < activePopups.length; i++) {
            const popupItem = activePopups[i]
            const newPosition = calculatePopupPosition(i)
            
            // Animate to new position
            animatePopupToPosition(popupItem.popup, newPosition)
            popupItem.position = newPosition
        }
    }
    
    function animatePopupToPosition(popup, position) {
        if (!popup || !popup.anchor) return
        
        // Create smooth position animation
        const xAnimation = Qt.createQmlObject(`
            import QtQuick
            NumberAnimation {
                target: popup.anchor.rect
                property: "x"
                to: ${position.x}
                duration: 300
                easing.type: Easing.OutCubic
            }
        `, popupManager)
        
        const yAnimation = Qt.createQmlObject(`
            import QtQuick
            NumberAnimation {
                target: popup.anchor.rect
                property: "y"
                to: ${position.y}
                duration: 300
                easing.type: Easing.OutCubic
            }
        `, popupManager)
        
        xAnimation.start()
        yAnimation.start()
        
        // Clean up animations after completion
        xAnimation.finished.connect(() => xAnimation.destroy())
        yAnimation.finished.connect(() => yAnimation.destroy())
    }
    
    function dismissAllPopups() {
        console.log("[NotificationPopupManager] Dismissing all active popups")
        
        // Close all active popups
        activePopups.forEach(item => {
            if (item.popup) {
                item.popup.hide()
            }
        })
        
        // Clear queue
        popupQueue = []
        
        console.log("[NotificationPopupManager] All popups dismissed")
    }
    
    function dismissPopup(notificationId) {
        const popupItem = activePopups.find(item => 
            item.notification && item.notification.id === notificationId
        )
        
        if (popupItem && popupItem.popup) {
            popupItem.popup.hide()
        }
    }
    
    function getActivePopupCount() {
        return activePopups.length
    }
    
    function getQueuedPopupCount() {
        return popupQueue.length
    }
    
    // Configuration helpers
    function updateConfiguration(newConfig) {
        if (newConfig.maxConcurrentPopups !== undefined) {
            maxConcurrentPopups = newConfig.maxConcurrentPopups
        }
        if (newConfig.popupSpacing !== undefined) {
            popupSpacing = newConfig.popupSpacing
        }
        if (newConfig.stackDirection !== undefined) {
            stackDirection = newConfig.stackDirection
        }
        if (newConfig.baseX !== undefined) {
            baseX = newConfig.baseX
        }
        if (newConfig.baseY !== undefined) {
            baseY = newConfig.baseY
        }
        
        // Reposition existing popups with new settings
        if (activePopups.length > 0) {
            repositionActivePopups()
        }
        
        console.log("[NotificationPopupManager] Configuration updated:", newConfig)
    }
    
    // Screen size change handling
    // TODO: Re-enable when proper screen change signal is available
    // Connections {
    //     target: Quickshell.screens
    //     function onScreensChanged() {
    //         console.log("[NotificationPopupManager] Screens changed, repositioning popups")
    //         repositionActivePopups()
    //     }
    // }
    
    Component.onCompleted: {
        console.log("[NotificationPopupManager] Popup manager initialized")
        console.log("[NotificationPopupManager] Max concurrent popups:", maxConcurrentPopups)
        console.log("[NotificationPopupManager] Stack direction:", stackDirection)
    }
}