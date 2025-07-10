pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: storageService
    
    // Public properties - automatically reactive
    property real usagePercentage: 0.0
    property real usedBytes: 0
    property real totalBytes: 0
    property real availableBytes: 0
    property string usageDisplay: "0%"
    property string usedDisplay: "0 GB"
    property string totalDisplay: "0 GB"
    property string availableDisplay: "0 GB"
    property string mountPoint: "/"
    property bool ready: false
    
    // Internal reference to system monitor
    property var systemMonitor: null
    
    // Connect to system monitor updates
    Connections {
        target: storageService.systemMonitor
        enabled: storageService.systemMonitor !== null
        
        function onStorageUpdated(used, total, available, percentage, mount) {
            // Convert GB to bytes (SystemMonitorService provides data in GB)
            storageService.usedBytes = (used || 0) * 1024 * 1024 * 1024
            storageService.totalBytes = (total || 0) * 1024 * 1024 * 1024
            storageService.availableBytes = (available || 0) * 1024 * 1024 * 1024
            storageService.usagePercentage = percentage || 0
            storageService.mountPoint = mount || "/"
            
            // Update display strings with safe values
            storageService.usageDisplay = (percentage || 0).toFixed(1) + "%"
            storageService.usedDisplay = formatBytes(storageService.usedBytes)
            storageService.totalDisplay = formatBytes(storageService.totalBytes)
            storageService.availableDisplay = formatBytes(storageService.availableBytes)
        }
    }
    
    // Watch for system monitor service changes
    onSystemMonitorChanged: {
        if (systemMonitor) {
            const stats = systemMonitor.getCurrentStats()
            if (stats && stats.storage) {
                // Convert GB to bytes (SystemMonitorService provides data in GB)
                usedBytes = (stats.storage.used || 0) * 1024 * 1024 * 1024
                totalBytes = (stats.storage.total || 0) * 1024 * 1024 * 1024
                availableBytes = (stats.storage.available || 0) * 1024 * 1024 * 1024
                usagePercentage = stats.storage.percentage || stats.storage.percent || 0
                mountPoint = stats.storage.mountPoint || "/"
                
                // Update display strings with safe values
                usageDisplay = (usagePercentage || 0).toFixed(1) + "%"
                usedDisplay = formatBytes(usedBytes)
                totalDisplay = formatBytes(totalBytes)
                availableDisplay = formatBytes(availableBytes)
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
            availableDisplay: availableDisplay,
            mountPoint: mountPoint
        }
    }
    
    function refreshStats() {
        if (systemMonitor && typeof systemMonitor.refreshStorageStats === 'function') {
            systemMonitor.refreshStorageStats()
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