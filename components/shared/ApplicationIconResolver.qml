import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: iconResolver
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.application.iconresolver"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Service state
    property bool initialized: false
    property var iconCache: ({})
    
    // Configuration
    property string fallbackIcon: "application-x-executable"
    property string fallbackEmoji: "⬜"
    
    // Common application class to icon mappings
    readonly property var iconMappings: ({
        // Browsers
        "firefox": "firefox",
        "chromium": "chromium",
        "google-chrome": "google-chrome",
        "brave-browser": "brave-browser",
        "microsoft-edge": "microsoft-edge",
        
        // Terminals
        "kitty": "terminal",
        "alacritty": "terminal", 
        "foot": "terminal",
        "wezterm": "terminal",
        "gnome-terminal": "terminal",
        "konsole": "terminal",
        "xterm": "terminal",
        
        // Code Editors
        "code": "visual-studio-code",
        "codium": "vscodium",
        "neovim": "nvim",
        "vim": "vim",
        "emacs": "emacs",
        "atom": "atom",
        "sublime_text": "sublime-text",
        
        // Communication
        "discord": "discord",
        "slack": "slack",
        "signal": "signal-desktop",
        "telegram": "telegram",
        "zoom": "zoom",
        "teams": "teams",
        
        // Media
        "vlc": "vlc",
        "mpv": "mpv",
        "spotify": "spotify",
        "rhythmbox": "rhythmbox",
        "audacity": "audacity",
        "gimp": "gimp",
        "blender": "blender",
        "obs": "obs-studio",
        
        // File Managers
        "dolphin": "dolphin",
        "nautilus": "nautilus",
        "thunar": "thunar",
        "pcmanfm": "pcmanfm",
        "ranger": "folder-manager",
        
        // System Tools
        "htop": "system-monitor",
        "btop": "system-monitor",
        "system-monitor": "system-monitor",
        "gnome-system-monitor": "gnome-system-monitor",
        
        // Gaming
        "steam": "steam",
        "lutris": "lutris",
        "minecraft": "minecraft",
        
        // Office
        "libreoffice": "libreoffice",
        "writer": "libreoffice-writer",
        "calc": "libreoffice-calc",
        "impress": "libreoffice-impress",
        
        // Default fallbacks for unknown applications
        "unknown": "application-x-executable"
    })
    
    // Get icon path for a window class
    function getIconForClass(windowClass) {
        if (!windowClass || windowClass === "unknown") {
            return fallbackEmoji
        }
        
        const normalizedClass = windowClass.toLowerCase()
        
        // Check cache first
        if (iconCache[normalizedClass]) {
            return iconCache[normalizedClass]
        }
        
        let iconPath = null
        
        // Try mapped icon names first
        const mappedName = iconMappings[normalizedClass]
        if (mappedName) {
            iconPath = Quickshell.iconPath(mappedName, true)
            console.log(logCategory, `Trying mapped icon "${mappedName}" for class "${normalizedClass}": ${iconPath || "NOT FOUND"}`)
            if (iconPath && iconPath !== "") {
                iconCache[normalizedClass] = iconPath
                return iconPath
            }
        }
        
        // Try the class name directly
        iconPath = Quickshell.iconPath(normalizedClass, true)
        console.log(logCategory, `Trying direct icon "${normalizedClass}": ${iconPath || "NOT FOUND"}`)
        if (iconPath && iconPath !== "") {
            iconCache[normalizedClass] = iconPath
            return iconPath
        }
        
        // Try with common suffixes removed
        const baseClass = normalizedClass.replace(/-.*$/, "").replace(/\..*$/, "")
        if (baseClass !== normalizedClass) {
            iconPath = Quickshell.iconPath(baseClass, true)
            console.log(logCategory, `Trying base icon "${baseClass}": ${iconPath || "NOT FOUND"}`)
            if (iconPath && iconPath !== "") {
                iconCache[normalizedClass] = iconPath
                return iconPath
            }
        }
        
        // Try fallback icon with emoji backup
        iconPath = Quickshell.iconPath(fallbackIcon, fallbackEmoji)
        console.log(logCategory, `Using fallback for class "${normalizedClass}": ${iconPath}`)
        iconCache[normalizedClass] = iconPath
        return iconPath
    }
    
    // Get consolidated icon data for a workspace
    function getIconsForWorkspace(workspaceId, windowsByWorkspace) {
        const windows = windowsByWorkspace[workspaceId] || []
        const iconCounts = {}
        
        windows.forEach(window => {
            const iconPath = getIconForClass(window.class)
            iconCounts[iconPath] = (iconCounts[iconPath] || 0) + 1
        })
        
        return iconCounts
    }
    
    // Get sorted list of icons with counts for display
    function getSortedIconsForWorkspace(workspaceId, windowsByWorkspace, maxIcons = 3) {
        const iconCounts = getIconsForWorkspace(workspaceId, windowsByWorkspace)
        const entries = Object.entries(iconCounts)
        
        // Sort by count (descending), then by icon path (ascending)
        entries.sort((a, b) => {
            if (b[1] !== a[1]) {
                return b[1] - a[1] // Sort by count descending
            }
            return a[0].localeCompare(b[0]) // Sort by icon path ascending
        })
        
        // Limit to maxIcons
        return entries.slice(0, maxIcons).map(([iconPath, count]) => ({
            iconPath: iconPath,
            count: count,
            isEmoji: !iconPath.startsWith("/") && !iconPath.startsWith("file://") && !iconPath.startsWith("image://")
        }))
    }
    
    // Get total window count for a workspace
    function getWindowCountForWorkspace(workspaceId, windowsByWorkspace) {
        const windows = windowsByWorkspace[workspaceId] || []
        return windows.length
    }
    
    // Clear icon cache (useful for testing or memory management)
    function clearCache() {
        console.log(logCategory, "Clearing icon cache")
        iconCache = {}
    }
    
    // Get cache statistics
    function getCacheStats() {
        return {
            size: Object.keys(iconCache).length,
            entries: iconCache
        }
    }
    
    // Initialization
    Component.onCompleted: {
        console.log(logCategory, "Initializing application icon resolver...")
        initialized = true
        console.log(logCategory, "Icon resolver initialization complete")
    }
}