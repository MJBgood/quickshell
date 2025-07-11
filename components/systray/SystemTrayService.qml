pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: systemTrayService
    
    // Public reactive properties
    property bool ready: false
    property var items: SystemTray.items
    property int itemCount: SystemTray.items ? SystemTray.items.values.length : 0
    property bool hasActiveItems: false
    property bool hasAttentionItems: false
    
    // Filter states
    property var activeItems: []
    property var passiveItems: []
    property var attentionItems: []
    
    // Entity ID for configuration
    property string entityId: "systemTrayService"
    
    // Public API functions
    function bindToSystem() {
        if (SystemTray) {
            ready = true
            refreshItemStates()
            console.log("SystemTrayService: Bound to SystemTray with", itemCount, "items")
        } else {
            console.warn("SystemTrayService: SystemTray not available")
        }
    }
    
    function refreshItemStates() {
        if (!SystemTray.items) return
        
        let active = []
        let passive = []
        let attention = []
        let hasActive = false
        let hasAttention = false
        
        const allItems = SystemTray.items.values || []
        
        for (let i = 0; i < allItems.length; i++) {
            const item = allItems[i]
            if (!item) continue
            
            switch (item.status) {
                case Status.Active:
                    active.push(item)
                    hasActive = true
                    break
                case Status.NeedsAttention:
                    attention.push(item)
                    hasAttention = true
                    break
                case Status.Passive:
                default:
                    passive.push(item)
                    break
            }
        }
        
        activeItems = active
        passiveItems = passive
        attentionItems = attention
        hasActiveItems = hasActive
        hasAttentionItems = hasAttention
    }
    
    function getFilteredItems(statusFilter) {
        switch (statusFilter) {
            case Status.Active:
                return activeItems
            case Status.NeedsAttention:
                return attentionItems
            case Status.Passive:
                return passiveItems
            default:
                return SystemTray.items ? SystemTray.items.values : []
        }
    }
    
    function getItemById(itemId) {
        if (!SystemTray.items) return null
        
        const allItems = SystemTray.items.values || []
        for (let i = 0; i < allItems.length; i++) {
            const item = allItems[i]
            if (item && item.id === itemId) {
                return item
            }
        }
        return null
    }
    
    function handleItemClick(item) {
        if (!item) return false
        
        console.log("SystemTrayService: Handling click for item:", item.title || item.id)
        
        // According to Quickshell docs, SystemTrayItem doesn't have an activate() method
        // The proper way is to show the menu if available, or do nothing
        if (item.hasMenu && item.menu) {
            console.log("SystemTrayService: Item has menu, should be shown via QsMenuAnchor")
            return true  // Indicate that menu should be shown
        } else if (item.onlyMenu) {
            console.log("SystemTrayService: Item only offers menu but no menu available")
            return false
        } else {
            console.log("SystemTrayService: Item has no menu interaction available")
            return false
        }
    }
    
    function handleItemRightClick(item) {
        if (!item) return false
        
        console.log("SystemTrayService: Handling right-click for item:", item.title || item.id)
        
        if (item.hasMenu && item.menu) {
            console.log("SystemTrayService: Showing item menu via right-click")
            return true  // Indicate that menu should be shown
        } else {
            console.log("SystemTrayService: Item has no context menu available")
            return false
        }
    }
    
    function getItemTooltip(item) {
        if (!item) return ""
        
        const title = item.tooltipTitle || item.title || ""
        const description = item.tooltipDescription || ""
        
        if (title.length > 0 && description.length > 0) {
            return title + "\n" + description
        } else if (title.length > 0) {
            return title
        } else if (description.length > 0) {
            return description
        } else {
            return ""
        }
    }
    
    function getStatusColor(item) {
        if (!item) return "transparent"
        
        switch (item.status) {
            case Status.Active:
                return "#a6e3a1"  // Green for active
            case Status.NeedsAttention:
                return "#f38ba8"  // Red for attention
            case Status.Passive:
            default:
                return "transparent"
        }
    }
    
    function getStatusText(item) {
        if (!item) return "Unknown"
        
        switch (item.status) {
            case Status.Active:
                return "Active"
            case Status.NeedsAttention:
                return "Needs Attention"
            case Status.Passive:
                return "Passive"
            default:
                return "Unknown"
        }
    }
    
    // Internal reactivity
    Connections {
        target: SystemTray.items
        function onValuesChanged() {
            itemCount = SystemTray.items ? SystemTray.items.values.length : 0
            refreshItemStates()
            console.log("SystemTrayService: Items changed, new count:", itemCount)
        }
    }
    
    // Component lifecycle
    Component.onCompleted: {
        console.log("SystemTrayService: Initializing singleton service")
        bindToSystem()
    }
    
    // Debug properties
    property bool debugMode: false
    
    function debugInfo() {
        if (!debugMode) return
        
        console.log("=== SystemTrayService Debug Info ===")
        console.log("Ready:", ready)
        console.log("Item count:", itemCount)
        console.log("Active items:", activeItems.length)
        console.log("Passive items:", passiveItems.length)
        console.log("Attention items:", attentionItems.length)
        console.log("Has active items:", hasActiveItems)
        console.log("Has attention items:", hasAttentionItems)
        console.log("SystemTray available:", !!SystemTray)
        console.log("SystemTray.items available:", !!SystemTray.items)
        
        if (SystemTray.items) {
            const allItems = SystemTray.items.values || []
            console.log("All items:")
            for (let i = 0; i < allItems.length; i++) {
                const item = allItems[i]
                if (item) {
                    console.log("  -", item.title || item.id, "| Status:", getStatusText(item), "| Has Menu:", item.hasMenu, "| Only Menu:", item.onlyMenu)
                }
            }
        }
        console.log("=====================================")
    }
    
    // Auto-refresh item states when count changes
    onItemCountChanged: {
        refreshItemStates()
        
        if (debugMode) {
            Qt.callLater(debugInfo)
        }
    }
}