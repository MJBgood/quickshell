pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: batteryService
    
    // Public properties - automatically reactive
    property real percentage: 0.0
    property bool charging: false
    property bool present: false
    property string state: "Unknown"
    property int timeToEmpty: 0 // in minutes
    property int timeToFull: 0 // in minutes
    property real energy: 0.0
    property real energyCapacity: 0.0
    property string iconName: "battery-missing"
    property bool ready: false
    
    // Battery device reference
    property var battery: null
    
    // UPower monitoring
    Connections {
        target: UPower.devices
        function onValuesChanged() { updateBattery() }
    }
    
    // Also monitor UPower display device readiness
    Connections {
        target: UPower.displayDevice
        function onReadyChanged() { if (UPower.displayDevice.ready) updateBattery() }
    }
    
    // Monitor battery device changes
    Connections {
        target: batteryService.battery
        function onPercentageChanged() { if (batteryService.battery) updateBatteryInfo() }
        function onStateChanged() { if (batteryService.battery) updateBatteryInfo() }
        function onTimeToEmptyChanged() { if (batteryService.battery) updateBatteryInfo() }
        function onTimeToFullChanged() { if (batteryService.battery) updateBatteryInfo() }
    }
    
    // Internal functions
    function updateBattery() {
        // First try display device (most reliable)
        if (UPower.displayDevice && UPower.displayDevice.ready) {
            battery = UPower.displayDevice
            updateBatteryInfo()
            ready = true
            return
        }
        
        // Find the main battery device
        if (UPower.devices && UPower.devices.count > 0) {
            for (let i = 0; i < UPower.devices.count; i++) {
                const device = UPower.devices.get(i)
                if (device && device.isLaptopBattery && device.ready) {
                    battery = device
                    updateBatteryInfo()
                    ready = true
                    return
                }
            }
        }
    }
    
    function updateBatteryInfo() {
        if (!battery) {
            percentage = 0.0
            charging = false
            present = false
            state = "Unknown"
            timeToEmpty = 0
            timeToFull = 0
            energy = 0.0
            energyCapacity = 0.0
            iconName = "battery-missing"
            return
        }
        
        percentage = (battery.percentage || 0.0) * 100
        present = battery.isPresent || false
        energy = battery.energy || 0.0
        energyCapacity = battery.energyCapacity || 0.0
        iconName = battery.iconName || "battery-missing"
        
        
        // Convert time from seconds to minutes
        timeToEmpty = battery.timeToEmpty ? Math.round(battery.timeToEmpty / 60) : 0
        timeToFull = battery.timeToFull ? Math.round(battery.timeToFull / 60) : 0
        
        // Determine charging state and status text
        const deviceState = battery.state
        switch (deviceState) {
            case UPowerDeviceState.Charging:
                charging = true
                state = "Charging"
                break
            case UPowerDeviceState.Discharging:
                charging = false
                state = "Discharging"
                break
            case UPowerDeviceState.Empty:
                charging = false
                state = "Empty"
                break
            case UPowerDeviceState.FullyCharged:
                charging = false
                state = "Full"
                break
            case UPowerDeviceState.PendingCharge:
                charging = true
                state = "Pending Charge"
                break
            case UPowerDeviceState.PendingDischarge:
                charging = false
                state = "Pending Discharge"
                break
            default:
                charging = false
                state = "Unknown"
        }
    }
    
    // Public API
    function getBatteryStatus() {
        if (!present) return "not-present"
        if (percentage > 80) return "high"
        if (percentage > 40) return "medium"
        if (percentage > 15) return "low"
        return "critical"
    }
    
    function getEstimatedTime() {
        if (charging && timeToFull > 0) {
            const hours = Math.floor(timeToFull / 60)
            const minutes = timeToFull % 60
            return `${hours}h ${minutes}m until full`
        } else if (!charging && timeToEmpty > 0) {
            const hours = Math.floor(timeToEmpty / 60)
            const minutes = timeToEmpty % 60
            return `${hours}h ${minutes}m remaining`
        }
        return ""
    }
    
    Component.onCompleted: {
        console.log("[BatteryService] Initialized")
        updateBattery()
    }
}