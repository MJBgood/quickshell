pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: mouseInteractionService
    
    // Reactive properties
    property bool ready: false
    property bool topCenterMenuVisible: false
    property bool shortcutModeActive: false
    
    // Mouse position tracking
    property real mouseX: 0
    property real mouseY: 0
    property bool mouseTracking: true
    
    // Configuration properties  
    property var configService: null
    property int borderThickness: configService ? configService.getValue("border.thickness", 8) : 8
    property int borderRounding: configService ? configService.getValue("border.rounding", 12) : 12
    property int activationZoneHeight: configService ? configService.getValue("topMenu.activationZoneHeight", 32) : 32
    property int activationZoneWidth: configService ? configService.getValue("topMenu.activationZoneWidth", 200) : 200
    
    // Screen dimensions (will be updated by main window)
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var anchorWindow: null
    
    // Mouse detection zones
    readonly property rect topCenterZone: Qt.rect(
        (screenWidth - activationZoneWidth) / 2,
        0,
        activationZoneWidth,
        activationZoneHeight + borderThickness
    )
    
    function updateMousePosition(x, y) {
        mouseX = x
        mouseY = y
        
        if (!mouseTracking || shortcutModeActive) return
        
        // Check if mouse is in top center activation zone
        const inTopCenter = isPointInRect(x, y, topCenterZone)
        
        if (inTopCenter !== topCenterMenuVisible) {
            topCenterMenuVisible = inTopCenter
            dashboardToggled() // Signal state change
        }
    }
    
    function isPointInRect(x, y, rect) {
        return x >= rect.x && 
               x <= rect.x + rect.width && 
               y >= rect.y && 
               y <= rect.y + rect.height
    }
    
    function showTopCenterMenu() {
        console.log("[MouseInteractionService] Show menu called")
        shortcutModeActive = true
        topCenterMenuVisible = true
        topCenterMenuRequested()
    }
    
    function hideTopCenterMenu() {
        console.log("[MouseInteractionService] Hide menu called")
        shortcutModeActive = false
        topCenterMenuVisible = false
        topCenterMenuHideRequested()
    }
    
    function toggleTopCenterMenu() {
        console.log("[MouseInteractionService] Toggle called")
        topCenterMenuVisible = !topCenterMenuVisible
        dashboardToggled()
    }
    
    function updateScreenDimensions(width, height, window) {
        screenWidth = width
        screenHeight = height
        anchorWindow = window
        
        console.log(`[MouseInteractionService] Screen dimensions updated: ${width}x${height}`)
    }
    
    function bindConfigService(service) {
        configService = service
        
        // Update configuration values
        if (configService) {
            borderThickness = configService.getValue("border.thickness", 8)
            borderRounding = configService.getValue("border.rounding", 12)
            activationZoneHeight = configService.getValue("topMenu.activationZoneHeight", 32)
            activationZoneWidth = configService.getValue("topMenu.activationZoneWidth", 200)
        }
        
        console.log(`[MouseInteractionService] Bound to ConfigService - activation zone: ${activationZoneWidth}x${activationZoneHeight}`)
    }
    
    // Debug function
    function getZoneInfo() {
        return {
            topCenter: topCenterZone,
            mousePos: Qt.point(mouseX, mouseY),
            screenSize: Qt.size(screenWidth, screenHeight),
            menuVisible: topCenterMenuVisible,
            shortcutMode: shortcutModeActive
        }
    }
    
    // Signals
    signal dashboardToggled()
    
    Component.onCompleted: {
        ready = true
        console.log("[MouseInteractionService] Initialized")
    }
}