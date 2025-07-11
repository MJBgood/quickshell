pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: configService
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.config"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Configuration state
    property bool initialized: false
    property var config: ({})
    
    // Hybrid config management
    property bool autoSave: true       // UI changes save immediately to config file
    property bool immediateUpdate: true // Config changes update UI immediately
    // Note: File watching not available in Quickshell - restart required for external config edits
    
    // System type - can be auto-detected or manually set in config
    property string systemType: getValue("system.type", "auto")
    property bool isLaptop: systemType === "laptop" || (systemType === "auto" && autoDetectLaptop())
    property bool isDesktop: systemType === "desktop" || (systemType === "auto" && !autoDetectLaptop())
    
    // Theme state
    property string activeTheme: "catppuccin"
    property string activeMode: "dark"
    property bool darkMode: true
    property var currentThemeData: null
    property var availableThemes: []
    
    // Configuration file path - following Quickshell best practices
    readonly property string configPath: {
        // Priority: 1) Environment variable 2) Config directory (recommended)
        const envPath = Quickshell.env("QUICKSHELL_CONFIG_PATH")
        if (envPath) return envPath
        
        // Default: ~/.config/quickshell/config/settings/config.json (follows XDG standards)
        const configDir = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
        return configDir + "/quickshell/config/settings/config.json"
    }
    
    // Theme file path
    readonly property string themePath: {
        const configDir = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
        return configDir + "/quickshell/themes/" + activeTheme + ".json"
    }
    
    // Default configuration
    readonly property var defaultConfig: ({
        "paths": {
            "themesPath": null,  // null = use default dataDir + "/config/theme/data"
            "configPath": null   // null = use default dataDir + "/config/settings/config.json"
        },
        "ui": {
            "panels": {
                "height": 32,
                "borderRadius": 8,
                "margin": 10,
                "spacing": 4
            },
            "menus": {
                "width": 300,
                "itemHeight": 36,
                "maxHeight": 400,
                "borderRadius": 8,
                "margin": 10
            },
            "timing": {
                "updateInterval": 2000,
                "hoverDelay": 800,
                "autoHideDelay": 5000,
                "animationDuration": 300
            },
            "scaling": {
                "globalScale": 1.0,
                "useCustomScaling": false,
                "customScales": {
                    "padding": 1.0,
                    "margin": 1.0,
                    "font": 1.0,
                    "borderRadius": 1.0,
                    "icon": 1.0,
                    "spacing": 1.0
                },
                "preset": "normal"
            },
            "monitors": {
                "cpu": {
                    "precisionDigits": 1,
                    "warningThreshold": 80.0,
                    "criticalThreshold": 95.0
                },
                "ram": {
                    "precisionDigits": 0,
                    "warningThreshold": 70.0,
                    "criticalThreshold": 85.0
                },
                "storage": {
                    "precisionDigits": 1,
                    "warningThreshold": 80.0,
                    "criticalThreshold": 90.0
                }
            }
        },
        "theme": {
            "activeTheme": "catppuccin",
            "activeMode": "dark",
            "followSystemTheme": false,
            "autoSwitchTimes": {
                "enabled": false,
                "lightModeStart": "06:00",
                "darkModeStart": "18:00"
            }
        },
        "panel": {
            "height": 32,
            "position": "top",
            "autohide": false,
            "opacity": 0.95
        },
        "widgets": {
            "clock": {
                "enabled": true,
                "format": "HH:mm",
                "showDate": false
            },
            "workspaces": {
                "enabled": true,
                "showEmpty": true,
                "showNumbers": true
            },
            "systray": {
                "enabled": true,
                "spacing": 4
            },
            "battery": {
                "enabled": null,  // null = auto-detect based on system type
                "showIcon": true,
                "showPercentage": true,
                "showTime": false,
                "autoHideOnDesktop": true,
                "autoShowOnLaptop": true
            }
        },
        "shortcuts": {
            "launcher": "Super+Space",
            "overview": "Super+Tab",
            "settings": "Super+Comma"
        },
        "system": {
            "type": "auto",  // "auto", "laptop", "desktop" - controls battery widget auto-hide
            "updateInterval": 2000,
            "showSystemStats": true,
            "enableNotifications": true
        },
        "performance": {
            "enabled": true,
            "layout": "horizontal",
            "displayMode": "compact",
            "cpu": {
                "enabled": true,
                "precision": 1,
                "updateInterval": 2000,
                "showIcon": true,
                "showLabel": false,
                "showPercentage": true,
                "showFrequency": false,
                "customIcon": ""
            },
            "ram": {
                "enabled": true,
                "precision": 0,
                "updateInterval": 2000,
                "showIcon": true,
                "showLabel": false,
                "showPercentage": true,
                "showFrequency": false,
                "showTotal": true,
                "customIcon": ""
            },
            "storage": {
                "enabled": true,
                "precision": 0,
                "updateInterval": 30000,
                "showIcon": true,
                "showLabel": false,
                "showPercentage": true,
                "showBytes": false,
                "customIcon": ""
            }
        },
        "developer": {
            "debugMode": false,
            "showPerformanceMetrics": true,
            "verboseLogging": false
        }
    })
    
    // Custom signals for lifecycle events
    signal configLoaded()
    signal configSaved()
    signal errorOccurred(string error)
    
    // Theme signals
    signal themeLoaded(string themeName, string mode)
    signal themeChanged(string oldTheme, string newTheme)
    signal modeChanged(string oldMode, string newMode)
    signal themesDiscovered(var themes)
    
    // Auto-generated property change signals (automatically available):
    // - configChanged()        // when config object changes (RECOMMENDED: use this)
    // - configPathChanged()    // when configPath changes
    // - initializedChanged()   // when initialized changes
    //
    // PERFORMANCE BEST PRACTICE:
    // Components should bind directly to config properties like:
    //   property string themeColor: configService.getValue("theme.accentColor", "#89b4fa")
    // 
    // FUTURE UPGRADE PATH:
    // For more sophisticated config management, consider implementing:
    // - signal configKeyChanged(string keyPath, var oldValue, var newValue)  // granular change tracking
    // - Batch change operations with change sets
    // - Config validation with rollback capability
    // - Change history for undo/redo functionality
    // Example use case: A settings UI that needs to highlight which specific
    // settings changed, or a theme editor that needs to preview changes before applying
    

    // Helper function to merge configs (preserving defaults for missing keys)
    function mergeConfig(defaults, loaded) {
        const result = JSON.parse(JSON.stringify(defaults))
        
        function merge(target, source) {
            for (const key in source) {
                if (typeof source[key] === 'object' && source[key] !== null && !Array.isArray(source[key])) {
                    if (typeof target[key] === 'object' && target[key] !== null) {
                        merge(target[key], source[key])
                    } else {
                        target[key] = source[key]
                    }
                } else {
                    target[key] = source[key]
                }
            }
        }
        
        merge(result, loaded)
        return result
    }

    // Config file loader process - reverting to Process approach with better error handling
    Process {
        id: configLoader
        command: ["cat", configPath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log(logCategory, "Config loading process finished, text length:", this.text.length)
                if (this.text.trim().length === 0) {
                    console.warn(logCategory, "Config file empty or not found, using defaults")
                    config = JSON.parse(JSON.stringify(defaultConfig))
                    configLoaded()
                    return
                }
                
                try {
                    const loadedConfig = JSON.parse(this.text)
                    config = mergeConfig(defaultConfig, loadedConfig)
                    console.log(logCategory, "Configuration loaded successfully from:", configPath)
                    configLoaded()
                } catch (error) {
                    console.warn(logCategory, "Failed to parse config file, using defaults:", error)
                    config = JSON.parse(JSON.stringify(defaultConfig))
                    configLoaded()
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log(logCategory, "Config loading process completed with exit code:", exitCode)
        }
    }

    // Public API
    function loadConfig(filePath = "") {
        console.log(logCategory, "Loading configuration from", configPath)
        configLoader.running = true
    }
    
    // Config file saver process
    Process {
        id: configSaver
    }
    
    // Theme loader process - reverting to Process approach with better error handling
    Process {
        id: themeLoader
        command: ["cat", themePath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log(logCategory, "Theme loading process finished, text length:", this.text.length)
                if (this.text.trim().length === 0) {
                    console.warn(logCategory, "Theme file empty or not found, using fallback")
                    loadFallbackTheme()
                    return
                }
                
                try {
                    const theme = JSON.parse(this.text)
                    if (validateTheme(theme)) {
                        // Extract the appropriate mode data
                        if (theme.supportsModes) {
                            const modeData = theme[activeMode]
                            if (modeData) {
                                currentThemeData = Object.assign({}, theme, modeData)
                            } else {
                                // Fallback to default mode
                                const defaultMode = theme.defaultMode || "dark"
                                currentThemeData = Object.assign({}, theme, theme[defaultMode])
                                activeMode = defaultMode
                            }
                        } else {
                            // Single-mode theme
                            currentThemeData = theme
                        }
                        
                        darkMode = activeMode === "dark"
                        console.log(logCategory, "Theme loaded:", theme.name, "(" + activeMode + " mode)")
                        themeLoaded(activeTheme, activeMode)
                    } else {
                        console.warn(logCategory, "Theme validation failed, using fallback")
                        loadFallbackTheme()
                    }
                } catch (error) {
                    console.warn(logCategory, "Failed to parse theme, using fallback:", error)
                    loadFallbackTheme()
                }
            }
        }
        
        onExited: (exitCode) => {
            console.log(logCategory, "Theme loading process completed with exit code:", exitCode)
        }
    }
    
    // Theme discovery process
    Process {
        id: themeDiscovery
        command: ["find", themePath.substring(0, themePath.lastIndexOf('/')), "-name", "*.json", "-type", "f"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = this.text.trim().split('\n').filter(p => p.length > 0)
                discoverThemes(paths)
            }
        }
    }
    
    // Note: FileSystemWatcher not available in Quickshell
    // File watching can be implemented later with a polling mechanism if needed
    
    function saveConfig() {
        console.log(logCategory, "Saving configuration to", configPath)
        
        try {
            const configJson = JSON.stringify(config, null, 2)
            const escapedJson = configJson.replace(/'/g, "'\"'\"'") // Escape single quotes for shell
            
            // Create directory structure first, then write config
            const configDir = configPath.substring(0, configPath.lastIndexOf('/'))
            configSaver.command = ["sh", "-c", "mkdir -p '" + configDir + "' && echo '" + escapedJson + "' > '" + configPath + "'"]
            configSaver.running = true
            
            console.log(logCategory, "Configuration save command executed")
            configSaved()
            
        } catch (error) {
            console.error(logCategory, "Failed to serialize config:", error)
            errorOccurred("Failed to serialize config: " + error)
        }
    }
    
    function getValue(keyPath, defaultValue = undefined) {
        try {
            const keys = keyPath.split('.')
            let value = config
            
            for (const key of keys) {
                if (value && typeof value === 'object' && key in value) {
                    value = value[key]
                } else {
                    console.log(logCategory, `Path '${keyPath}' not found, returning default:`, defaultValue)
                    return defaultValue
                }
            }
            
            // Debug polling rate requests specifically
            if (keyPath.includes('pollingRate')) {
                console.log(logCategory, `getValue('${keyPath}') = ${value} (type: ${typeof value})`)
            }
            
            return value
        } catch (error) {
            console.warn(logCategory, `Failed to get value for '${keyPath}':`, error)
            return defaultValue
        }
    }
    
    function setValue(keyPath, value) {
        try {
            const keys = keyPath.split('.')
            const lastKey = keys.pop()
            let target = config
            
            // Navigate to the parent object
            for (const key of keys) {
                if (!(key in target)) {
                    target[key] = {}
                }
                target = target[key]
            }
            
            // Set the value
            const oldValue = target[lastKey]
            target[lastKey] = value
            
            // Force config to be reassigned to trigger property change
            config = config
            
            // Emit the configChanged signal if immediateUpdate is enabled
            if (immediateUpdate) {
                configChanged()
            }
            
            console.log(logCategory, `Set '${keyPath}' from '${oldValue}' to:`, value)
            
            // Auto-save to file if enabled (hybrid approach)
            if (autoSave) {
                console.log(logCategory, `Auto-saving config due to change in '${keyPath}'`)
                saveConfig()
            }
            
            return true
        } catch (error) {
            console.error(logCategory, `Failed to set value for '${keyPath}':`, error)
            errorOccurred(`Failed to set config value: ${error}`)
            return false
        }
    }
    
    function resetToDefaults() {
        console.log(logCategory, "Resetting to default configuration")
        config = JSON.parse(JSON.stringify(defaultConfig))
        // config property change will auto-emit configChanged()
    }
    
    function exportConfig() {
        return JSON.stringify(config, null, 2)
    }
    
    function importConfig(jsonString) {
        try {
            const newConfig = JSON.parse(jsonString)
            config = newConfig
            // config property change will auto-emit configChanged()
            console.log(logCategory, "Configuration imported successfully")
            return true
        } catch (error) {
            console.error(logCategory, "Failed to import configuration:", error)
            errorOccurred(`Failed to import config: ${error}`)
            return false
        }
    }
    
    // UI Configuration Helpers (user-modifiable at runtime)
    function getUISetting(category, key, fallback) {
        const uiConfig = config.ui || defaultConfig.ui
        const categoryConfig = uiConfig[category]
        return categoryConfig ? (categoryConfig[key] !== undefined ? categoryConfig[key] : fallback) : fallback
    }
    
    function setUISetting(category, key, value) {
        if (!config.ui) config.ui = {}
        if (!config.ui[category]) config.ui[category] = {}
        config.ui[category][key] = value
        configChanged()
        return saveConfig()
    }
    
    // Convenience getters for common UI values (runtime modifiable)
    property int panelHeight: getUISetting("panels", "height", 32)
    property int menuWidth: getUISetting("menus", "width", 300)
    property int menuItemHeight: getUISetting("menus", "itemHeight", 36) 
    property int borderRadius: getUISetting("panels", "borderRadius", 8)
    property int defaultMargin: getUISetting("panels", "margin", 10)
    property int defaultSpacing: getUISetting("panels", "spacing", 4)
    property int updateInterval: getUISetting("timing", "updateInterval", 2000)
    property int hoverDelay: getUISetting("timing", "hoverDelay", 800)
    
    // Monitor configuration getters
    function getMonitorSetting(monitorType, key, fallback) {
        return getUISetting("monitors", `${monitorType}.${key}`, fallback)
    }
    
    // Scaling helpers
    property real globalScale: {
        // Use device pixel ratio from primary screen, with user override
        const primaryScreen = Quickshell.screens[0]
        const deviceScale = primaryScreen ? primaryScreen.devicePixelRatio : 1.0
        const userScale = getUISetting("scaling", "globalScale", 1.0)
        return deviceScale * userScale
    }
    
    function scaled(baseValue, scaleType = "base") {
        const useCustom = getUISetting("scaling", "useCustomScaling", false)
        if (useCustom) {
            const customScale = getUISetting("scaling", `customScales.${scaleType}`, 1.0)
            return Math.round(baseValue * globalScale * customScale)
        }
        return Math.round(baseValue * globalScale)
    }
    
    // Convenience scaling functions
    function fontScale(baseSize) { return scaled(baseSize, "font") }
    function paddingScale(baseSize) { return scaled(baseSize, "padding") }
    function marginScale(baseSize) { return scaled(baseSize, "margin") }
    function iconScale(baseSize) { return scaled(baseSize, "icon") }
    function borderRadiusScale(baseSize) { return scaled(baseSize, "borderRadius") }
    function spacingScale(baseSize) { return scaled(baseSize, "spacing") }
    
    // Common UI sizes (scaled)
    function scaledFontTiny() { return fontScale(8) }
    function scaledFontSmall() { return fontScale(9) }
    function scaledFontNormal() { return fontScale(10) }
    function scaledFontMedium() { return fontScale(12) }
    function scaledFontLarge() { return fontScale(14) }
    
    // ISO-compliant size scales following international standards
    
    // Typography scale (based on modular scale + Apple/WCAG guidelines)
    property var typographyScale: {
        "xs": 11,     // 11px (Apple minimum readable size)
        "sm": 14,     // 14px (common UI text)
        "base": 16,   // 16px (web standard default)
        "lg": 20,     // 20px (large text)
        "xl": 24,     // 24px (headings)
        "2xl": 32,    // 32px (large headings)
        "3xl": 48     // 48px (display text)
    }
    
    // Spacing scale (8px grid system for consistency)
    property var spacingScale: {
        "xs": 4,      // 4px (micro spacing)
        "sm": 8,      // 8px (small spacing)
        "md": 16,     // 16px (default spacing)
        "lg": 24,     // 24px (WCAG AA minimum touch target)
        "xl": 32,     // 32px (large spacing)
        "2xl": 48,    // 48px (section spacing)
        "3xl": 64     // 64px (major section spacing)
    }
    
    // Touch target sizes (accessibility compliant)
    property var touchTargetScale: {
        "minimum": 24,  // WCAG AA minimum
        "standard": 44, // Apple/WCAG AAA standard
        "large": 56     // Enhanced accessibility
    }
    
    // Legacy font functions (for backward compatibility)
    function fontTiny() { return typographyScale.xs }
    function fontSmall() { return typographyScale.sm }
    function fontNormal() { return typographyScale.base }
    function fontMedium() { return typographyScale.lg }
    function fontLarge() { return typographyScale.xl }
    
    // Legacy margin functions (for backward compatibility)
    function marginTiny() { return spacingScale.xs }
    function marginSmall() { return spacingScale.sm }
    function marginNormal() { return spacingScale.md }
    function marginLarge() { return spacingScale.lg }
    
    // Legacy scaled functions (for backward compatibility)
    function scaledMarginTiny() { return marginScale(spacingScale.xs) }
    function scaledMarginSmall() { return marginScale(spacingScale.sm) }
    function scaledMarginNormal() { return marginScale(spacingScale.md) }
    function scaledMarginLarge() { return marginScale(spacingScale.lg) }
    
    function scaledIconSmall() { return iconScale(16) }
    function scaledIconMedium() { return iconScale(20) }
    function scaledIconLarge() { return iconScale(24) }
    
    // Modern ISO-compliant size functions
    
    // Typography helpers (scaled)
    function fontSize(size) { return fontScale(typographyScale[size] || typographyScale.base) }
    function fontSizeXs() { return fontSize("xs") }
    function fontSizeSm() { return fontSize("sm") }
    function fontSizeBase() { return fontSize("base") }
    function fontSizeLg() { return fontSize("lg") }
    function fontSizeXl() { return fontSize("xl") }
    function fontSize2xl() { return fontSize("2xl") }
    function fontSize3xl() { return fontSize("3xl") }
    
    // Removed legacy spacing functions - use spacing(size, entityId) instead
    
    // Touch target helpers (scaled, accessibility compliant)
    function touchTarget(size) { return scaled(touchTargetScale[size] || touchTargetScale.standard) }
    function touchTargetMinimum() { return touchTarget("minimum") }
    function touchTargetStandard() { return touchTarget("standard") }
    function touchTargetLarge() { return touchTarget("large") }
    
    // Removed legacy icon functions - use icon(size, entityId) instead
    
    // Widget helper functions (updated to use new entity system)
    function widgetSpacing(entityId) { return spacing("sm", entityId) }  // 8px spacing
    function badgeSize(entityId) { return spacing("md", entityId) }      // 16px (readable badge size)
    function badgeRadius(entityId) { return spacing("sm", entityId) }     // 8px radius
    function badgePadding(entityId) { return spacing("xs", entityId) }    // 4px padding
    
    // Entity-based configuration API
    function getEntityProperty(entityId, property, defaultValue) {
        if (!entityId) return defaultValue
        return getValue("entities." + entityId + "." + property, defaultValue)
    }
    
    function getEntityStyle(entityId, styleProperty, defaultValue, contentValue) {
        if (!entityId) return contentValue || defaultValue
        
        const entityValue = getValue("entities." + entityId + "." + styleProperty, "auto")
        
        if (entityValue === "auto") {
            return contentValue || defaultValue
        } else if (typeof entityValue === "string" && isSemanticSize(entityValue)) {
            // Handle semantic sizes (sm, md, lg, etc.)
            return getSemanticValue(styleProperty, entityValue)
        } else if (typeof entityValue === "number") {
            // Handle numerical overrides
            return scaled(entityValue)
        } else {
            return entityValue
        }
    }
    
    function isSemanticSize(value) {
        const semanticSizes = ["xs", "sm", "md", "lg", "xl", "2xl", "3xl"]
        return semanticSizes.includes(value)
    }
    
    function getSemanticValue(styleProperty, semanticSize) {
        // Map style properties to appropriate scale types
        if (styleProperty === "fontSize" || styleProperty.includes("font")) {
            return fontSize(semanticSize)
        } else if (styleProperty === "iconSize" || styleProperty.includes("icon")) {
            return iconSize(semanticSize)
        } else {
            // Default to spacing scale for padding, margin, etc.
            return spacing(semanticSize)
        }
    }
    
    // Entity-aware semantic scaling functions with four-tier resolution
    function typography(requestedSize, entityId) {
        if (entityId) {
            // Check for entity-specific override
            const entityOverride = getEntityProperty(entityId, "fontSize", null)
            if (entityOverride !== null) {
                if (entityOverride === "auto") {
                    // Use global default
                    requestedSize = getValue("scaling.defaults.typography", "md")
                } else if (typeof entityOverride === "string") {
                    // Use entity's semantic choice
                    requestedSize = entityOverride
                } else if (typeof entityOverride === "number") {
                    // Numerical override - bypass semantic system
                    return scaled(entityOverride, "font")
                }
            }
        }
        
        // Apply semantic scaling
        const baseValue = typographyScale[requestedSize] || typographyScale.md
        return fontScale(baseValue)
    }
    
    function spacing(requestedSize, entityId) {
        if (entityId) {
            // Check for entity-specific override
            const entityOverride = getEntityProperty(entityId, "spacing", null)
            if (entityOverride !== null) {
                if (entityOverride === "auto") {
                    requestedSize = getValue("scaling.defaults.spacing", "md")
                } else if (typeof entityOverride === "string") {
                    requestedSize = entityOverride
                } else if (typeof entityOverride === "number") {
                    return scaled(entityOverride, "spacing")
                }
            }
        }
        
        const baseValue = spacingScale[requestedSize] || spacingScale.md
        return marginScale(baseValue)
    }
    
    function icon(requestedSize, entityId) {
        if (entityId) {
            const entityOverride = getEntityProperty(entityId, "iconSize", null)
            if (entityOverride !== null) {
                if (entityOverride === "auto") {
                    requestedSize = getValue("scaling.defaults.icon", "md")
                } else if (typeof entityOverride === "string") {
                    requestedSize = entityOverride
                } else if (typeof entityOverride === "number") {
                    return scaled(entityOverride, "icon")
                }
            }
        }
        
        const baseValue = spacingScale[requestedSize] || spacingScale.md
        return iconScale(baseValue)
    }
    
    // Simplified widget height helper using entity system
    function getWidgetHeight(entityId, contentHeight) {
        return getEntityStyle(entityId, "height", "auto", contentHeight)
    }
    
    // Workspace helper functions (ISO-compliant sizing with accessibility)
    function workspaceSize(mode) {
        const sizes = {
            "xs": { width: spacingScale.lg, height: spacingScale.md },      // 24x16px (compact)
            "sm": { width: touchTargetMinimum(), height: spacingScale.md }, // 24x16px (WCAG minimum)
            "md": { width: spacingScale.xl, height: spacingScale.lg },      // 32x24px (default)
            "lg": { width: spacingScale["2xl"], height: spacingScale.xl },  // 48x32px (large)
            "xl": { width: touchTargetStandard(), height: spacingScale.xl } // 44x32px (touch-friendly)
        }
        return sizes[mode] || sizes["md"]
    }
    
    // Scaling preset management
    function applyScalingPreset(presetName) {
        const presets = {
            "compact": { globalScale: 0.8, customScales: { font: 0.9, padding: 0.8, margin: 0.8 } },
            "normal": { globalScale: 1.0, customScales: { font: 1.0, padding: 1.0, margin: 1.0 } },
            "large": { globalScale: 1.2, customScales: { font: 1.1, padding: 1.2, margin: 1.2 } },
            "extraLarge": { globalScale: 1.5, customScales: { font: 1.3, padding: 1.5, margin: 1.5 } }
        }
        
        const preset = presets[presetName]
        if (preset) {
            setUISetting("scaling", "preset", presetName)
            setUISetting("scaling", "globalScale", preset.globalScale)
            setUISetting("scaling", "useCustomScaling", true)
            for (const [key, value] of Object.entries(preset.customScales)) {
                setUISetting("scaling", `customScales.${key}`, value)
            }
            return true
        }
        return false
    }
    
    // Theme management functions
    function loadTheme() {
        activeTheme = getValue("theme.activeTheme", "catppuccin")
        activeMode = getValue("theme.activeMode", "dark")
        darkMode = activeMode === "dark"
        
        console.log(logCategory, "Loading theme:", activeTheme, "mode:", activeMode)
        themeLoader.running = true
    }
    
    function validateTheme(theme) {
        if (!theme || typeof theme.id !== 'string' || typeof theme.name !== 'string') {
            return false
        }
        
        // Check if theme supports modes (has dark/light mode data)
        if (theme.supportsModes) {
            const darkMode = theme.dark
            const lightMode = theme.light
            
            // At least one mode must have colors
            return (darkMode && darkMode.colors && typeof darkMode.colors === 'object') ||
                   (lightMode && lightMode.colors && typeof lightMode.colors === 'object')
        } else {
            // Flat theme structure
            return theme.colors && typeof theme.colors === 'object'
        }
    }
    
    function loadFallbackTheme() {
        console.log(logCategory, "Loading fallback theme")
        currentThemeData = {
            id: "catppuccin-mocha",
            name: "Catppuccin Mocha",
            description: "Dark theme with purple accents",
            supportsModes: false,
            colors: {
                background: "#1e1e2e",
                surface: "#313244",
                surfaceAlt: "#45475a",
                surfaceContainer: "#45475a",
                text: "#cdd6f4",
                primary: "#89b4fa",
                onPrimary: "#1e1e2e",
                secondary: "#f38ba8",
                accent: "#a6e3a1",
                success: "#a6e3a1",
                warning: "#f9e2af",
                error: "#f38ba8",
                border: "#585b70",
                textAlt: "#bac2de"
            },
            spacing: {
                small: 4,
                medium: 8,
                large: 16,
                xl: 24
            }
        }
        themeLoaded(activeTheme, activeMode)
    }
    
    function getThemeProperty(category, property) {
        if (!currentThemeData) {
            console.warn(logCategory, "No theme data loaded, using fallback")
            return getFallbackProperty(category, property)
        }
        
        const categoryData = currentThemeData[category]
        if (!categoryData) {
            console.warn(logCategory, "Theme category not found:", category)
            return getFallbackProperty(category, property)
        }
        
        const value = categoryData[property]
        if (value === undefined) {
            console.warn(logCategory, "Theme property not found:", category + "." + property)
            return getFallbackProperty(category, property)
        }
        
        return value
    }
    
    function getFallbackProperty(category, property) {
        // Fallback theme properties (Catppuccin Mocha)
        const fallback = {
            colors: {
                background: "#1e1e2e",
                surface: "#313244", 
                surfaceAlt: "#45475a",
                surfaceContainer: "#45475a",
                text: "#cdd6f4",
                primary: "#89b4fa",
                onPrimary: "#1e1e2e",
                secondary: "#f38ba8",
                accent: "#a6e3a1",
                success: "#a6e3a1",
                warning: "#f9e2af",
                error: "#f38ba8",
                border: "#585b70",
                textAlt: "#bac2de"
            },
            spacing: {
                small: 4,
                medium: 8,
                large: 16,
                xl: 24
            }
        }
        
        return fallback[category] && fallback[category][property]
    }
    
    function setTheme(themeName, mode) {
        if (!themeName) return false
        
        const oldTheme = activeTheme
        const oldMode = activeMode
        
        activeTheme = themeName
        activeMode = mode || "dark"
        darkMode = activeMode === "dark"
        
        // Save to configuration
        setValue("theme.activeTheme", activeTheme)
        setValue("theme.activeMode", activeMode)
        saveConfig()
        
        // Load the new theme
        loadTheme()
        
        if (oldTheme !== activeTheme) {
            themeChanged(oldTheme, activeTheme)
        }
        if (oldMode !== activeMode) {
            modeChanged(oldMode, activeMode)
        }
        
        return true
    }
    
    function toggleDarkMode() {
        if (!currentThemeData) return false
        
        if (!currentThemeData.supportsModes) {
            console.log(logCategory, "Theme does not support light/dark mode switching")
            return false
        }
        
        const newMode = activeMode === "dark" ? "light" : "dark"
        return setTheme(activeTheme, newMode)
    }
    
    function discoverThemes(themePaths) {
        console.log(logCategory, "Discovering themes...")
        const themeList = []
        
        for (const path of themePaths) {
            const filename = path.split('/').pop()
            const fileId = filename.replace('.json', '')
            
            // Create simplified theme entry for discovery
            themeList.push({
                id: fileId,
                name: fileId.charAt(0).toUpperCase() + fileId.slice(1).replace(/-/g, ' '),
                description: "Theme file: " + filename,
                filePath: path
            })
        }
        
        availableThemes = themeList
        themesDiscovered(themeList)
        
        console.log(logCategory, "Discovered", themeList.length, "themes:", themeList.map(t => t.id).join(", "))
    }
    
    function refreshThemes() {
        console.log(logCategory, "Refreshing theme list...")
        const themesDir = themePath.substring(0, themePath.lastIndexOf('/'))
        themeDiscovery.command = ["find", themesDir, "-name", "*.json", "-type", "f"]
        themeDiscovery.running = true
    }
    
    function loadAllThemes() {
        if (availableThemes.length > 0) {
            console.log(logCategory, "Themes already loaded")
            return
        }
        console.log(logCategory, "Loading all themes...")
        refreshThemes()
    }
    
    // Simple laptop detection for auto-mode
    function autoDetectLaptop() {
        // Use multiple detection methods for better accuracy
        console.log(logCategory, "Auto-detecting system type...")
        
        try {
            // Method 1: Check for laptop-specific environment variables
            const powerProfile = Quickshell.env("POWER_PROFILE_DAEMON_PREFERRED_PROFILE")
            if (powerProfile === "power-saver" || powerProfile === "balanced") {
                console.log(logCategory, "Laptop detected: power profile indicates mobile device")
                return true
            }
            
            // Method 2: Check for common laptop environment indicators
            const xdgSessionType = Quickshell.env("XDG_SESSION_TYPE")
            const currentDesktop = Quickshell.env("XDG_CURRENT_DESKTOP")
            
            // Method 3: Try to detect battery presence (most reliable for laptops)
            const batteryExists = checkBatteryExists()
            if (batteryExists) {
                console.log(logCategory, "Laptop detected: battery found")
                return true
            }
            
            // Method 4: Check screen size and DPI (laptops typically have higher DPI)
            const primaryScreen = Quickshell.screens[0]
            if (primaryScreen) {
                const width = primaryScreen.width
                const height = primaryScreen.height
                const dpr = primaryScreen.devicePixelRatio
                
                // Laptop-like characteristics: smaller screens with higher DPI
                const isSmallHighDPI = (width < 1920 || height < 1080) && dpr > 1.25
                const isTypicalLaptopRes = (width === 1366 && height === 768) || 
                                         (width === 1920 && height === 1080 && dpr > 1.0) ||
                                         (width < 1600 && dpr > 1.0)
                
                if (isSmallHighDPI || isTypicalLaptopRes) {
                    console.log(logCategory, `Laptop detected: screen characteristics ${width}x${height} DPR:${dpr.toFixed(2)}`)
                    return true
                }
            }
            
            // Method 5: Check ACPI for laptop-specific power management
            // This would require external commands, skip for now
            
            console.log(logCategory, "System type auto-detection: no clear laptop indicators found, defaulting to desktop")
            return false
            
        } catch (error) {
            console.warn(logCategory, "Error in laptop auto-detection:", error)
            return false
        }
    }
    
    function checkBatteryExists() {
        // Simplified battery detection
        try {
            // Method 1: Check environment variables for battery
            const hasBat0 = Quickshell.env("POWER_SUPPLY_BAT0_PRESENT") === "1"
            const hasBat1 = Quickshell.env("POWER_SUPPLY_BAT1_PRESENT") === "1"
            
            if (hasBat0 || hasBat1) {
                console.log(logCategory, "Battery found via environment variables")
                return true
            }
            
            // Method 2: Check for common laptop battery environment indicators
            const upowerConf = Quickshell.env("UPOWER_CONF_FILE_NAME")
            const powerProfile = Quickshell.env("POWER_PROFILE_DAEMON_PREFERRED_PROFILE")
            
            if (upowerConf || powerProfile) {
                console.log(logCategory, "Power management detected, likely has battery")
                return true
            }
            
            // Method 3: Check XDG environment for mobile session indicators
            const sessionDesktop = Quickshell.env("XDG_SESSION_DESKTOP")
            const sessionType = Quickshell.env("XDG_SESSION_TYPE")
            
            // GNOME and KDE often set laptop-specific variables
            if (sessionDesktop && (sessionDesktop.includes("gnome") || sessionDesktop.includes("kde"))) {
                const gnomePowerManager = Quickshell.env("GNOME_DESKTOP_SESSION_ID")
                if (gnomePowerManager) {
                    console.log(logCategory, "GNOME session detected, checking for power management")
                    return true
                }
            }
            
            console.log(logCategory, "No battery detected via environment variables")
            return false
        } catch (error) {
            console.warn(logCategory, "Error checking battery existence:", error)
            return false
        }
    }
    
    // Helper function to get battery widget enabled state with auto-detection
    function getBatteryEnabled() {
        const explicitSetting = getValue("widgets.battery.enabled", null)
        if (explicitSetting !== null) {
            return explicitSetting  // User explicitly set it
        }
        
        // Auto-detect based on system type and config
        const autoHideOnDesktop = getValue("widgets.battery.autoHideOnDesktop", true)
        const autoShowOnLaptop = getValue("widgets.battery.autoShowOnLaptop", true)
        
        if (isLaptop && autoShowOnLaptop) {
            return true
        } else if (isDesktop && autoHideOnDesktop) {
            return false
        }
        
        // Fallback: show on laptop, hide on desktop
        return isLaptop
    }
    
    // Load theme after config is loaded
    onConfigLoaded: {
        loadTheme()
        refreshThemes()  // Also discover available themes
    }
    
    // Initialization
    Component.onCompleted: {
        console.log(logCategory, "Initializing ConfigService singleton...")
        console.log(logCategory, "Config path:", configPath)
        console.log(logCategory, "Theme path:", themePath)
        
        // Load default configuration first
        config = JSON.parse(JSON.stringify(defaultConfig))
        console.log(logCategory, "Default config loaded")
        
        // Load fallback theme immediately to ensure currentThemeData is available
        loadFallbackTheme()
        console.log(logCategory, "Fallback theme loaded")
        
        // Then try to load actual config/theme
        loadConfig()
        initialized = true
        console.log(logCategory, "ConfigService initialization complete")
    }
}