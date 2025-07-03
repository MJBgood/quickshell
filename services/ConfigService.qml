import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Item {
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
    // Configuration file path - configurable with fallbacks  
    readonly property string configPath: {
        // Priority: 1) Environment variable 2) Default relative to dataDir
        const envPath = Quickshell.env("QUICKSHELL_CONFIG_PATH")
        if (envPath) return envPath
        
        // Default: ~/.local/share/quickshell/by-shell/<shell-id>/config/settings/main-config.json
        return Quickshell.dataDir + "/config/settings/main-config.json"
    }
    
    // Default configuration
    readonly property var defaultConfig: ({
        "paths": {
            "themesPath": null,  // null = use default dataDir + "/config/theme/data"
            "configPath": null   // null = use default dataDir + "/config/settings/main-config.json"
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
            "activeTheme": "tokyo-night",
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
            }
        },
        "shortcuts": {
            "launcher": "Super+Space",
            "overview": "Super+Tab",
            "settings": "Super+Comma"
        },
        "system": {
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
                "customIcon": ""
            },
            "ram": {
                "enabled": true,
                "precision": 0,
                "updateInterval": 2000,
                "showIcon": true,
                "showLabel": false,
                "showPercentage": true,
                "customIcon": ""
            },
            "storage": {
                "enabled": true,
                "precision": 0,
                "updateInterval": 30000,
                "showIcon": true,
                "showLabel": false,
                "showPercentage": true,
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

    // Config file loader process
    Process {
        id: configLoader
        command: ["cat", configPath]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length === 0) {
                    console.warn(logCategory, "Config file empty or not found, using defaults")
                    config = JSON.parse(JSON.stringify(defaultConfig))
                    configLoaded()
                    return
                }
                
                try {
                    const loadedConfig = JSON.parse(this.text)
                    config = mergeConfig(defaultConfig, loadedConfig)
                    console.log(logCategory, "Configuration loaded successfully")
                    configLoaded()
                } catch (error) {
                    console.warn(logCategory, "Failed to parse config file, using defaults:", error)
                    config = JSON.parse(JSON.stringify(defaultConfig))
                    // Save the default config so it exists for next time
                    saveConfig()
                    configLoaded()
                }
            }
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
    
    function saveConfig() {
        console.log(logCategory, "Saving configuration to", configPath)
        
        try {
            const configJson = JSON.stringify(config, null, 2)
            const escapedJson = configJson.replace(/'/g, "'\"'\"'") // Escape single quotes for shell
            
            // Use echo to write the config to file
            configSaver.command = ["sh", "-c", "echo '" + escapedJson + "' > '" + configPath + "'"]
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
                    return defaultValue
                }
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
            
            console.log(logCategory, `Set '${keyPath}' to:`, value)
            
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
    
    // Initialization
    Component.onCompleted: {
        console.log(logCategory, "Initializing...")
        loadConfig()
        initialized = true
        console.log(logCategory, "Initialization complete")
    }
}