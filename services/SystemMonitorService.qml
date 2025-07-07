import QtQuick
import QtCore
import Quickshell.Io

Item {
    id: systemMonitorService
    
    // Configuration service reference
    property var configService: null
    
    onConfigServiceChanged: {
        if (configService) {
            console.log(logCategory, "ConfigService connected, loading polling rates")
            updateIntervalsFromConfig()
        }
    }
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.systemmonitor"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Service state
    property bool initialized: false
    property bool monitoring: false
    
    // Update intervals (in milliseconds) - reactive to config changes
    property int cpuUpdateInterval: 2000
    property int ramUpdateInterval: 2000
    property int storageUpdateInterval: 30000
    
    // React to config changes
    Connections {
        target: configService
        function onConfigChanged() {
            updateIntervalsFromConfig()
        }
    }
    
    function updateIntervalsFromConfig() {
        if (!configService) {
            console.log(logCategory, "No configService available for loading intervals")
            return
        }
        
        const newCpuInterval = configService.getValue("ui.monitors.cpu.pollingRate", 2.0) * 1000
        const newRamInterval = configService.getValue("ui.monitors.ram.pollingRate", 2.0) * 1000
        const newStorageInterval = configService.getValue("ui.monitors.storage.pollingRate", 30.0) * 1000
        
        console.log(logCategory, "Loading from config - CPU:", newCpuInterval/1000+"s", "RAM:", newRamInterval/1000+"s", "Storage:", newStorageInterval/1000+"s")
        
        if (cpuUpdateInterval !== newCpuInterval) {
            console.log(logCategory, "Updating CPU interval from", cpuUpdateInterval/1000+"s", "to", newCpuInterval/1000+"s")
            cpuUpdateInterval = newCpuInterval
            cpuTimer.interval = newCpuInterval
        }
        
        if (ramUpdateInterval !== newRamInterval) {
            console.log(logCategory, "Updating RAM interval from", ramUpdateInterval/1000+"s", "to", newRamInterval/1000+"s")
            ramUpdateInterval = newRamInterval
            ramTimer.interval = newRamInterval
        }
        
        if (storageUpdateInterval !== newStorageInterval) {
            console.log(logCategory, "Updating Storage interval from", storageUpdateInterval/1000+"s", "to", newStorageInterval/1000+"s")
            storageUpdateInterval = newStorageInterval
            storageTimer.interval = newStorageInterval
        }
    }
    
    // Current system stats
    property real cpuUsage: 0.0
    property real cpuFrequency: 0.0
    property var cpuCores: []
    property real ramUsed: 0.0
    property real ramTotal: 0.0
    property real ramUsagePercent: 0.0
    property real storageUsed: 0.0
    property real storageTotal: 0.0
    property real storageUsagePercent: 0.0
    
    // Formatted display strings
    property string cpuDisplay: "0%"
    property string cpuFrequencyDisplay: "0 GHz"
    property string ramDisplay: "0 GB"
    property string storageDisplay: "0 GB"
    
    // Signals for components to subscribe to
    signal cpuUpdated(real percentage)
    signal cpuFrequencyUpdated(real frequency, string display)
    signal ramUpdated(real used, real total, real percentage)
    signal storageUpdated(real used, real total, real percentage)
    signal errorOccurred(string component, string error)
    
    // CPU monitoring with per-core stats and frequency
    Process {
        id: cpuMonitor
        
        
        // Optimized CPU monitoring command - reduced complexity
        command: ["sh", "-c", 
            "echo '=== CPU_USAGE ===' && " +
            "awk '/^cpu / {printf \"%.1f\\n\", 100-($5*100/($2+$3+$4+$5+$6+$7+$8))}' /proc/stat && " +
            "echo '=== CPU_FREQ ===' && " +
            "(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | awk '{print $1/1000}' || echo '0')"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                if (output) {
                    try {
                        const sections = output.split("=== ")
                        let totalUsage = 0
                        let cores = []
                        let frequency = 0
                        
                        for (const section of sections) {
                            if (section.startsWith("CPU_USAGE ===")) {
                                const lines = section.split("\n")  // Use regular \n, not \\n
                                if (lines.length > 1) {
                                    const usageStr = lines[1].trim()
                                    totalUsage = parseFloat(usageStr)
                                }
                            } else if (section.startsWith("CPU_CORES ===")) {
                                const coreLines = section.split("\n").slice(1).filter(line => line.includes(":"))
                                cores = coreLines.map(line => {
                                    const [name, usage] = line.split(":")
                                    return {
                                        name: name.replace("cpu", "Core "),
                                        usage: parseFloat(usage) || 0
                                    }
                                })
                            } else if (section.startsWith("CPU_FREQ ===")) {
                                const lines = section.split("\n")  // Use regular \n, not \\n
                                if (lines.length > 1) {
                                    const freqStr = lines[1].trim()
                                    if (freqStr && freqStr !== "") {
                                        frequency = parseFloat(freqStr) / 1000 // Convert MHz to GHz
                                    }
                                }
                            }
                        }
                        
                        if (!isNaN(totalUsage) && totalUsage >= 0 && totalUsage <= 100) {
                            cpuUsage = totalUsage
                            cpuDisplay = Math.round(totalUsage) + "%"
                            cpuUpdated(totalUsage)
                        }
                        
                        if (cores.length > 0) {
                            cpuCores = cores
                        }
                        
                        if (!isNaN(frequency) && frequency > 0) {
                            cpuFrequency = frequency
                            cpuFrequencyDisplay = frequency.toFixed(1) + "GHz"
                            cpuFrequencyUpdated(frequency, cpuFrequencyDisplay)
                        }
                        
                    } catch (error) {
                        console.warn(logCategory, "Failed to parse CPU data:", error)
                        errorOccurred("cpu", "Parse error: " + error)
                    }
                }
            }
        }
    }
    
    // RAM monitoring using /proc/meminfo
    Process {
        id: ramMonitor
        command: ["sh", "-c", "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable' | awk '{print $2}'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n')
                if (lines.length >= 2) {
                    try {
                        const totalKb = parseFloat(lines[0])
                        const availableKb = parseFloat(lines[1])
                        
                        if (!isNaN(totalKb) && !isNaN(availableKb)) {
                            ramTotal = totalKb / 1024 / 1024  // Convert to GB
                            const usedKb = totalKb - availableKb
                            ramUsed = usedKb / 1024 / 1024    // Convert to GB
                            ramUsagePercent = (usedKb / totalKb) * 100
                            
                            ramDisplay = ramUsed.toFixed(1) + "/" + ramTotal.toFixed(1) + " GB"
                            ramUpdated(ramUsed, ramTotal, ramUsagePercent)
                        }
                    } catch (error) {
                        console.warn(logCategory, "Failed to parse RAM usage:", error)
                        errorOccurred("ram", "Parse error: " + error)
                    }
                }
            }
        }
    }
    
    // Storage monitoring using df command for root filesystem
    Process {
        id: storageMonitor
        command: ["sh", "-c", "df -h / | tail -1 | awk '{print $2 \"\\n\" $3 \"\\n\" $5}' | sed 's/%//'"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n')
                if (lines.length >= 3) {
                    try {
                        const totalStr = lines[0]
                        const usedStr = lines[1]
                        const percentStr = lines[2]
                        
                        // Parse human-readable sizes (e.g., "100G", "50M")
                        const totalGB = parseHumanSize(totalStr)
                        const usedGB = parseHumanSize(usedStr)
                        const percent = parseFloat(percentStr)
                        
                        if (!isNaN(totalGB) && !isNaN(usedGB) && !isNaN(percent)) {
                            storageTotal = totalGB
                            storageUsed = usedGB
                            storageUsagePercent = percent
                            
                            storageDisplay = usedGB.toFixed(1) + "/" + totalGB.toFixed(1) + " GB"
                            storageUpdated(usedGB, totalGB, percent)
                        }
                    } catch (error) {
                        console.warn(logCategory, "Failed to parse storage usage:", error)
                        errorOccurred("storage", "Parse error: " + error)
                    }
                }
            }
        }
    }
    
    // Helper function to parse human-readable sizes (K, M, G, T)
    function parseHumanSize(sizeStr) {
        const match = sizeStr.match(/^(\d+(?:\.\d+)?)\s*([KMGT]?)$/i)
        if (!match) return 0
        
        const value = parseFloat(match[1])
        const unit = match[2].toUpperCase()
        
        switch (unit) {
            case 'K': return value / 1024 / 1024  // KB to GB
            case 'M': return value / 1024         // MB to GB
            case 'G': return value               // GB
            case 'T': return value * 1024        // TB to GB
            default: return value / 1024 / 1024 / 1024  // Bytes to GB
        }
    }
    
    // Timer-based updates
    Timer {
        id: cpuTimer
        interval: cpuUpdateInterval
        repeat: true
        running: monitoring
        onTriggered: cpuMonitor.running = true
    }
    
    Timer {
        id: ramTimer
        interval: ramUpdateInterval
        repeat: true
        running: monitoring
        onTriggered: ramMonitor.running = true
    }
    
    Timer {
        id: storageTimer
        interval: storageUpdateInterval
        repeat: true
        running: monitoring
        onTriggered: storageMonitor.running = true
    }
    
    // Public API
    function startMonitoring() {
        if (monitoring) return
        
        console.log(logCategory, "Starting system monitoring")
        monitoring = true
        
        // Initial updates
        cpuMonitor.running = true
        ramMonitor.running = true
        storageMonitor.running = true
    }
    
    function stopMonitoring() {
        if (!monitoring) return
        
        console.log(logCategory, "Stopping system monitoring")
        monitoring = false
    }
    
    function updateCpuInterval(intervalMs) {
        cpuUpdateInterval = Math.max(1000, intervalMs) // Minimum 1 second
        cpuTimer.interval = cpuUpdateInterval
    }
    
    function updateRamInterval(intervalMs) {
        ramUpdateInterval = Math.max(1000, intervalMs) // Minimum 1 second
        ramTimer.interval = ramUpdateInterval
    }
    
    function updateStorageInterval(intervalMs) {
        storageUpdateInterval = Math.max(5000, intervalMs) // Minimum 5 seconds
        storageTimer.interval = storageUpdateInterval
    }
    
    // Get current stats for immediate access
    function getCurrentStats() {
        return {
            cpu: {
                usage: cpuUsage,
                frequency: cpuFrequency,
                cores: cpuCores,
                display: cpuDisplay,
                frequencyDisplay: cpuFrequencyDisplay
            },
            ram: {
                used: ramUsed,
                total: ramTotal,
                percent: ramUsagePercent,
                display: ramDisplay
            },
            storage: {
                used: storageUsed,
                total: storageTotal,
                percent: storageUsagePercent,
                display: storageDisplay
            }
        }
    }
    
    // Polling rate control functions with config persistence
    function setCpuPollingRate(seconds) {
        const newInterval = seconds * 1000  // Convert to milliseconds
        console.log(logCategory, "Setting CPU polling rate to", seconds, "seconds")
        cpuUpdateInterval = newInterval
        cpuTimer.interval = newInterval
        
        // Save to config
        if (configService && configService.setValue("ui.monitors.cpu.pollingRate", seconds)) {
            configService.saveConfig()
            console.log(logCategory, "CPU polling rate saved to config")
        }
    }
    
    function setRamPollingRate(seconds) {
        const newInterval = seconds * 1000  // Convert to milliseconds
        console.log(logCategory, "Setting RAM polling rate to", seconds, "seconds")
        ramUpdateInterval = newInterval
        ramTimer.interval = newInterval
        
        // Save to config
        if (configService && configService.setValue("ui.monitors.ram.pollingRate", seconds)) {
            configService.saveConfig()
            console.log(logCategory, "RAM polling rate saved to config")
        }
    }
    
    function setStoragePollingRate(seconds) {
        const newInterval = seconds * 1000  // Convert to milliseconds
        console.log(logCategory, "Setting Storage polling rate to", seconds, "seconds")
        storageUpdateInterval = newInterval
        storageTimer.interval = newInterval
        
        // Save to config
        if (configService && configService.setValue("ui.monitors.storage.pollingRate", seconds)) {
            configService.saveConfig()
            console.log(logCategory, "Storage polling rate saved to config")
        }
    }
    
    function getCpuPollingRate() {
        return cpuUpdateInterval / 1000  // Convert to seconds
    }
    
    function getRamPollingRate() {
        return ramUpdateInterval / 1000  // Convert to seconds
    }
    
    function getStoragePollingRate() {
        return storageUpdateInterval / 1000  // Convert to seconds
    }
    
    Component.onCompleted: {
        console.log(logCategory, "SystemMonitorService Component.onCompleted starting")
        console.log(logCategory, "Initialized")
        initialized = true
        
        // Load intervals from config once configService is available
        Qt.callLater(() => {
            console.log(logCategory, "Qt.callLater executing, configService:", !!configService)
            if (configService) {
                updateIntervalsFromConfig()
                console.log(logCategory, "Loaded polling rates from config")
            }
        })
        
        // Start monitoring by default
        console.log(logCategory, "About to call startMonitoring()")
        startMonitoring()
        console.log(logCategory, "SystemMonitorService Component.onCompleted finished")
    }
}