import QtQuick
import "../services"

Item {
    id: workspaceStore
    
    // Store state
    property bool initialized: false
    
    // Workspace data
    property var workspaces: []
    property int activeWorkspace: 1
    property int workspaceCount: 10
    property var workspaceHistory: []
    property int maxHistoryLength: 10
    
    // Configuration
    property bool showEmptyWorkspaces: true
    property bool autoCreateWorkspaces: true
    property int maxWorkspaces: 20
    
    // Signals
    signal workspaceAdded(int workspaceId)
    signal workspaceRemoved(int workspaceId)
    signal workspaceChanged(int oldId, int newId)
    signal workspaceUpdated(int workspaceId)
    signal storeUpdated()
    
    // Public API
    function createWorkspace(workspaceId = -1) {
        // Auto-generate ID if not provided
        if (workspaceId === -1) {
            workspaceId = getNextAvailableId()
        }
        
        // Check if workspace already exists
        if (getWorkspace(workspaceId)) {
            console.warn(`WorkspaceStore: Workspace ${workspaceId} already exists`)
            return false
        }
        
        // Check max workspaces limit
        if (workspaces.length >= maxWorkspaces) {
            console.warn(`WorkspaceStore: Maximum workspace limit (${maxWorkspaces}) reached`)
            return false
        }
        
        const workspace = {
            id: workspaceId,
            name: `Workspace ${workspaceId}`,
            windows: [],
            windowCount: 0,
            active: false,
            empty: true,
            createdAt: Date.now(),
            lastAccessed: Date.now()
        }
        
        workspaces.push(workspace)
        workspaceCount = workspaces.length
        
        // Sort workspaces by ID
        workspaces.sort((a, b) => a.id - b.id)
        
        workspaceAdded(workspaceId)
        storeUpdated()
        
        console.log(`WorkspaceStore: Created workspace ${workspaceId}`)
        return true
    }
    
    function removeWorkspace(workspaceId) {
        const workspaceIndex = workspaces.findIndex(w => w.id === workspaceId)
        if (workspaceIndex === -1) {
            console.warn(`WorkspaceStore: Workspace ${workspaceId} not found`)
            return false
        }
        
        const workspace = workspaces[workspaceIndex]
        
        // Don't remove workspace if it has windows
        if (workspace.windowCount > 0) {
            console.warn(`WorkspaceStore: Cannot remove workspace ${workspaceId} - it contains windows`)
            return false
        }
        
        // Don't remove the active workspace
        if (workspace.id === activeWorkspace) {
            console.warn(`WorkspaceStore: Cannot remove active workspace ${workspaceId}`)
            return false
        }
        
        workspaces.splice(workspaceIndex, 1)
        workspaceCount = workspaces.length
        
        // Remove from history
        workspaceHistory = workspaceHistory.filter(id => id !== workspaceId)
        
        workspaceRemoved(workspaceId)
        storeUpdated()
        
        console.log(`WorkspaceStore: Removed workspace ${workspaceId}`)
        return true
    }
    
    function switchToWorkspace(workspaceId) {
        const workspace = getWorkspace(workspaceId)
        if (!workspace) {
            // Auto-create workspace if enabled
            if (autoCreateWorkspaces && workspaceId > 0 && workspaceId <= maxWorkspaces) {
                createWorkspace(workspaceId)
            } else {
                console.warn(`WorkspaceStore: Workspace ${workspaceId} not found`)
                return false
            }
        }
        
        const oldWorkspace = activeWorkspace
        
        // Update active workspace
        workspaces.forEach(w => {
            w.active = (w.id === workspaceId)
            if (w.id === workspaceId) {
                w.lastAccessed = Date.now()
            }
        })
        
        activeWorkspace = workspaceId
        
        // Update history
        addToHistory(workspaceId)
        
        workspaceChanged(oldWorkspace, workspaceId)
        workspaceUpdated(workspaceId)
        storeUpdated()
        
        console.log(`WorkspaceStore: Switched from workspace ${oldWorkspace} to ${workspaceId}`)
        return true
    }
    
    function updateWorkspace(workspaceId, updates) {
        const workspace = getWorkspace(workspaceId)
        if (!workspace) {
            console.warn(`WorkspaceStore: Workspace ${workspaceId} not found`)
            return false
        }
        
        // Apply updates
        for (const [key, value] of Object.entries(updates)) {
            workspace[key] = value
        }
        
        workspaceUpdated(workspaceId)
        storeUpdated()
        
        console.log(`WorkspaceStore: Updated workspace ${workspaceId}`)
        return true
    }
    
    function getWorkspace(workspaceId) {
        return workspaces.find(w => w.id === workspaceId) || null
    }
    
    function getActiveWorkspace() {
        return getWorkspace(activeWorkspace)
    }
    
    function getVisibleWorkspaces() {
        if (showEmptyWorkspaces) {
            return workspaces
        } else {
            return workspaces.filter(w => !w.empty || w.active)
        }
    }
    
    function getNextWorkspace() {
        const currentIndex = workspaces.findIndex(w => w.id === activeWorkspace)
        if (currentIndex === -1 || currentIndex === workspaces.length - 1) {
            return workspaces[0]
        }
        return workspaces[currentIndex + 1]
    }
    
    function getPreviousWorkspace() {
        const currentIndex = workspaces.findIndex(w => w.id === activeWorkspace)
        if (currentIndex === -1 || currentIndex === 0) {
            return workspaces[workspaces.length - 1]
        }
        return workspaces[currentIndex - 1]
    }
    
    function getNextAvailableId() {
        for (let i = 1; i <= maxWorkspaces; i++) {
            if (!getWorkspace(i)) {
                return i
            }
        }
        return -1 // No available IDs
    }
    
    function addToHistory(workspaceId) {
        // Remove existing entry
        workspaceHistory = workspaceHistory.filter(id => id !== workspaceId)
        
        // Add to front
        workspaceHistory.unshift(workspaceId)
        
        // Trim to max length
        if (workspaceHistory.length > maxHistoryLength) {
            workspaceHistory = workspaceHistory.slice(0, maxHistoryLength)
        }
    }
    
    function getPreviousWorkspaceFromHistory() {
        // Return the second item in history (first is current workspace)
        return workspaceHistory.length > 1 ? workspaceHistory[1] : null
    }
    
    function updateWorkspaceWindowCounts(windowsByWorkspace) {
        workspaces.forEach(workspace => {
            const windows = windowsByWorkspace[workspace.id] || []
            workspace.windows = windows
            workspace.windowCount = windows.length
            workspace.empty = windows.length === 0
        })
        
        storeUpdated()
    }
    
    function syncWithService(hyprlandService) {
        if (!hyprlandService) {
            console.warn("WorkspaceStore: HyprlandService is not available")
            return
        }
        
        // Connect to service signals
        hyprlandService.workspaceChanged.connect((workspaceId) => {
            switchToWorkspace(workspaceId)
        })
        
        hyprlandService.workspaceCreated.connect((workspaceId) => {
            createWorkspace(workspaceId)
        })
        
        hyprlandService.workspaceDestroyed.connect((workspaceId) => {
            removeWorkspace(workspaceId)
        })
        
        // Initial sync
        clearAll()
        
        if (hyprlandService.workspaces) {
            hyprlandService.workspaces.forEach(workspace => {
                createWorkspace(workspace.id)
                updateWorkspace(workspace.id, {
                    name: workspace.name,
                    windowCount: workspace.windows,
                    empty: workspace.windows === 0
                })
            })
        }
        
        if (hyprlandService.activeWorkspace) {
            switchToWorkspace(hyprlandService.activeWorkspace)
        }
        
        console.log("WorkspaceStore: Synchronized with HyprlandService")
    }
    
    function clearAll() {
        workspaces = []
        workspaceCount = 0
        activeWorkspace = 1
        workspaceHistory = []
        
        storeUpdated()
        
        console.log("WorkspaceStore: Cleared all workspaces")
    }
    
    function initializeDefaults() {
        // Create default workspaces
        for (let i = 1; i <= 10; i++) {
            createWorkspace(i)
        }
        
        // Set first workspace as active
        switchToWorkspace(1)
        
        console.log("WorkspaceStore: Initialized with default workspaces")
    }
    
    // Statistics
    function getStats() {
        return {
            total: workspaceCount,
            active: activeWorkspace,
            empty: workspaces.filter(w => w.empty).length,
            nonEmpty: workspaces.filter(w => !w.empty).length,
            totalWindows: workspaces.reduce((sum, w) => sum + w.windowCount, 0),
            averageWindows: workspaceCount > 0 ? 
                (workspaces.reduce((sum, w) => sum + w.windowCount, 0) / workspaceCount).toFixed(2) : 0,
            history: workspaceHistory.slice()
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("WorkspaceStore: Initializing...")
        initializeDefaults()
        initialized = true
        console.log("WorkspaceStore: Initialization complete")
    }
}