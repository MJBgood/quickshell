import QtQuick
import "../services"

Item {
    id: windowStore
    
    // Store state
    property bool initialized: false
    
    // Window data
    property var windows: []
    property var activeWindow: null
    property int windowCount: 0
    property var windowsByWorkspace: ({})
    
    // Filtering and sorting
    property string filterText: ""
    property string sortBy: "title" // "title", "class", "workspace", "recent"
    property bool sortAscending: true
    
    // Custom signals for specific events
    signal windowAdded(var window)
    signal windowRemoved(var window)
    signal windowUpdated(var window)
    signal storeUpdated()
    
    // Auto-generated property change signals (automatically available):
    // - windowsChanged()           // when windows array changes
    // - activeWindowChanged()      // when activeWindow property changes  
    // - windowCountChanged()       // when windowCount changes
    // - windowsByWorkspaceChanged() // when windowsByWorkspace changes
    // - filterTextChanged()        // when filterText changes
    // - sortByChanged()           // when sortBy changes
    // - sortAscendingChanged()    // when sortAscending changes
    
    // Public API
    function addWindow(window) {
        if (!window || !window.id) {
            console.warn("WindowStore: Invalid window data")
            return false
        }
        
        // Check if window already exists
        const existingIndex = windows.findIndex(w => w.id === window.id)
        if (existingIndex !== -1) {
            console.warn(`WindowStore: Window ${window.id} already exists`)
            return false
        }
        
        // Add timestamp
        window.addedAt = Date.now()
        window.lastFocused = Date.now()
        
        windows.push(window)
        windowCount = windows.length
        
        updateWindowsByWorkspace()
        windowAdded(window)
        storeUpdated()
        
        console.log(`WindowStore: Added window '${window.title}' (ID: ${window.id})`)
        return true
    }
    
    function removeWindow(windowId) {
        const windowIndex = windows.findIndex(w => w.id === windowId)
        if (windowIndex === -1) {
            console.warn(`WindowStore: Window ${windowId} not found`)
            return false
        }
        
        const window = windows[windowIndex]
        windows.splice(windowIndex, 1)
        windowCount = windows.length
        
        // Clear active window if it was removed
        if (activeWindow && activeWindow.id === windowId) {
            activeWindow = null
            // activeWindow property change will auto-emit activeWindowChanged()
        }
        
        updateWindowsByWorkspace()
        windowRemoved(window)
        storeUpdated()
        
        console.log(`WindowStore: Removed window '${window.title}' (ID: ${windowId})`)
        return true
    }
    
    function updateWindow(windowId, updates) {
        const windowIndex = windows.findIndex(w => w.id === windowId)
        if (windowIndex === -1) {
            console.warn(`WindowStore: Window ${windowId} not found`)
            return false
        }
        
        const window = windows[windowIndex]
        
        // Apply updates
        for (const [key, value] of Object.entries(updates)) {
            window[key] = value
        }
        
        // Update last modified timestamp
        window.lastModified = Date.now()
        
        updateWindowsByWorkspace()
        windowUpdated(window)
        storeUpdated()
        
        console.log(`WindowStore: Updated window '${window.title}' (ID: ${windowId})`)
        return true
    }
    
    function setActiveWindow(windowId) {
        const window = windows.find(w => w.id === windowId)
        if (!window) {
            console.warn(`WindowStore: Window ${windowId} not found`)
            return false
        }
        
        // Update last focused timestamp
        window.lastFocused = Date.now()
        
        activeWindow = window
        // activeWindow property change will auto-emit activeWindowChanged()
        
        console.log(`WindowStore: Set active window to '${window.title}' (ID: ${windowId})`)
        return true
    }
    
    function getWindow(windowId) {
        return windows.find(w => w.id === windowId) || null
    }
    
    function getWindowsByWorkspace(workspaceId) {
        return windows.filter(w => w.workspace === workspaceId)
    }
    
    function getWindowsByClass(className) {
        return windows.filter(w => w.class === className)
    }
    
    function getFilteredWindows() {
        let filtered = windows
        
        // Apply text filter
        if (filterText.trim() !== "") {
            const searchText = filterText.toLowerCase()
            filtered = filtered.filter(w => 
                w.title.toLowerCase().includes(searchText) ||
                w.class.toLowerCase().includes(searchText)
            )
        }
        
        // Apply sorting
        filtered.sort((a, b) => {
            let aValue, bValue
            
            switch (sortBy) {
                case "title":
                    aValue = a.title.toLowerCase()
                    bValue = b.title.toLowerCase()
                    break
                case "class":
                    aValue = a.class.toLowerCase()
                    bValue = b.class.toLowerCase()
                    break
                case "workspace":
                    aValue = a.workspace
                    bValue = b.workspace
                    break
                case "recent":
                    aValue = a.lastFocused || 0
                    bValue = b.lastFocused || 0
                    break
                default:
                    return 0
            }
            
            if (aValue < bValue) {
                return sortAscending ? -1 : 1
            } else if (aValue > bValue) {
                return sortAscending ? 1 : -1
            }
            return 0
        })
        
        return filtered
    }
    
    function updateWindowsByWorkspace() {
        const byWorkspace = {}
        
        windows.forEach(window => {
            const workspaceId = window.workspace
            if (!byWorkspace[workspaceId]) {
                byWorkspace[workspaceId] = []
            }
            byWorkspace[workspaceId].push(window)
        })
        
        windowsByWorkspace = byWorkspace
    }
    
    function clearAll() {
        windows = []
        windowCount = 0
        activeWindow = null
        windowsByWorkspace = {}
        
        // activeWindow property change will auto-emit activeWindowChanged()
        storeUpdated()
        
        console.log("WindowStore: Cleared all windows")
    }
    
    function syncWithService(hyprlandService) {
        if (!hyprlandService) {
            console.warn("WindowStore: HyprlandService is not available")
            return
        }
        
        // Connect to service signals
        hyprlandService.windowCreated.connect((window) => {
            addWindow(window)
        })
        
        hyprlandService.windowDestroyed.connect((window) => {
            removeWindow(window.id)
        })
        
        hyprlandService.windowChanged.connect((window) => {
            if (window) {
                setActiveWindow(window.id)
            }
        })
        
        // Initial sync
        clearAll()
        
        if (hyprlandService.windows) {
            hyprlandService.windows.forEach(window => {
                addWindow(JSON.parse(JSON.stringify(window)))
            })
        }
        
        if (hyprlandService.activeWindow) {
            setActiveWindow(hyprlandService.activeWindow.id)
        }
        
        console.log("WindowStore: Synchronized with HyprlandService")
    }
    
    // Statistics
    function getStats() {
        return {
            total: windowCount,
            byWorkspace: Object.keys(windowsByWorkspace).reduce((acc, workspaceId) => {
                acc[workspaceId] = windowsByWorkspace[workspaceId].length
                return acc
            }, {}),
            byClass: windows.reduce((acc, window) => {
                acc[window.class] = (acc[window.class] || 0) + 1
                return acc
            }, {}),
            floating: windows.filter(w => w.floating).length,
            fullscreen: windows.filter(w => w.fullscreen).length
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("WindowStore: Initializing...")
        initialized = true
        console.log("WindowStore: Initialization complete")
    }
}