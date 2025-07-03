import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: themeService
    
    // Theme state
    property bool initialized: false
    property string activeTheme: "tokyo-night"  // Will be overridden by config
    property string activeMode: "dark"
    property bool darkMode: true
    property var availableThemes: []
    property var currentThemeData: null
    
    // Services - will be connected from parent
    property var configService: null
    
    // Theme directory path - configurable with fallbacks
    readonly property string themesPath: {
        // Priority: 1) Environment variable 2) Config override 3) Default relative to dataDir
        const envPath = Quickshell.env("QUICKSHELL_THEMES_PATH")
        if (envPath) return envPath
        
        const configOverride = configService?.getSetting("paths", "themesPath")
        if (configOverride) return configOverride
        
        // Default: ~/.local/share/quickshell/by-shell/<shell-id>/config/theme/data
        return Quickshell.dataDir + "/config/theme/data"
    }
    
    // Signals
    signal themeLoaded(string themeName, string mode)
    signal themeChanged(string oldTheme, string newTheme)
    signal modeChanged(string oldMode, string newMode)
    signal themesDiscovered(var themes)
    signal errorOccurred(string error)
    
    // Watch for config changes
    Connections {
        target: configService
        function onConfigLoaded() {
            loadThemeFromConfig()
        }
    }
    
    function loadThemeFromConfig() {
        if (!configService) {
            console.warn("ThemeService: No config service available")
            return
        }
        
        if (!configService.initialized) {
            console.warn("ThemeService: Config service not yet initialized")
            return
        }
        
        activeTheme = configService.getValue("theme.activeTheme", "tokyo-night")
        activeMode = configService.getValue("theme.activeMode", "dark")
        darkMode = activeMode === "dark"
        
        console.log("ThemeService: Loaded from main config - theme:", activeTheme, "mode:", activeMode)
        
        // Now load the active theme
        loadActiveTheme()
    }

    // Auto-discovery process for theme files - lazy loaded
    Process {
        id: themeDiscovery
        command: ["find", themesPath, "-name", "*.json", "-type", "f"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = this.text.trim().split('\n').filter(p => p.length > 0)
                discoverThemes(paths)
            }
        }
        
    }
    
    
    // Active theme loader process
    Process {
        id: activeThemeLoader
        command: ["cat", themesPath + "/" + activeTheme + ".json"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length === 0) {
                    console.warn("ThemeService: Active theme file empty or not found, using fallback")
                    loadFallbackThemes()
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
                        console.log("ThemeService: Loaded theme '" + theme.name + "' (" + activeMode + " mode)")
                        themeLoaded(activeTheme, activeMode)
                    } else {
                        console.warn("ThemeService: Active theme validation failed, using fallback")
                        loadFallbackThemes()
                    }
                } catch (error) {
                    console.warn("ThemeService: Failed to parse active theme, using fallback:", error)
                    loadFallbackThemes()
                }
            }
        }
        
    }
    
    // Load only the active theme for startup efficiency
    function loadActiveTheme() {
        console.log("ThemeService: Loading active theme '" + activeTheme + "' in '" + activeMode + "' mode")
        activeThemeLoader.running = true
    }
    
    // Toggle dark/light mode for current theme
    function toggleDarkMode() {
        if (!currentThemeData) {
            console.warn("ThemeService: No theme loaded")
            return false
        }
        
        if (!currentThemeData.supportsModes) {
            console.log("ThemeService: Theme '" + activeTheme + "' does not support light/dark mode switching")
            return false
        }
        
        const newMode = activeMode === "dark" ? "light" : "dark"
        return setMode(newMode)
    }
    
    // Set specific mode for current theme
    function setMode(mode) {
        if (!currentThemeData) {
            console.warn("ThemeService: No theme loaded")
            return false
        }
        
        if (!currentThemeData.supportsModes) {
            console.log("ThemeService: Theme '" + activeTheme + "' does not support mode switching")
            return false
        }
        
        if (!currentThemeData[mode]) {
            console.warn("ThemeService: Mode '" + mode + "' not available for theme '" + activeTheme + "'")
            return false
        }
        
        const oldMode = activeMode
        activeMode = mode
        darkMode = mode === "dark"
        
        // Reload the theme with the new mode
        loadActiveTheme()
        
        // Save preference (with override if power user mode enabled)
        saveThemePreference(activeTheme, mode)
        
        modeChanged(oldMode, mode)
        console.log("ThemeService: Switched to " + mode + " mode")
        return true
    }
    
    // Cycle through available themes
    function cycleTheme() {
        if (availableThemes.length === 0) {
            console.log("ThemeService: No themes loaded, discovering themes first")
            refreshThemes()
            return false
        }
        
        const currentIndex = availableThemes.findIndex(t => t.id === activeTheme)
        const nextIndex = (currentIndex + 1) % availableThemes.length
        const nextTheme = availableThemes[nextIndex]
        
        console.log("ThemeService: Cycling from '" + activeTheme + "' to '" + nextTheme.id + "'")
        return loadTheme(nextTheme.id)
    }
    
    // Save theme preference to main config
    function saveThemePreference(themeId, mode) {
        if (!configService) {
            console.warn("ThemeService: No config service available for saving")
            return
        }
        
        configService.setValue("theme.activeTheme", themeId)
        configService.setValue("theme.activeMode", mode)
        configService.saveConfig()
        
        console.log("ThemeService: Saved preference to main config - " + themeId + ":" + mode)
    }
    
    // Public API - simplified theme discovery
    function discoverThemes(themePaths) {
        console.log("ThemeService: Discovered theme files...")
        const themeList = []
        
        for (const path of themePaths) {
            const filename = path.split('/').pop()
            const fileId = filename.replace('.json', '')
            
            // Create simplified theme entry for discovery
            // Use filename as ID since that's what we load from
            themeList.push({
                id: fileId,
                name: fileId.charAt(0).toUpperCase() + fileId.slice(1).replace(/-/g, ' '),
                description: "Theme file: " + filename,
                filePath: path
            })
        }
        
        availableThemes = themeList
        themesDiscovered(themeList)
        
        console.log("ThemeService: Discovered " + themeList.length + " theme files")
        console.log("ThemeService: Available themes:", availableThemes.map(t => t.id).join(", "))
    }
    
    function loadTheme(themeName) {
        console.log("ThemeService: Loading theme '" + themeName + "'")
        
        const oldTheme = activeTheme
        activeTheme = themeName
        
        // Update the active theme loader command and run it
        activeThemeLoader.command = ["cat", themesPath + "/" + themeName + ".json"]
        activeThemeLoader.running = true
        
        themeChanged(oldTheme, themeName)
        return true
    }
    
    // Track if we've already warned about missing theme data to prevent spam
    property bool hasWarnedAboutMissingTheme: false
    
    function getThemeProperty(category, property) {
        if (!currentThemeData) {
            if (!hasWarnedAboutMissingTheme) {
                console.warn("ThemeService: No theme data loaded, using fallback values")
                hasWarnedAboutMissingTheme = true
            }
            return getFallbackProperty(category, property)
        }
        
        const categoryData = currentThemeData[category]
        if (!categoryData) {
            console.warn("ThemeService: Category '" + category + "' not found in theme '" + activeTheme + "'")
            return getFallbackProperty(category, property)
        }
        
        const value = categoryData[property]
        if (value === undefined) {
            console.warn("ThemeService: Property '" + property + "' not found in category '" + category + "'")
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
                text: "#cdd6f4",
                primary: "#89b4fa",
                onPrimary: "#1e1e2e",
                secondary: "#f38ba8",
                accent: "#a6e3a1",
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
    
    function loadFallbackThemes() {
        console.log("ThemeService: Loading fallback themes")
        availableThemes = [
            {
                id: "catppuccin-mocha",
                name: "Catppuccin Mocha",
                description: "Dark theme with purple accents",
                type: "dark",
                colors: {
                    background: "#1e1e2e",
                    surface: "#313244",
                    surfaceAlt: "#45475a",
                    text: "#cdd6f4",
                    primary: "#89b4fa",
                    onPrimary: "#1e1e2e",
                    accent: "#a6e3a1",
                    border: "#585b70",
                    textAlt: "#bac2de"
                }
            }
        ]
        currentThemeData = availableThemes[0]
        themesDiscovered(availableThemes)
    }
    
    function refreshThemes() {
        console.log("ThemeService: Refreshing theme list...")
        themeDiscovery.running = true
    }
    
    
    // Lazy load all themes only when needed (e.g., when theme selector opens)
    function loadAllThemes() {
        if (availableThemes.length > 0) {
            console.log("ThemeService: Themes already loaded")
            return
        }
        
        console.log("ThemeService: Lazy loading all themes...")
        themeDiscovery.running = true
    }
    
    // Initialization
    Component.onCompleted: {
        console.log("ThemeService: Initializing...")
        
        // Discover available themes for cycling
        refreshThemes()
        
        // Load theme from config if already available
        if (configService && configService.initialized) {
            loadThemeFromConfig()
        }
        
        initialized = true
        console.log("ThemeService: Initialization complete")
    }
}