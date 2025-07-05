pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: cpuService
    
    // Public properties - automatically reactive
    property real usage: 0.0
    property real frequency: 0.0
    property string frequencyDisplay: ""
    property var cores: []
    property bool ready: false
    
    // Internal reference to system monitor
    property var systemMonitor: null
    
    // Connect to system monitor updates
    Connections {
        target: cpuService.systemMonitor
        enabled: cpuService.systemMonitor !== null
        
        function onCpuUpdated(percentage) {
            cpuService.usage = percentage || 0
        }
        
        function onCpuFrequencyUpdated(freq, display) {
            cpuService.frequency = freq || 0
            cpuService.frequencyDisplay = display || ""
        }
    }
    
    // Watch for system monitor service changes
    onSystemMonitorChanged: {
        if (systemMonitor) {
            const stats = systemMonitor.getCurrentStats()
            if (stats && stats.cpu) {
                usage = stats.cpu.usage || 0
                frequency = stats.cpu.frequency || 0
                frequencyDisplay = stats.cpu.frequencyDisplay || ""
                cores = stats.cpu.cores || []
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
            usage: usage,
            frequency: frequency,
            frequencyDisplay: frequencyDisplay,
            cores: cores
        }
    }
    
    function refreshStats() {
        if (systemMonitor && typeof systemMonitor.refreshCpuStats === 'function') {
            systemMonitor.refreshCpuStats()
        }
    }
}