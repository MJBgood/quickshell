pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: gpuService
    
    // Configuration service reference
    property var configService: null
    
    // Public properties - automatically reactive
    property real usage: 0.0
    property real memoryUsed: 0.0
    property real memoryTotal: 0.0
    property real memoryUsage: 0.0  // percentage
    property real clockSpeed: 0.0
    property real memoryClockSpeed: 0.0
    property real temperature: 0.0  // GPU temperature in Celsius
    property string gpuName: "Unknown"
    property string driverVersion: "Unknown"
    property bool ready: false
    
    // GPU vendor detection
    property string vendor: "unknown"  // "nvidia", "amd", "intel", "unknown"
    
    // Update interval (in milliseconds) - reactive to config changes
    property int updateInterval: 2000
    
    // React to config changes
    Connections {
        target: configService
        function onConfigChanged() {
            updateIntervalFromConfig()
        }
    }
    
    onConfigServiceChanged: {
        if (configService) {
            console.log("[GpuService] ConfigService connected, loading polling rate")
            updateIntervalFromConfig()
        }
    }
    
    function updateIntervalFromConfig() {
        if (!configService) return
        
        const newInterval = configService.getValue("ui.monitors.gpu.pollingRate", 2.0) * 1000
        if (updateInterval !== newInterval) {
            updateInterval = newInterval
            updateTimer.interval = newInterval
            console.log("[GpuService] Updated polling rate from config:", newInterval/1000, "seconds")
        }
    }
    
    // GPU monitoring processes
    Process {
        id: nvidiaProcess
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,clocks.gr,clocks.mem,temperature.gpu,name,driver_version", "--format=csv,noheader,nounits"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    gpuService.parseNvidiaOutput(this.text)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[GpuService] nvidia-smi stderr:", this.text.trim())
                }
            }
        }
    }
    
    Process {
        id: amdUsageProcess
        command: ["python3", "/opt/rocm/libexec/rocm_smi/rocm_smi.py", "--showuse", "--json"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    gpuService.parseAmdUsageOutput(this.text)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[GpuService] rocm-smi usage stderr:", this.text.trim())
                }
            }
        }
    }
    
    Process {
        id: amdMemoryProcess
        command: ["python3", "/opt/rocm/libexec/rocm_smi/rocm_smi.py", "--showmeminfo", "vram", "--json"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    gpuService.parseAmdMemoryOutput(this.text)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[GpuService] rocm-smi memory stderr:", this.text.trim())
                }
            }
        }
    }
    
    Process {
        id: amdTemperatureProcess
        command: ["python3", "/opt/rocm/libexec/rocm_smi/rocm_smi.py", "--showtemp", "--json"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    gpuService.parseAmdTemperatureOutput(this.text)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[GpuService] rocm-smi temperature stderr:", this.text.trim())
                }
            }
        }
    }
    
    Process {
        id: intelProcess
        command: ["intel_gpu_top", "-l", "-s", "1000"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    gpuService.parseIntelOutput(this.text)
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("[GpuService] intel_gpu_top stderr:", this.text.trim())
                }
            }
        }
    }
    
    // Timer for periodic updates
    Timer {
        id: updateTimer
        interval: gpuService.updateInterval
        running: true
        repeat: true
        onTriggered: {
            refreshStats()
        }
    }
    
    // GPU vendor detection process
    Process {
        id: vendorDetectionProcess
        command: ["lspci", "-nn"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                gpuService.detectGpuVendor(this.text)
            }
        }
    }
    
    // Parse nvidia-smi output
    function parseNvidiaOutput(output) {
        try {
            const lines = output.trim().split('\n')
            if (lines.length > 0) {
                const parts = lines[0].split(', ')
                if (parts.length >= 8) {
                    usage = parseFloat(parts[0]) || 0
                    memoryUsed = parseFloat(parts[1]) || 0
                    memoryTotal = parseFloat(parts[2]) || 0
                    memoryUsage = memoryTotal > 0 ? (memoryUsed / memoryTotal) * 100 : 0
                    clockSpeed = parseFloat(parts[3]) || 0
                    memoryClockSpeed = parseFloat(parts[4]) || 0
                    temperature = parseFloat(parts[5]) || 0
                    gpuName = parts[6] || "Unknown"
                    driverVersion = parts[7] || "Unknown"
                    ready = true
                }
            }
        } catch (error) {
            console.error("[GpuService] Failed to parse nvidia-smi output:", error)
        }
    }
    
    // Parse rocm-smi usage output (JSON)
    function parseAmdUsageOutput(output) {
        try {
            const data = JSON.parse(output)
            const cardKeys = Object.keys(data)
            
            if (cardKeys.length > 0) {
                const cardData = data[cardKeys[0]]
                if (cardData["GPU use (%)"]) {
                    usage = parseFloat(cardData["GPU use (%)"]) || 0
                    gpuName = "AMD GPU"
                    ready = true
                }
            }
        } catch (error) {
            console.error("[GpuService] Failed to parse rocm-smi usage output:", error)
        }
    }
    
    // Parse rocm-smi memory output (JSON)
    function parseAmdMemoryOutput(output) {
        try {
            const data = JSON.parse(output)
            const cardKeys = Object.keys(data)
            
            if (cardKeys.length > 0) {
                const cardData = data[cardKeys[0]]
                const totalMemory = cardData["VRAM Total Memory (B)"]
                const usedMemory = cardData["VRAM Total Used Memory (B)"]
                
                if (totalMemory && usedMemory) {
                    memoryTotal = parseFloat(totalMemory) || 0
                    memoryUsed = parseFloat(usedMemory) || 0
                    memoryUsage = memoryTotal > 0 ? (memoryUsed / memoryTotal) * 100 : 0
                }
            }
        } catch (error) {
            console.error("[GpuService] Failed to parse rocm-smi memory output:", error)
        }
    }
    
    // Parse rocm-smi temperature output (JSON)
    function parseAmdTemperatureOutput(output) {
        try {
            const data = JSON.parse(output)
            const cardKeys = Object.keys(data)
            
            if (cardKeys.length > 0) {
                const cardData = data[cardKeys[0]]
                const tempData = cardData["Temperature (Sensor edge) (C)"]
                
                if (tempData) {
                    temperature = parseFloat(tempData) || 0
                }
            }
        } catch (error) {
            console.error("[GpuService] Failed to parse rocm-smi temperature output:", error)
        }
    }
    
    // Parse intel_gpu_top output
    function parseIntelOutput(output) {
        try {
            const lines = output.trim().split('\n')
            for (let line of lines) {
                if (line.includes('Render/3D')) {
                    const usageMatch = line.match(/(\d+\.?\d*)%/)
                    if (usageMatch) {
                        usage = parseFloat(usageMatch[1]) || 0
                        gpuName = "Intel GPU"
                        ready = true
                        break
                    }
                }
            }
        } catch (error) {
            console.error("[GpuService] Failed to parse intel_gpu_top output:", error)
        }
    }
    
    // Detect GPU vendor
    function detectGpuVendor(output) {
        try {
            const lines = output.split('\n')
            for (let line of lines) {
                const lowerLine = line.toLowerCase()
                if (lowerLine.includes('vga') || lowerLine.includes('3d') || lowerLine.includes('display')) {
                    if (lowerLine.includes('nvidia')) {
                        vendor = "nvidia"
                        console.log("[GpuService] Detected NVIDIA GPU")
                        return
                    } else if (lowerLine.includes('amd') || lowerLine.includes('radeon')) {
                        vendor = "amd"
                        console.log("[GpuService] Detected AMD GPU")
                        return
                    } else if (lowerLine.includes('intel')) {
                        vendor = "intel"
                        console.log("[GpuService] Detected Intel GPU")
                        return
                    }
                }
            }
            console.log("[GpuService] GPU vendor detection failed, defaulting to unknown")
            vendor = "unknown"
        } catch (error) {
            console.error("[GpuService] Failed to detect GPU vendor:", error)
            vendor = "unknown"
        }
    }
    
    // Public API
    function refreshStats() {
        if (!ready && vendor === "unknown") {
            return  // Don't spam if we can't detect GPU
        }
        
        switch (vendor) {
            case "nvidia":
                if (!nvidiaProcess.running) {
                    nvidiaProcess.running = true
                }
                break
            case "amd":
                if (!amdUsageProcess.running) {
                    amdUsageProcess.running = true
                }
                if (!amdMemoryProcess.running) {
                    amdMemoryProcess.running = true
                }
                if (!amdTemperatureProcess.running) {
                    amdTemperatureProcess.running = true
                }
                break
            case "intel":
                if (!intelProcess.running) {
                    intelProcess.running = true
                }
                break
        }
    }
    
    function getCurrentStats() {
        return {
            usage: usage,
            memoryUsed: memoryUsed,
            memoryTotal: memoryTotal,
            memoryUsage: memoryUsage,
            clockSpeed: clockSpeed,
            memoryClockSpeed: memoryClockSpeed,
            temperature: temperature,
            gpuName: gpuName,
            driverVersion: driverVersion,
            vendor: vendor
        }
    }
    
    function setPollingRate(seconds) {
        const newInterval = seconds * 1000  // Convert to milliseconds
        console.log("[GpuService] Setting polling rate to", seconds, "seconds")
        updateInterval = newInterval
        updateTimer.interval = newInterval
        
        // Save to config
        if (configService) {
            configService.setValue("ui.monitors.gpu.pollingRate", seconds)
            configService.saveConfig()
            console.log("[GpuService] GPU polling rate saved to config")
        }
    }
    
    function getPollingRate() {
        return updateInterval / 1000  // Convert to seconds
    }
    
    Component.onCompleted: {
        console.log("[GpuService] Initialized - will update every", updateInterval/1000, "seconds")
        
        // Detect GPU vendor first
        vendorDetectionProcess.running = true
        
        // Load interval from config once configService is available
        Qt.callLater(() => {
            if (configService) {
                updateIntervalFromConfig()
                console.log("[GpuService] Loaded polling rate from config")
            }
        })
        
        // Initial stats read after vendor detection
        Qt.callLater(() => {
            // Wait a bit for vendor detection to complete
            const timer = Qt.createQmlObject(`
                import QtQuick
                Timer {
                    interval: 1000
                    running: true
                    repeat: false
                    onTriggered: {
                        refreshStats()
                        destroy()
                    }
                }
            `, gpuService)
        })
    }
}