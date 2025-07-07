import QtQuick
import "../../services"

// Base widget component that provides global styling with override capability
Rectangle {
    id: widgetBase
    
    // Services
    property var configService: ConfigService
    
    // Widget identification
    property string widgetType: "generic"
    
    // Global widget styling with auto/override pattern
    property string heightMode: getWidgetValue("height", "auto")
    property string widthMode: getWidgetValue("width", "auto") 
    property string marginMode: getWidgetValue("margin", "auto")
    property string paddingMode: getWidgetValue("padding", "auto")
    property string borderRadiusMode: getWidgetValue("borderRadius", "auto")
    property string spacingMode: getWidgetValue("spacing", "auto")
    
    // Computed styling properties
    readonly property int computedHeight: {
        if (heightMode === "auto") {
            return configService ? configService.scaled(24) : 24
        } else if (typeof heightMode === "number") {
            return configService ? configService.scaled(heightMode) : heightMode
        } else {
            return parseInt(heightMode) || 24
        }
    }
    
    readonly property int computedWidth: {
        if (widthMode === "auto") {
            return configService ? configService.scaled(80) : 80
        } else if (typeof widthMode === "number") {
            return configService ? configService.scaled(widthMode) : widthMode
        } else {
            return parseInt(widthMode) || 80
        }
    }
    
    readonly property int computedMargin: {
        if (marginMode === "auto") {
            return configService ? configService.marginNormal() : 8
        } else if (typeof marginMode === "number") {
            return configService ? configService.scaled(marginMode) : marginMode
        } else {
            return parseInt(marginMode) || 8
        }
    }
    
    readonly property int computedPadding: {
        if (paddingMode === "auto") {
            return configService ? configService.scaledMarginSmall() : 4
        } else if (typeof paddingMode === "number") {
            return configService ? configService.scaled(paddingMode) : paddingMode
        } else {
            return parseInt(paddingMode) || 4
        }
    }
    
    readonly property int computedBorderRadius: {
        if (borderRadiusMode === "auto") {
            return configService ? configService.borderRadius : 8
        } else if (typeof borderRadiusMode === "number") {
            return configService ? configService.scaled(borderRadiusMode) : borderRadiusMode
        } else {
            return parseInt(borderRadiusMode) || 8
        }
    }
    
    readonly property int computedSpacing: {
        if (spacingMode === "auto") {
            return configService ? configService.scaledMarginSmall() : 4
        } else if (typeof spacingMode === "number") {
            return configService ? configService.scaled(spacingMode) : spacingMode
        } else {
            return parseInt(spacingMode) || 4
        }
    }
    
    // Default styling
    implicitHeight: computedHeight
    implicitWidth: computedWidth
    radius: computedBorderRadius
    color: "transparent"
    
    // Helper function to get widget-specific or global values
    function getWidgetValue(property, defaultValue) {
        if (!configService) return defaultValue
        
        // Check widget-specific override first
        const widgetSpecific = configService.getValue("widgets." + widgetType + "." + property, null)
        if (widgetSpecific !== null && widgetSpecific !== "auto") {
            return widgetSpecific
        }
        
        // Fall back to global widget setting
        const globalValue = configService.getValue("widgets.global." + property, defaultValue)
        return globalValue
    }
    
    Component.onCompleted: {
        console.log("WidgetBase: Initialized", widgetType, "with computed dimensions:", computedWidth, "x", computedHeight)
    }
}