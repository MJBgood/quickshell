import QtQuick
import QtCore
import Quickshell.Hyprland

Item {
    id: hyprlandService
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.hyprland"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Service state
    property bool initialized: false
    property bool isConnected: false
    property string socketPath: ""
    
    // Workspace state - now using real Hyprland data
    property var workspaces: Hyprland.workspaces
    property int activeWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property int workspaceCount: (workspaces && workspaces.length !== undefined) ? workspaces.length : 0
    
    // Window state - now using real Hyprland data  
    property var windows: []  // TODO: Implement window tracking
    property var activeWindow: Hyprland.focusedWindow
    property int windowCount: 0  // TODO: Calculate from real windows
    
    // Signals
    signal workspaceChanged(int workspaceId)
    signal windowChanged(var window)
    signal windowCreated(var window)
    signal windowDestroyed(var window)
    signal workspaceCreated(int workspaceId)
    signal workspaceDestroyed(int workspaceId)
    signal connected()
    signal disconnected()
    signal errorOccurred(string error)
    
    // Connect to Hyprland singleton events
    Connections {
        target: Hyprland
        
        function onFocusedWorkspaceChanged() {
            if (Hyprland.focusedWorkspace) {
                const newWorkspaceId = Hyprland.focusedWorkspace.id
                console.log(logCategory, `Workspace changed to ${newWorkspaceId}`)
                workspaceChanged(newWorkspaceId)
            }
        }
        
        function onRawEvent(event) {
            console.log(logCategory, `Raw event: ${event}`)
        }
    }
    
    // Public API
    function switchToWorkspace(workspaceId) {
        console.log(`HyprlandService: Switching to workspace ${workspaceId}`)
        
        try {
            // Use Hyprland.dispatch() to actually switch workspaces
            Hyprland.dispatch("workspace", workspaceId)
            console.log(`HyprlandService: Dispatched workspace switch to ${workspaceId}`)
            return true
            
        } catch (error) {
            console.error(`HyprlandService: Failed to switch workspace:`, error)
            errorOccurred(`Failed to switch workspace: ${error}`)
            return false
        }
    }
    
    function focusWindow(windowId) {
        console.log(`HyprlandService: Focusing window ${windowId}`)
        
        try {
            // Find the window
            const window = windows.find(w => w.id === windowId)
            if (!window) {
                console.warn(`HyprlandService: Window ${windowId} not found`)
                return false
            }
            
            // Focus the window
            activeWindow = window
            windowChanged(window)
            
            console.log(`HyprlandService: Focused window '${window.title}'`)
            return true
            
        } catch (error) {
            console.error(`HyprlandService: Failed to focus window:`, error)
            errorOccurred(`Failed to focus window: ${error}`)
            return false
        }
    }
    
    function closeWindow(windowId) {
        console.log(`HyprlandService: Closing window ${windowId}`)
        
        try {
            // Find and remove the window
            const windowIndex = windows.findIndex(w => w.id === windowId)
            if (windowIndex === -1) {
                console.warn(`HyprlandService: Window ${windowId} not found`)
                return false
            }
            
            const window = windows[windowIndex]
            windows.splice(windowIndex, 1)
            windowCount = windows.length
            
            if (activeWindow && activeWindow.id === windowId) {
                activeWindow = null
            }
            
            windowDestroyed(window)
            console.log(`HyprlandService: Closed window '${window.title}'`)
            return true
            
        } catch (error) {
            console.error(`HyprlandService: Failed to close window:`, error)
            errorOccurred(`Failed to close window: ${error}`)
            return false
        }
    }
    
    function moveWindowToWorkspace(windowId, workspaceId) {
        console.log(`HyprlandService: Moving window ${windowId} to workspace ${workspaceId}`)
        
        try {
            const window = windows.find(w => w.id === windowId)
            if (!window) {
                console.warn(`HyprlandService: Window ${windowId} not found`)
                return false
            }
            
            window.workspace = workspaceId
            console.log(`HyprlandService: Moved window '${window.title}' to workspace ${workspaceId}`)
            return true
            
        } catch (error) {
            console.error(`HyprlandService: Failed to move window:`, error)
            errorOccurred(`Failed to move window: ${error}`)
            return false
        }
    }
    
    function getWorkspaceWindows(workspaceId) {
        return windows.filter(w => w.workspace === workspaceId)
    }
    
    function refreshWorkspaces() {
        console.log("HyprlandService: Refreshing workspace information...")
        
        try {
            // In a real implementation, this would query Hyprland via IPC
            // For now, we'll simulate some workspaces
            const newWorkspaces = []
            for (let i = 1; i <= workspaceCount; i++) {
                newWorkspaces.push({
                    id: i,
                    name: `Workspace ${i}`,
                    windows: getWorkspaceWindows(i).length,
                    active: i === activeWorkspace
                })
            }
            
            workspaces = newWorkspaces
            console.log(`HyprlandService: Refreshed ${workspaces.length} workspaces`)
            
        } catch (error) {
            console.error("HyprlandService: Failed to refresh workspaces:", error)
            errorOccurred(`Failed to refresh workspaces: ${error}`)
        }
    }
    
    function refreshWindows() {
        console.log("HyprlandService: Refreshing window information...")
        
        try {
            // In a real implementation, this would query Hyprland via IPC
            // For now, we'll simulate some windows
            windowCount = windows.length
            console.log(`HyprlandService: Found ${windowCount} windows`)
            
        } catch (error) {
            console.error("HyprlandService: Failed to refresh windows:", error)
            errorOccurred(`Failed to refresh windows: ${error}`)
        }
    }
    
    function connectToHyprland() {
        console.log("HyprlandService: Connecting to Hyprland...")
        
        try {
            // Connection is automatic with Quickshell.Hyprland singleton
            if (Hyprland.eventSocketPath !== "") {
                isConnected = true
                connected()
                console.log(`HyprlandService: Connected to Hyprland at ${Hyprland.eventSocketPath}`)
                
                // Log initial state
                console.log(`HyprlandService: Found ${workspaceCount} workspaces`)
                console.log(`HyprlandService: Active workspace: ${activeWorkspace}`)
                
            } else {
                console.warn("HyprlandService: No Hyprland event socket found")
                isConnected = false
            }
            
        } catch (error) {
            console.error("HyprlandService: Failed to connect to Hyprland:", error)
            isConnected = false
            errorOccurred(`Failed to connect to Hyprland: ${error}`)
        }
    }
    
    function disconnect() {
        console.log("HyprlandService: Disconnecting from Hyprland...")
        isConnected = false
        workspaces = []
        windows = []
        activeWindow = null
        windowCount = 0
        this.disconnected()
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("HyprlandService: Initializing...")
        
        // Connect to Hyprland
        connectToHyprland()
        
        initialized = true
        console.log("HyprlandService: Initialization complete")
    }
}