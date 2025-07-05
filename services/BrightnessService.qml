pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: brightnessService
    
    // Public properties - automatically reactive
    property real brightness: 0.0
    property real maxBrightness: 255.0
    property bool ready: false
    
    // Process to get current brightness
    Process {
        id: getBrightnessProcess
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(this.text.trim())
                if (!isNaN(value)) {
                    brightnessService.brightness = value / brightnessService.maxBrightness
                }
            }
        }
    }
    
    // Process to get max brightness
    Process {
        id: getMaxBrightnessProcess
        command: ["brightnessctl", "max"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(this.text.trim())
                if (!isNaN(value)) {
                    brightnessService.maxBrightness = value
                    getBrightnessProcess.running = true
                    brightnessService.ready = true
                }
            }
        }
    }
    
    // Process to set brightness
    Process {
        id: setBrightnessProcess
        onExited: {
            Qt.callLater(() => getBrightnessProcess.running = true)
        }
    }
    
    // Public API
    function setBrightness(newBrightness) {
        const clamped = Math.max(0.0, Math.min(1.0, newBrightness))
        const value = Math.round(clamped * maxBrightness)
        try {
            setBrightnessProcess.command = ["brightnessctl", "set", `${value}`]
            setBrightnessProcess.running = true
            return true
        } catch (error) {
            console.error(`[BrightnessService] Failed to set brightness:`, error)
            return false
        }
    }
    
    function adjustBrightness(delta) {
        return setBrightness(brightness + delta)
    }
    
    function cycleBrightness() {
        if (brightness <= 0.3) return setBrightness(0.6)
        if (brightness <= 0.6) return setBrightness(1.0)
        return setBrightness(0.3)
    }
    
    function updateBrightness() {
        if (ready) getBrightnessProcess.running = true
    }
    
    // Update timer
    Timer {
        interval: 10000
        running: brightnessService.ready
        repeat: true
        onTriggered: brightnessService.updateBrightness()
    }
    
    Component.onCompleted: getMaxBrightnessProcess.running = true
}