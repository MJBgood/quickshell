pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: powerService
    
    // Configuration service reference
    property var configService: null
    
    // Public properties - automatically reactive
    property bool ready: false
    property bool canSuspend: true
    property bool canHibernate: true
    property bool canReboot: true
    property bool canPowerOff: true
    property bool canLock: true
    property bool canLogout: true
    
    // Internal process for system commands
    Process {
        id: systemProcess
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[PowerManagementService] Command output:", this.text)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    console.error("[PowerManagementService] Command error:", this.text)
                }
            }
        }
    }
    
    // Check system capabilities
    Process {
        id: capabilityChecker
        command: ["loginctl", "list-sessions", "--no-legend"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                // If loginctl works, we have session management
                ready = true
                console.log("[PowerManagementService] System capabilities checked")
            }
        }
    }
    
    // Public API functions
    function powerOff() {
        const confirmAction = configService ? 
            configService.getValue("power.confirmActions", true) : true
            
        if (confirmAction) {
            console.log("[PowerManagementService] Power off requested - confirmation needed")
            // This should trigger confirmation dialog in UI
            return false
        }
        
        console.log("[PowerManagementService] Executing power off")
        systemProcess.command = ["systemctl", "poweroff"]
        systemProcess.running = true
        return true
    }
    
    function reboot() {
        const confirmAction = configService ? 
            configService.getValue("power.confirmActions", true) : true
            
        if (confirmAction) {
            console.log("[PowerManagementService] Reboot requested - confirmation needed")
            return false
        }
        
        console.log("[PowerManagementService] Executing reboot")
        systemProcess.command = ["systemctl", "reboot"]
        systemProcess.running = true
        return true
    }
    
    function suspend() {
        console.log("[PowerManagementService] Executing suspend")
        systemProcess.command = ["systemctl", "suspend"]
        systemProcess.running = true
        return true
    }
    
    function hibernate() {
        console.log("[PowerManagementService] Executing hibernate")
        systemProcess.command = ["systemctl", "hibernate"]
        systemProcess.running = true
        return true
    }
    
    function lockScreen() {
        const lockCommand = configService ? 
            configService.getValue("power.lockCommand", "hyprlock") : "hyprlock"
        
        console.log("[PowerManagementService] Executing screen lock with:", lockCommand)
        systemProcess.command = [lockCommand]
        systemProcess.running = true
        return true
    }
    
    function logout() {
        console.log("[PowerManagementService] Executing logout")
        // Try Hyprland exit first, fallback to loginctl
        if (Hyprland) {
            Hyprland.dispatch("exit")
        } else {
            systemProcess.command = ["loginctl", "terminate-session", "self"]
            systemProcess.running = true
        }
        return true
    }
    
    // Force variants (skip confirmation)
    function forcePowerOff() {
        console.log("[PowerManagementService] Force power off")
        systemProcess.command = ["systemctl", "poweroff"]
        systemProcess.running = true
        return true
    }
    
    function forceReboot() {
        console.log("[PowerManagementService] Force reboot")
        systemProcess.command = ["systemctl", "reboot"]
        systemProcess.running = true
        return true
    }
    
    // Utility functions
    function getAvailableActions() {
        var actions = []
        if (canLock) actions.push("lock")
        if (canLogout) actions.push("logout")
        if (canSuspend) actions.push("suspend")
        if (canHibernate) actions.push("hibernate")
        if (canReboot) actions.push("reboot")
        if (canPowerOff) actions.push("poweroff")
        return actions
    }
    
    function getActionIcon(action) {
        switch (action) {
            case "lock": return "🔒"
            case "logout": return "🚪"
            case "suspend": return "😴"
            case "hibernate": return "💤"
            case "reboot": return "🔄"
            case "poweroff": return "⚡"
            default: return "❓"
        }
    }
    
    function getActionLabel(action) {
        switch (action) {
            case "lock": return "Lock Screen"
            case "logout": return "Log Out"
            case "suspend": return "Suspend"
            case "hibernate": return "Hibernate"
            case "reboot": return "Restart"
            case "poweroff": return "Shut Down"
            default: return "Unknown"
        }
    }
    
    Component.onCompleted: {
        console.log("[PowerManagementService] Initialized")
        ready = true // Assume capabilities are available
        // Optionally check system capabilities later
        // Qt.callLater(() => { capabilityChecker.running = true })
    }
}