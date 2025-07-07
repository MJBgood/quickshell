pragma Singleton
import QtQuick

// Utility singleton for finding proper Quickshell windows for popup anchoring
QtObject {
    
    // Find the proper Quickshell window (PanelWindow) for popup anchoring
    function findQuickshellWindow(startItem) {
        if (!startItem) {
            console.error("WindowUtils: No starting item provided")
            return null
        }
        
        var currentItem = startItem
        var depth = 0
        
        // Traverse up the parent hierarchy
        while (currentItem && depth < 10) { // Safety limit
            const itemString = currentItem.toString()
            
            // Look for Quickshell window types
            if (itemString.indexOf("PanelWindow") !== -1 ||
                itemString.indexOf("PopupWindow") !== -1 ||
                itemString.indexOf("Window") !== -1) {
                
                // Additional validation - should have screen property
                if (currentItem.hasOwnProperty("screen")) {
                    console.log("WindowUtils: Found Quickshell window:", itemString)
                    return currentItem
                }
            }
            
            currentItem = currentItem.parent
            depth++
        }
        
        console.error("WindowUtils: Could not find valid Quickshell window, searched", depth, "levels")
        return null
    }
    
    // Safe popup show helper
    function showPopup(popup, anchorItem, x, y) {
        if (!popup || !anchorItem) {
            console.error("WindowUtils: Invalid popup or anchor item")
            return false
        }
        
        const quickshellWindow = findQuickshellWindow(anchorItem)
        if (quickshellWindow) {
            popup.show(quickshellWindow, x || 0, y || 0)
            return true
        } else {
            console.error("WindowUtils: Cannot show popup - no valid anchor window found")
            return false
        }
    }
}