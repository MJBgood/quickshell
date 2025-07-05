pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: wallpaperService
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.wallpaper"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Service state
    property bool initialized: false
    property bool monitoring: false
    
    // Configuration service reference
    property var configService: null
    
    // Wallpaper discovery settings
    readonly property var supportedExtensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff", "bmp"]
    readonly property string defaultWallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    
    // Current wallpaper state
    property string currentWallpaper: ""
    property var wallpapers: []
    property bool previewMode: false
    property string previewWallpaper: ""
    
    // Wallpaper directories to monitor
    property var wallpaperDirs: [defaultWallpaperDir]
    
    // State persistence using JsonAdapter (more robust than manual JSON)
    FileView {
        id: stateFile
        path: Quickshell.dataPath("wallpaper-state.json")
        watchChanges: true
        onFileChanged: loadStateFromFile()
        
        JsonAdapter {
            id: wallpaperState
            property string currentWallpaper: ""
            property var additionalDirectories: []
            property string lastUsed: ""
            
            onCurrentWallpaperChanged: {
                if (currentWallpaper !== wallpaperService.currentWallpaper) {
                    wallpaperService.currentWallpaper = currentWallpaper
                }
            }
            
            onAdditionalDirectoriesChanged: {
                const newDirs = [defaultWallpaperDir, ...additionalDirectories]
                if (JSON.stringify(newDirs) !== JSON.stringify(wallpaperDirs)) {
                    wallpaperDirs = newDirs
                }
            }
        }
        
        Component.onCompleted: {
            Qt.callLater(() => {
                if (loaded) {
                    loadStateFromFile()
                } else {
                    // Create default state file
                    wallpaperState.lastUsed = new Date().toISOString()
                    saveStateToFile()
                }
            })
        }
    }
    
    // Signals for reactive updates
    signal wallpaperChanged(string path)
    signal wallpapersDiscovered(var wallpapers)
    signal previewChanged(string path)
    signal errorOccurred(string error)
    
    // State file management functions
    function loadStateFromFile() {
        if (!stateFile.loaded) return
        
        try {
            console.log(logCategory, "Loading wallpaper state from file")
            
            // JsonAdapter automatically loads the state from file
            if (wallpaperState.currentWallpaper && wallpaperState.currentWallpaper !== currentWallpaper) {
                console.log(logCategory, "Restored wallpaper:", wallpaperState.currentWallpaper)
                currentWallpaper = wallpaperState.currentWallpaper
            }
            
            if (wallpaperState.additionalDirectories.length > 0) {
                const newDirs = [defaultWallpaperDir, ...wallpaperState.additionalDirectories]
                if (JSON.stringify(newDirs) !== JSON.stringify(wallpaperDirs)) {
                    console.log(logCategory, "Restored directories:", newDirs)
                    wallpaperDirs = newDirs
                }
            }
        } catch (error) {
            console.warn(logCategory, "Failed to load state from file:", error)
        }
    }
    
    function saveStateToFile() {
        try {
            wallpaperState.currentWallpaper = currentWallpaper
            wallpaperState.additionalDirectories = wallpaperDirs.slice(1) // Remove default directory
            wallpaperState.lastUsed = new Date().toISOString()
            stateFile.writeAdapter()
            console.log(logCategory, "Wallpaper state saved to file")
        } catch (error) {
            console.warn(logCategory, "Failed to save state to file:", error)
        }
    }
    
    // Directory creation process
    Process {
        id: directoryCreator
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log(logCategory, "Wallpaper directories created successfully")
                // Retry discovery after creating directories
                Qt.callLater(() => wallpaperDiscovery.running = true)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn(logCategory, "Directory creation warning:", this.text.trim())
                }
            }
        }
    }

    // Wallpaper discovery process
    Process {
        id: wallpaperDiscovery
        
        onRunningChanged: {
            if (running) {
                console.log(logCategory, "Discovering wallpapers in:", wallpaperDirs)
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("WallpaperService: Find command output:", this.text.trim())
                const files = this.text.trim().split('\n').filter(path => {
                    if (!path || path.length === 0) return false
                    
                    // Check if file has supported extension
                    const extension = path.split('.').pop().toLowerCase()
                    return supportedExtensions.includes(extension)
                }).sort()
                
                console.log("WallpaperService: Discovered", files.length, "wallpapers")
                
                if (files.length === 0) {
                    // No wallpapers found, provide helpful instructions
                    wallpapers = []
                    console.log("WallpaperService: No wallpapers found, will show instructions")
                } else {
                    console.log("WallpaperService: Found wallpapers:", files)
                    wallpapers = files.map(path => ({
                        path: path,
                        name: path.split('/').pop().split('.')[0],
                        filename: path.split('/').pop(),
                        directory: path.substring(0, path.lastIndexOf('/'))
                    }))
                }
                
                wallpapersDiscovered(wallpapers)
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                const errorText = this.text.trim()
                if (errorText.length > 0) {
                    // Check if it's a "directory not found" error
                    if (errorText.includes("No such file or directory")) {
                        console.log(logCategory, "Wallpaper directories don't exist, creating them...")
                        wallpaperService.createWallpaperDirectories()
                    } else {
                        console.warn(logCategory, "Wallpaper discovery error:", errorText)
                    }
                }
            }
        }
    }
    
    // File system monitoring using FileView (more efficient than inotifywait)
    Repeater {
        id: directoryWatchers
        model: wallpaperDirs
        
        delegate: Item {
            property string directory: modelData
            
            FileView {
                path: directory + "/.wallpaper_monitor"  // Dummy file for directory watching
                watchChanges: true
                printErrors: false  // Don't spam logs for non-existent monitor file
                
                // Create a simple monitor mechanism by watching directory timestamps
                onFileChanged: {
                    console.log(logCategory, "Directory change detected in:", directory)
                    Qt.callLater(() => discoverWallpapers())
                }
                
                Component.onCompleted: {
                    // Create monitor file if it doesn't exist (timestamps will change when dir changes)
                    Qt.callLater(() => {
                        try {
                            setText(Date.now().toString())
                        } catch (e) {
                            // Silently ignore if we can't create the file
                        }
                    })
                }
            }
        }
    }
    
    // Fallback directory monitoring using native filesystem watching
    Timer {
        id: periodicRefresh
        interval: 30000  // 30 seconds
        running: monitoring && wallpaperDirs.length > 0
        repeat: true
        onTriggered: {
            console.log(logCategory, "Periodic wallpaper refresh")
            discoverWallpapers()
        }
    }
    
    // Public API Functions
    
    /**
     * Start wallpaper service and begin monitoring
     */
    function startService() {
        if (initialized) return
        
        console.log(logCategory, "Starting wallpaper service...")
        
        // Load state from file
        if (stateFile.loaded) {
            loadStateFromFile()
        }
        
        // Start wallpaper discovery
        discoverWallpapers()
        
        // Start file system monitoring
        startMonitoring()
        
        initialized = true
        console.log(logCategory, "Wallpaper service started")
    }
    
    /**
     * Create wallpaper directories if they don't exist
     */
    function createWallpaperDirectories() {
        const dirsToCreate = wallpaperDirs.filter(dir => dir && dir.trim().length > 0)
        if (dirsToCreate.length === 0) return
        
        console.log(logCategory, "Creating wallpaper directories:", dirsToCreate)
        
        // Build mkdir command for all directories
        let mkdirCommand = ["mkdir", "-p"]
        mkdirCommand.push(...dirsToCreate)
        
        directoryCreator.command = mkdirCommand
        directoryCreator.running = true
    }

    /**
     * Discover wallpapers in configured directories
     */
    function discoverWallpapers() {
        if (wallpaperDirs.length === 0) {
            console.warn(logCategory, "No wallpaper directories configured")
            return
        }
        
        // Build find command for all directories
        let findCommand = ["find"]
        
        // Add all directories
        for (const dir of wallpaperDirs) {
            findCommand.push(dir)
        }
        
        // Add find parameters
        findCommand.push("-type", "f", "-readable")
        
        // Filter for supported extensions - use -name instead of -iregex for better compatibility
        findCommand.push("(")
        for (let i = 0; i < supportedExtensions.length; i++) {
            if (i > 0) {
                findCommand.push("-o")
            }
            findCommand.push("-iname", `*.${supportedExtensions[i]}`)
        }
        findCommand.push(")")
        
        wallpaperDiscovery.command = findCommand
        wallpaperDiscovery.running = true
    }
    
    /**
     * Start monitoring wallpaper directories for changes
     */
    function startMonitoring() {
        if (monitoring) return
        
        console.log(logCategory, "Starting directory monitoring for:", wallpaperDirs.length, "directories")
        monitoring = true
        
        // FileView watchers are automatically managed by the Repeater
        // Periodic refresh timer will also start
    }
    
    /**
     * Stop monitoring wallpaper directories
     */
    function stopMonitoring() {
        if (!monitoring) return
        
        monitoring = false
        console.log(logCategory, "Stopped wallpaper monitoring")
    }
    
    /**
     * Set current wallpaper using Hyprland's native wallpaper functionality
     */
    function setWallpaper(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath === currentWallpaper) return
        
        console.log(logCategory, "Setting wallpaper:", wallpaperPath)
        
        // Verify file exists and is readable
        if (!isValidWallpaper(wallpaperPath)) {
            console.warn(logCategory, "Invalid wallpaper path:", wallpaperPath)
            errorOccurred("Invalid wallpaper: " + wallpaperPath)
            return
        }
        
        // Use external wallpaper command since Hyprland doesn't have built-in wallpaper support
        try {
            console.log("WallpaperService: Applying wallpaper using external command")
            
            // Use swaybg as the wallpaper tool (standard for Wayland)
            const wallpaperCommand = ["swaybg", "-i", wallpaperPath, "-m", "fill"]
            console.log("WallpaperService: Running wallpaper command:", wallpaperCommand.join(" "))
            
            // Kill any existing swaybg processes first
            wallpaperSetter.command = ["pkill", "swaybg"]
            wallpaperSetter.running = true
            
            // Wait a moment, then start the new wallpaper
            Qt.callLater(() => {
                wallpaperSetter.command = wallpaperCommand
                wallpaperSetter.running = true
                
                const previousWallpaper = currentWallpaper
                currentWallpaper = wallpaperPath
                
                // Save to state file
                saveStateToFile()
                
                wallpaperChanged(wallpaperPath)
                console.log("WallpaperService: Wallpaper changed from", previousWallpaper, "to", wallpaperPath)
            })
            
        } catch (error) {
            console.error("WallpaperService: Failed to set wallpaper:", error)
            errorOccurred("Failed to set wallpaper: " + error)
        }
    }
    
    /**
     * Start wallpaper preview mode
     */
    function startPreview(wallpaperPath) {
        if (!isValidWallpaper(wallpaperPath)) {
            console.warn(logCategory, "Invalid preview wallpaper:", wallpaperPath)
            return
        }
        
        console.log(logCategory, "Starting wallpaper preview:", wallpaperPath)
        previewWallpaper = wallpaperPath
        previewMode = true
        previewChanged(wallpaperPath)
    }
    
    /**
     * Stop wallpaper preview mode
     */
    function stopPreview() {
        if (!previewMode) return
        
        console.log(logCategory, "Stopping wallpaper preview")
        previewMode = false
        previewWallpaper = ""
        previewChanged("")
    }
    
    /**
     * Apply current preview as wallpaper
     */
    function applyPreview() {
        if (!previewMode || !previewWallpaper) return
        
        setWallpaper(previewWallpaper)
        stopPreview()
    }
    
    /**
     * Get random wallpaper from collection
     */
    function getRandomWallpaper() {
        if (wallpapers.length === 0) return null
        
        const randomIndex = Math.floor(Math.random() * wallpapers.length)
        return wallpapers[randomIndex]
    }
    
    /**
     * Set random wallpaper
     */
    function setRandomWallpaper() {
        const randomWallpaper = getRandomWallpaper()
        if (randomWallpaper) {
            setWallpaper(randomWallpaper.path)
        }
    }
    
    /**
     * Search wallpapers by name (simple string matching)
     */
    function searchWallpapers(query) {
        if (!query || query.trim().length === 0) return wallpapers
        
        const lowerQuery = query.toLowerCase()
        return wallpapers.filter(wallpaper => 
            wallpaper.name.toLowerCase().includes(lowerQuery) ||
            wallpaper.filename.toLowerCase().includes(lowerQuery) ||
            wallpaper.path.toLowerCase().includes(lowerQuery)
        )
    }
    
    /**
     * Get wallpaper info by path
     */
    function getWallpaperInfo(wallpaperPath) {
        return wallpapers.find(w => w.path === wallpaperPath) || null
    }
    
    /**
     * Add wallpaper directory
     */
    function addWallpaperDirectory(directoryPath) {
        if (!directoryPath || wallpaperDirs.includes(directoryPath)) return
        
        console.log(logCategory, "Adding wallpaper directory:", directoryPath)
        wallpaperDirs.push(directoryPath)
        
        // Save to state file
        saveStateToFile()
        
        // Refresh discovery and monitoring
        discoverWallpapers()
        if (monitoring) {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    /**
     * Remove wallpaper directory
     */
    function removeWallpaperDirectory(directoryPath) {
        const index = wallpaperDirs.indexOf(directoryPath)
        if (index === -1 || directoryPath === defaultWallpaperDir) return
        
        console.log(logCategory, "Removing wallpaper directory:", directoryPath)
        wallpaperDirs.splice(index, 1)
        
        // Save to state file
        saveStateToFile()
        
        // Refresh discovery and monitoring
        discoverWallpapers()
        if (monitoring) {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    /**
     * Validate wallpaper file
     */
    function isValidWallpaper(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath.trim().length === 0) return false
        
        const extension = wallpaperPath.split('.').pop().toLowerCase()
        return supportedExtensions.includes(extension)
    }
    
    /**
     * Get current wallpaper for display
     */
    function getCurrentDisplayWallpaper() {
        return previewMode ? previewWallpaper : currentWallpaper
    }
    
    // Wallpaper setter process
    Process {
        id: wallpaperSetter
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("WallpaperService: Wallpaper command output:", this.text.trim())
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("WallpaperService: Wallpaper command error:", this.text.trim())
                }
            }
        }
        
        onRunningChanged: {
            if (!running) {
                console.log("WallpaperService: Wallpaper command completed")
            }
        }
    }

    // File manager opener process
    Process {
        id: fileManagerOpener
        
        onRunningChanged: {
            if (!running) {
                console.log("WallpaperService: Opened wallpaper directory in file manager")
            }
        }
    }
    
    /**
     * Open wallpaper directory in system file manager
     */
    function openWallpaperDirectory(directoryPath = "") {
        const dirToOpen = directoryPath || defaultWallpaperDir
        console.log(logCategory, "Opening wallpaper directory:", dirToOpen)
        
        // Use xdg-open to open the directory in the default file manager
        fileManagerOpener.command = ["xdg-open", dirToOpen]
        fileManagerOpener.running = true
    }
    
    /**
     * Get instructional background info when no wallpapers are found
     */
    function getInstructionalBackground() {
        return {
            isInstructional: true,
            title: "No Wallpapers Found",
            subtitle: "Add wallpapers to get started",
            instructions: [
                `Place wallpaper images in: ${defaultWallpaperDir}`,
                `Supported formats: ${supportedExtensions.join(', ')}`,
                "Right-click the desktop to change wallpapers",
                "Use the wallpaper selector to browse and preview"
            ],
            primaryAction: {
                text: "Open Wallpaper Folder",
                action: () => openWallpaperDirectory()
            },
            secondaryAction: {
                text: "Add Wallpaper Directory",
                action: () => console.log("Add directory function would be called")
            }
        }
    }
    
    /**
     * Get current wallpaper or instructional background
     */
    function getCurrentDisplayInfo() {
        if (wallpapers.length === 0) {
            return getInstructionalBackground()
        }
        
        const displayWallpaper = getCurrentDisplayWallpaper()
        if (!displayWallpaper) {
            return getInstructionalBackground()
        }
        
        return {
            isInstructional: false,
            path: displayWallpaper,
            info: getWallpaperInfo(displayWallpaper),
            isPreview: previewMode
        }
    }
    
    /**
     * Create a sample wallpaper in the default directory
     */
    function createSampleWallpaper() {
        console.log(logCategory, "Creating sample instructional wallpaper")
        
        // This would create a simple colored background with instructions
        // For now, we'll just log the intention
        console.log(logCategory, "Sample wallpaper creation not implemented yet")
    }

    /**
     * Get wallpaper statistics
     */
    function getStats() {
        return {
            totalWallpapers: wallpapers.length,
            directories: wallpaperDirs.length,
            currentWallpaper: currentWallpaper,
            previewMode: previewMode,
            monitoring: monitoring,
            supportedFormats: supportedExtensions,
            hasWallpapers: wallpapers.length > 0,
            defaultDirectory: defaultWallpaperDir
        }
    }
    
    Component.onCompleted: {
        console.log(logCategory, "WallpaperService initialized")
        console.log(logCategory, "Default wallpaper directory:", defaultWallpaperDir)
        console.log(logCategory, "Supported formats:", supportedExtensions)
        console.log(logCategory, "State file location:", Quickshell.dataPath("wallpaper-state.json"))
        
        // Start service automatically
        Qt.callLater(() => startService())
    }
}