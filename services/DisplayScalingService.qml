pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: displayScaling
    
    // Reactive properties
    property real recommendedScale: 1.0
    property real currentDpi: 96.0
    property real physicalDpi: 96.0
    property string scaleReason: "Default"
    property bool ready: false
    
    // DPI reference standards
    readonly property real standardDpi: 96.0      // Windows/Linux standard
    readonly property real retinaThreshold: 220.0 // High DPI threshold
    readonly property real lowDpiThreshold: 72.0   // Low DPI threshold
    
    // Scale recommendations based on DPI ranges
    readonly property var scaleRecommendations: ({
        "ultra-low": { min: 0, max: 80, scale: 0.75, reason: "Very Low DPI Display" },
        "low": { min: 80, max: 110, scale: 1.0, reason: "Standard DPI Display" },
        "medium": { min: 110, max: 140, scale: 1.25, reason: "Medium DPI Display" },
        "high": { min: 140, max: 180, scale: 1.5, reason: "High DPI Display" },
        "very-high": { min: 180, max: 250, scale: 2.0, reason: "Very High DPI Display" },
        "ultra-high": { min: 250, max: 350, scale: 2.5, reason: "Ultra High DPI Display" },
        "extreme": { min: 350, max: 9999, scale: 3.0, reason: "Extreme DPI Display" }
    })
    
    function analyzePrimaryScreen() {
        if (!Quickshell.screens || Quickshell.screens.length === 0) {
            console.warn("[DisplayScalingService] No screens available")
            return
        }
        
        const screen = Quickshell.screens[0]
        
        // Calculate physical DPI from screen properties
        // physicalPixelDensity is pixels per mm, convert to pixels per inch
        physicalDpi = screen.physicalPixelDensity * 25.4
        
        // Current logical DPI (what the system thinks it is)
        currentDpi = screen.logicalPixelDensity * 25.4
        
        // Find recommended scale based on physical DPI
        const recommendation = getScaleRecommendation(physicalDpi)
        recommendedScale = recommendation.scale
        scaleReason = recommendation.reason
        
        ready = true
        
        console.log(`[DisplayScalingService] Display Analysis:`)
        console.log(`  Screen: ${screen.name} (${screen.width}x${screen.height})`)
        console.log(`  Physical DPI: ${physicalDpi.toFixed(1)}`)
        console.log(`  Current DPI: ${currentDpi.toFixed(1)}`)
        console.log(`  Device Pixel Ratio: ${screen.devicePixelRatio}`)
        console.log(`  Recommended Scale: ${recommendedScale}x (${scaleReason})`)
        console.log(`  Physical Size: ${getPhysicalSize(screen)}`)
    }
    
    function getScaleRecommendation(dpi) {
        for (const [key, rec] of Object.entries(scaleRecommendations)) {
            if (dpi >= rec.min && dpi < rec.max) {
                return rec
            }
        }
        return scaleRecommendations["low"] // fallback
    }
    
    function getPhysicalSize(screen) {
        if (!screen.physicalPixelDensity || screen.physicalPixelDensity === 0) {
            return "Unknown"
        }
        
        // Convert pixels to physical dimensions
        const widthMm = screen.width / screen.physicalPixelDensity
        const heightMm = screen.height / screen.physicalPixelDensity
        const widthInches = widthMm / 25.4
        const heightInches = heightMm / 25.4
        const diagonal = Math.sqrt(widthInches * widthInches + heightInches * heightInches)
        
        return `${widthMm.toFixed(0)}×${heightMm.toFixed(0)}mm (${diagonal.toFixed(1)}" diagonal)`
    }
    
    function getAllScreensAnalysis() {
        if (!Quickshell.screens) return []
        
        return Quickshell.screens.map(screen => {
            const physDpi = screen.physicalPixelDensity * 25.4
            const logDpi = screen.logicalPixelDensity * 25.4
            const recommendation = getScaleRecommendation(physDpi)
            
            return {
                name: screen.name,
                model: screen.model,
                resolution: `${screen.width}×${screen.height}`,
                physicalDpi: physDpi,
                logicalDpi: logDpi,
                devicePixelRatio: screen.devicePixelRatio,
                recommendedScale: recommendation.scale,
                reason: recommendation.reason,
                physicalSize: getPhysicalSize(screen),
                currentScale: screen.devicePixelRatio
            }
        })
    }
    
    function getDpiCategory(dpi) {
        const recommendation = getScaleRecommendation(dpi)
        return Object.keys(scaleRecommendations).find(key => 
            scaleRecommendations[key] === recommendation
        ) || "unknown"
    }
    
    function getOptimalScaleForSize(screenWidth, screenHeight, physicalDpi) {
        // Additional logic for considering screen size vs DPI
        // Larger screens can handle higher DPI better than small ones
        const diagonal = Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight) / physicalDpi / 25.4
        
        let adjustment = 1.0
        if (diagonal < 15) {      // Small screens (laptop)
            adjustment = 1.1      // Slightly higher scaling
        } else if (diagonal > 27) { // Large screens (desktop)
            adjustment = 0.9      // Slightly lower scaling
        }
        
        const baseRecommendation = getScaleRecommendation(physicalDpi)
        return Math.round(baseRecommendation.scale * adjustment * 4) / 4 // Round to nearest 0.25
    }
    
    Component.onCompleted: {
        console.log("[DisplayScalingService] Initializing...")
        
        // Wait for Quickshell.screens to be available
        if (Quickshell.screens && Quickshell.screens.length > 0) {
            analyzePrimaryScreen()
        } else {
            // Retry after a short delay
            Qt.callLater(() => {
                if (Quickshell.screens && Quickshell.screens.length > 0) {
                    analyzePrimaryScreen()
                }
            })
        }
    }
    
    // React to screen changes
    Connections {
        target: Quickshell
        function onScreensChanged() {
            console.log("[DisplayScalingService] Screens changed, re-analyzing...")
            analyzePrimaryScreen()
        }
    }
}