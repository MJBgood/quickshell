import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: windowTracker
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.hyprland.windowtracker"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Service state
    property bool initialized: false
    property var windowsByWorkspace: ({})
    property int totalWindows: 0
    
    // Signals
    signal windowsUpdated()
    signal windowAdded(var window)
    signal windowRemoved(var window)
    signal windowMoved(var window, int fromWorkspace, int toWorkspace)
    
    // Process for getting window information
    Process {
        id: clientsProcess
        command: ["hyprctl", "clients", "-j"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text.trim().length === 0) {
                        console.warn(logCategory, "Empty response from hyprctl clients")
                        return
                    }
                    
                    const windows = JSON.parse(this.text)
                    processWindowData(windows)
                } catch (error) {
                    console.error(logCategory, "Failed to parse window data:", error)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn(logCategory, "hyprctl stderr:", this.text)
                }
            }
        }
    }
    
    // Process window data and update workspace mappings
    function processWindowData(windows) {
        const byWorkspace = {}
        let total = 0
        
        windows.forEach(window => {
            // Extract workspace ID - handle both object and numeric formats
            let workspaceId
            if (typeof window.workspace === 'object' && window.workspace.id !== undefined) {
                workspaceId = window.workspace.id
            } else if (typeof window.workspace === 'number') {
                workspaceId = window.workspace
            } else {
                console.warn(logCategory, "Unknown workspace format for window:", window.title)
                return
            }
            
            if (!byWorkspace[workspaceId]) {
                byWorkspace[workspaceId] = []
            }
            
            byWorkspace[workspaceId].push({
                class: window.class || "unknown",
                title: window.title || "Unknown Window",
                pid: window.pid || 0,
                address: window.address || "",
                workspace: workspaceId
            })
            
            total++
        })
        
        // Update properties
        windowsByWorkspace = byWorkspace
        totalWindows = total
        
        console.log(logCategory, `Updated window tracking: ${total} windows across ${Object.keys(byWorkspace).length} workspaces`)
        windowsUpdated()
    }
    
    // Public API functions
    function getWindowsForWorkspace(workspaceId) {
        return windowsByWorkspace[workspaceId] || []
    }
    
    function getWindowCountForWorkspace(workspaceId) {
        const windows = windowsByWorkspace[workspaceId] || []
        return windows.length
    }
    
    function getApplicationsForWorkspace(workspaceId) {
        const windows = windowsByWorkspace[workspaceId] || []
        const apps = {}
        
        windows.forEach(window => {
            const className = window.class || "unknown"
            apps[className] = (apps[className] || 0) + 1
        })
        
        return apps
    }
    
    function refreshWindows() {
        console.log(logCategory, "Refreshing window information...")
        clientsProcess.running = true
    }
    
    // Listen to Hyprland events for real-time updates
    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // Update on window-related events
            switch (event.name) {
                case "openwindow":
                case "closewindow":
                case "movewindow":
                case "changefloatingmode":
                case "urgent":
                    // Small delay to ensure Hyprland state is updated
                    refreshTimer.restart()
                    break
                    
                case "workspace":
                case "focusedmon":
                    // Workspace changes might affect window visibility
                    refreshTimer.restart()
                    break
                    
                default:
                    // Log other events for debugging if needed
                    // console.log(logCategory, `Hyprland event: ${event.name}`)
                    break
            }
        }
    }
    
    // Timer to debounce rapid window changes
    Timer {
        id: refreshTimer
        interval: 100 // 100ms delay (reduced from 200ms)
        running: false
        repeat: false
        onTriggered: refreshWindows()
    }
    
    // Periodic refresh fallback (every 30 seconds)
    Timer {
        id: periodicRefresh
        interval: 30000 // 30 seconds
        running: initialized
        repeat: true
        onTriggered: {
            console.log(logCategory, "Periodic window refresh")
            refreshWindows()
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log(logCategory, "Initializing Hyprland window tracker...")
        
        // Start tracking immediately
        initialized = true
        
        // Trigger initial refresh with small delay to ensure Hyprland is ready
        initialLoadTimer.start()
        
        console.log(logCategory, "Window tracker initialization complete")
    }
    
    // Initial load timer
    Timer {
        id: initialLoadTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            console.log(logCategory, "Starting initial window data collection...")
            refreshWindows()
        }
    }
    
    Component.onDestruction: {
        console.log(logCategory, "Window tracker shutting down")
    }
}