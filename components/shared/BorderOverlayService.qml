pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: borderOverlayService
    
    // Reactive properties
    property bool ready: false
    property bool enabled: true
    property bool visible: true
    
    // Configuration properties
    property var configService: null
    property int thickness: configService ? configService.getValue("border.thickness", 8) : 8
    property int rounding: configService ? configService.getValue("border.rounding", 12) : 12
    property real opacity: configService ? configService.getValue("border.opacity", 0.3) : 0.3
    property string color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
    
    // Screen dimensions and window reference
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var anchorWindow: null
    property int barWidth: 0  // Width of side bar to account for
    
    // Animation properties
    property int animationDuration: configService ? configService.getValue("border.animationDuration", 300) : 300
    property string easingType: configService ? configService.getValue("border.easingType", "OutCubic") : "OutCubic"
    
    function updateScreenDimensions(width, height, window) {
        screenWidth = width
        screenHeight = height
        anchorWindow = window
        
        console.log(`[BorderOverlayService] Screen dimensions updated: ${width}x${height}`)
    }
    
    function updateBarWidth(width) {
        barWidth = width
        console.log(`[BorderOverlayService] Bar width updated: ${width}`)
    }
    
    function bindConfigService(service) {
        configService = service
        
        // Update configuration values
        if (configService) {
            thickness = configService.getValue("border.thickness", 8)
            rounding = configService.getValue("border.rounding", 12)
            opacity = configService.getValue("border.opacity", 0.3)
            color = configService.getThemeProperty("colors", "border") || "#585b70"
            animationDuration = configService.getValue("border.animationDuration", 300)
            easingType = configService.getValue("border.easingType", "OutCubic")
        }
        
        console.log(`[BorderOverlayService] Bound to ConfigService - thickness: ${thickness}, rounding: ${rounding}`)
    }
    
    function show() {
        visible = true
        borderVisibilityChanged()
    }
    
    function hide() {
        visible = false
        borderVisibilityChanged()
    }
    
    function toggle() {
        visible = !visible
        borderVisibilityChanged()
    }
    
    function enable() {
        enabled = true
        borderEnabledChanged()
    }
    
    function disable() {
        enabled = false
        borderEnabledChanged()
    }
    
    function updateTheme() {
        if (configService) {
            const newColor = configService.getThemeProperty("colors", "border") || "#585b70"
            if (newColor !== color) {
                color = newColor
                borderStyleChanged()
            }
        }
    }
    
    // Helper function to get border rectangle accounting for bar
    function getBorderRect() {
        return Qt.rect(
            barWidth,
            0,
            screenWidth - barWidth,
            screenHeight
        )
    }
    
    // Helper function to get inner content rectangle  
    function getContentRect() {
        return Qt.rect(
            barWidth + thickness,
            thickness,
            screenWidth - barWidth - (thickness * 2),
            screenHeight - (thickness * 2)
        )
    }
    
    // Helper function to check if border should be visible in area
    function shouldShowBorderInArea(x, y, width, height) {
        if (!enabled || !visible) return false
        
        const borderRect = getBorderRect()
        const contentRect = getContentRect()
        
        // Check if area overlaps with border but not entirely within content
        const areaRect = Qt.rect(x, y, width, height)
        
        // Area overlaps border area
        const overlaps = !(areaRect.x >= borderRect.x + borderRect.width ||
                          areaRect.x + areaRect.width <= borderRect.x ||
                          areaRect.y >= borderRect.y + borderRect.height ||
                          areaRect.y + areaRect.height <= borderRect.y)
        
        // Area is not entirely within content area
        const withinContent = (areaRect.x >= contentRect.x &&
                              areaRect.y >= contentRect.y &&
                              areaRect.x + areaRect.width <= contentRect.x + contentRect.width &&
                              areaRect.y + areaRect.height <= contentRect.y + contentRect.height)
        
        return overlaps && !withinContent
    }
    
    // Debug function
    function getBorderInfo() {
        return {
            enabled: enabled,
            visible: visible,
            thickness: thickness,
            rounding: rounding,
            color: color,
            opacity: opacity,
            screenSize: Qt.size(screenWidth, screenHeight),
            barWidth: barWidth,
            borderRect: getBorderRect(),
            contentRect: getContentRect()
        }
    }
    
    // Signals
    signal borderVisibilityChanged()
    signal borderEnabledChanged()
    signal borderStyleChanged()
    signal borderGeometryChanged()
    
    // React to configuration changes
    onThicknessChanged: borderGeometryChanged()
    onRoundingChanged: borderGeometryChanged()
    onScreenWidthChanged: borderGeometryChanged()
    onScreenHeightChanged: borderGeometryChanged()
    onBarWidthChanged: borderGeometryChanged()
    
    Component.onCompleted: {
        ready = true
        console.log("[BorderOverlayService] Initialized")
    }
}