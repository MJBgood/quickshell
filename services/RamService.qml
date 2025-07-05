pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: ramService
    
    // Public properties - automatically reactive
    property real usagePercentage: 0.0
    property real usedBytes: 0
    property real totalBytes: 0
    property real availableBytes: 0
    property string usageDisplay: "0%"
    property string usedDisplay: "0 MB"
    property string totalDisplay: "0 MB"
    property string availableDisplay: "0 MB"
    property bool ready: false
    
    // Internal reference to system monitor
    property var systemMonitor: null
    
    // Connect to system monitor updates
    Connections {
        target: ramService.systemMonitor
        enabled: ramService.systemMonitor !== null
        
        function onRamUpdated(used, total, available, percentage) {
            ramService.usedBytes = used || 0
            ramService.totalBytes = total || 0
            ramService.availableBytes = available || 0
            ramService.usagePercentage = percentage || 0
            
            // Update display strings with safe values
            ramService.usageDisplay = (percentage || 0).toFixed(1) + "%"
            ramService.usedDisplay = formatBytes(used || 0)
            ramService.totalDisplay = formatBytes(total || 0)
            ramService.availableDisplay = formatBytes(available || 0)
        }
    }
    
    // Watch for system monitor service changes
    onSystemMonitorChanged: {
        if (systemMonitor) {
            const stats = systemMonitor.getCurrentStats()
            if (stats && stats.ram) {
                usedBytes = stats.ram.used || 0
                totalBytes = stats.ram.total || 0
                availableBytes = stats.ram.available || 0
                usagePercentage = stats.ram.percentage || stats.ram.percent || 0
                
                // Update display strings with safe values
                usageDisplay = (usagePercentage || 0).toFixed(1) + "%"
                usedDisplay = formatBytes(usedBytes || 0)
                totalDisplay = formatBytes(totalBytes || 0)
                availableDisplay = formatBytes(availableBytes || 0)
                ready = true
            }
        }
    }
    
    // Public API
    function bindToSystemMonitor(monitor) {
        systemMonitor = monitor
    }
    
    function getCurrentStats() {
        return {
            usagePercentage: usagePercentage,
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            availableBytes: availableBytes,
            usageDisplay: usageDisplay,
            usedDisplay: usedDisplay,
            totalDisplay: totalDisplay,
            availableDisplay: availableDisplay
        }
    }
    
    function refreshStats() {
        if (systemMonitor && typeof systemMonitor.refreshRamStats === 'function') {
            systemMonitor.refreshRamStats()
        }
    }
    
    // Helper function to format bytes
    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        
        const units = ["B", "KB", "MB", "GB", "TB"]
        const k = 1024
        const dm = 1
        
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + units[i]
    }
}