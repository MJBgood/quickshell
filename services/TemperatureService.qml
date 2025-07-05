pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: temperatureService
    
    // Configuration service reference
    property var configService: null
    
    // Public properties - automatically reactive
    property real cpuTemp: 0.0
    property real gpuTemp: 0.0
    property string cpuSensor: "Unknown"
    property string gpuSensor: "Unknown"
    property bool ready: false
    
    // Update interval (in milliseconds) - configurable
    property int updateInterval: configService ? 
        configService.getValue("temperature.updateInterval", 10000) : 10000
    
    // Internal process for sensors command
    Process {
        id: sensorsProcess
        command: ["sensors", "-A"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                temperatureService.parseSensorsOutput(this.text)
            }
        }
    }
    
    // Timer for periodic updates
    Timer {
        interval: temperatureService.updateInterval
        running: true
        repeat: true
        onTriggered: {
            if (!sensorsProcess.running) {
                sensorsProcess.running = true
            }
        }
    }
    
    // Parse sensors output
    function parseSensorsOutput(output) {
        try {
            const lines = output.split('\n')
            let currentChip = ""
            
            for (let line of lines) {
                line = line.trim()
                
                // Detect chip headers
                if (line.includes('-pci-') || line.includes('-virtual-')) {
                    currentChip = line
                    continue
                }
                
                // Parse temperature values
                if (line.includes('°C')) {
                    const tempMatch = line.match(/([+-]?\d+\.?\d*)°C/)
                    if (tempMatch) {
                        const temp = parseFloat(tempMatch[1])
                        
                        // CPU temperature detection
                        if (currentChip.includes('k10temp') || currentChip.includes('coretemp')) {
                            if (line.toLowerCase().includes('tctl') || line.toLowerCase().includes('package') || line.toLowerCase().includes('core')) {
                                cpuTemp = temp
                                cpuSensor = currentChip
                            }
                        }
                        
                        // GPU temperature detection
                        else if (currentChip.includes('amdgpu') || currentChip.includes('nvidia')) {
                            if (line.toLowerCase().includes('edge') || line.toLowerCase().includes('gpu') || line.toLowerCase().includes('temp1')) {
                                gpuTemp = temp
                                gpuSensor = currentChip
                            }
                        }
                    }
                }
            }
            
            ready = true
            
        } catch (error) {
            console.error("[TemperatureService] Failed to parse sensors output:", error)
        }
    }
    
    // Public API
    function refreshTemperatures() {
        if (!sensorsProcess.running) {
            sensorsProcess.running = true
        }
    }
    
    function setUpdateInterval(interval) {
        updateInterval = Math.max(1000, interval) // Minimum 1 second
        if (configService) {
            configService.setValue("temperature.updateInterval", updateInterval)
        }
    }
    
    // Temperature status helpers with configurable thresholds
    function getCpuStatus() {
        const warmThreshold = configService ? 
            configService.getValue("temperature.thresholds.cpu.warm", 65) : 65
        const hotThreshold = configService ? 
            configService.getValue("temperature.thresholds.cpu.hot", 80) : 80
        const criticalThreshold = configService ? 
            configService.getValue("temperature.thresholds.cpu.critical", 90) : 90
            
        if (cpuTemp < warmThreshold) return "cool"
        if (cpuTemp < hotThreshold) return "warm" 
        if (cpuTemp < criticalThreshold) return "hot"
        return "critical"
    }
    
    function getGpuStatus() {
        const warmThreshold = configService ? 
            configService.getValue("temperature.thresholds.gpu.warm", 70) : 70
        const hotThreshold = configService ? 
            configService.getValue("temperature.thresholds.gpu.hot", 85) : 85
        const criticalThreshold = configService ? 
            configService.getValue("temperature.thresholds.gpu.critical", 95) : 95
            
        if (gpuTemp < warmThreshold) return "cool"
        if (gpuTemp < hotThreshold) return "warm"
        if (gpuTemp < criticalThreshold) return "hot" 
        return "critical"
    }
    
    Component.onCompleted: {
        console.log("[TemperatureService] Initialized - will update every", updateInterval/1000, "seconds")
        // Initial temperature read
        Qt.callLater(() => { sensorsProcess.running = true })
    }
}