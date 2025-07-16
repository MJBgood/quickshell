pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: mediaService
    
    // Public properties - automatically reactive
    property bool hasActivePlayer: false
    property var currentPlayer: null
    property string trackTitle: "No Media"
    property string trackArtist: ""
    property string trackAlbum: ""
    property string albumArtUrl: ""
    property bool isPlaying: false
    property bool canPlay: false
    property bool canPause: false
    property bool canGoNext: false
    property bool canGoPrevious: false
    property real position: 0.0
    property real length: 0.0
    property bool positionSupported: false
    property string playbackState: "Stopped"
    property real volume: 1.0
    property bool volumeSupported: false
    property bool ready: false
    
    // Player management
    property var availablePlayers: []
    property int activePlayerIndex: 0
    
    // Monitor MPRIS players
    Connections {
        target: Mpris.players
        function onValuesChanged() { 
            console.log("[MediaService] MPRIS players changed")
            updatePlayerList() 
        }
        ignoreUnknownSignals: true
    }
    
    // Monitor current player changes
    Connections {
        target: currentPlayer
        function onIsPlayingChanged() { updatePlayerInfo() }
        function onTrackTitleChanged() { updatePlayerInfo() }
        function onTrackArtistChanged() { updatePlayerInfo() }
        function onTrackAlbumChanged() { updatePlayerInfo() }
        function onTrackArtUrlChanged() { updatePlayerInfo() }
        function onPlaybackStateChanged() { updatePlayerInfo() }
        function onPositionChanged() { updatePlayerInfo() }
        function onLengthChanged() { updatePlayerInfo() }
        function onVolumeChanged() { updatePlayerInfo() }
        function onCanPlayChanged() { updatePlayerInfo() }
        function onCanPauseChanged() { updatePlayerInfo() }
        function onCanGoNextChanged() { updatePlayerInfo() }
        function onCanGoPreviousChanged() { updatePlayerInfo() }
        ignoreUnknownSignals: true
    }
    
    // Internal functions
    function updatePlayerList() {
        console.log("[MediaService] Updating player list")
        console.log("[MediaService] Mpris object:", Mpris)
        console.log("[MediaService] Mpris.players:", Mpris.players)
        console.log("[MediaService] Mpris.players.length:", Mpris.players ? Mpris.players.length : "undefined")
        
        availablePlayers = []
        
        try {
            if (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0) {
                console.log("[MediaService] Found", Mpris.players.values.length, "players")
                
                // Access players through the values array
                for (let i = 0; i < Mpris.players.values.length; i++) {
                    const player = Mpris.players.values[i]
                    if (player) {
                        availablePlayers.push({
                            name: player.identity || player.dbusName || `Player ${i}`,
                            player: player,
                            index: i
                        })
                        console.log("[MediaService] Added player:", player.identity || player.dbusName)
                    }
                }
                
                // Set current player if we don't have one
                if (!currentPlayer && availablePlayers.length > 0) {
                    setActivePlayer(0)
                }
                
                hasActivePlayer = availablePlayers.length > 0
                console.log(`[MediaService] Total ${availablePlayers.length} players available`)
            } else {
                hasActivePlayer = false
                currentPlayer = null
                console.log("[MediaService] No players available - length:", Mpris.players ? Mpris.players.length : "undefined")
            }
        } catch (error) {
            console.error("[MediaService] Error updating player list:", error)
            hasActivePlayer = false
            currentPlayer = null
        }
        
        updatePlayerInfo()
    }
    
    function updatePlayerInfo() {
        if (!currentPlayer) {
            trackTitle = "No Media"
            trackArtist = ""
            trackAlbum = ""
            albumArtUrl = ""
            isPlaying = false
            canPlay = false
            canPause = false
            canGoNext = false
            canGoPrevious = false
            position = 0.0
            length = 0.0
            positionSupported = false
            playbackState = "Stopped"
            volume = 1.0
            volumeSupported = false
            ready = false
            return
        }
        
        // Update track information with fallbacks
        trackTitle = currentPlayer.trackTitle || "Unknown Title"
        trackArtist = currentPlayer.trackArtist || "Unknown Artist"
        trackAlbum = currentPlayer.trackAlbum || "Unknown Album"
        albumArtUrl = currentPlayer.trackArtUrl || ""
        
        // Update playback state
        isPlaying = currentPlayer.isPlaying || false
        playbackState = currentPlayer.playbackState || "Stopped"
        
        // Update capabilities
        canPlay = currentPlayer.canPlay || false
        canPause = currentPlayer.canPause || false
        canGoNext = currentPlayer.canGoNext || false
        canGoPrevious = currentPlayer.canGoPrevious || false
        
        // Update position info
        position = currentPlayer.position || 0.0
        length = currentPlayer.length || 0.0
        positionSupported = currentPlayer.positionSupported || false
        
        // Update volume info
        volume = currentPlayer.volume || 1.0
        volumeSupported = currentPlayer.volumeSupported || false
        
        ready = true
    }
    
    // Public API
    function play() {
        if (!currentPlayer || !canPlay) {
            console.log("[MediaService] Cannot play - no player or capability")
            return false
        }
        try {
            currentPlayer.play()
            console.log("[MediaService] Play command sent")
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to play:`, error)
            return false
        }
    }
    
    function pause() {
        if (!currentPlayer || !canPause) {
            console.log("[MediaService] Cannot pause - no player or capability")
            return false
        }
        try {
            currentPlayer.pause()
            console.log("[MediaService] Pause command sent")
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to pause:`, error)
            return false
        }
    }
    
    function togglePlayPause() {
        if (!currentPlayer) return false
        
        try {
            if (currentPlayer.canTogglePlaying) {
                currentPlayer.togglePlaying()
                console.log("[MediaService] Toggle play/pause command sent")
                return true
            } else if (isPlaying && canPause) {
                return pause()
            } else if (!isPlaying && canPlay) {
                return play()
            }
            return false
        } catch (error) {
            console.error(`[MediaService] Failed to toggle play/pause:`, error)
            return false
        }
    }
    
    function next() {
        if (!currentPlayer || !canGoNext) {
            console.log("[MediaService] Cannot go next - no player or capability")
            return false
        }
        try {
            currentPlayer.next()
            console.log("[MediaService] Next command sent")
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to go next:`, error)
            return false
        }
    }
    
    function previous() {
        if (!currentPlayer || !canGoPrevious) {
            console.log("[MediaService] Cannot go previous - no player or capability")
            return false
        }
        try {
            currentPlayer.previous()
            console.log("[MediaService] Previous command sent")
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to go previous:`, error)
            return false
        }
    }
    
    function setVolume(newVolume) {
        if (!currentPlayer || !volumeSupported) {
            console.log("[MediaService] Cannot set volume - no player or capability")
            return false
        }
        try {
            currentPlayer.volume = Math.max(0.0, Math.min(1.0, newVolume))
            console.log(`[MediaService] Volume set to: ${currentPlayer.volume}`)
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to set volume:`, error)
            return false
        }
    }
    
    function seek(offset) {
        if (!currentPlayer || !currentPlayer.canSeek) {
            console.log("[MediaService] Cannot seek - no player or capability")
            return false
        }
        try {
            // Convert seconds to microseconds for MPRIS
            currentPlayer.seek(offset * 1000000)
            console.log(`[MediaService] Seek offset: ${offset}s`)
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to seek:`, error)
            return false
        }
    }
    
    function setPosition(newPosition) {
        if (!currentPlayer || !positionSupported) {
            console.log("[MediaService] Cannot set position - no player or capability")
            return false
        }
        try {
            currentPlayer.position = Math.max(0.0, Math.min(length, newPosition))
            console.log(`[MediaService] Position set to: ${currentPlayer.position}s`)
            return true
        } catch (error) {
            console.error(`[MediaService] Failed to set position:`, error)
            return false
        }
    }
    
    function setActivePlayer(index) {
        if (index < 0 || index >= availablePlayers.length) {
            console.log(`[MediaService] Invalid player index: ${index}`)
            return false
        }
        
        activePlayerIndex = index
        currentPlayer = availablePlayers[index].player
        console.log(`[MediaService] Active player set to: ${availablePlayers[index].name}`)
        
        updatePlayerInfo()
        return true
    }
    
    function getPlayerName(index) {
        if (index >= 0 && index < availablePlayers.length) {
            return availablePlayers[index].name
        }
        return "Unknown Player"
    }
    
    function getCurrentPlayerName() {
        return getPlayerName(activePlayerIndex)
    }
    
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "0:00"
        const mins = Math.floor(seconds / 60)
        const secs = Math.floor(seconds % 60)
        return `${mins}:${secs.toString().padStart(2, '0')}`
    }
    
    Component.onCompleted: {
        console.log("[MediaService] Initializing MediaService singleton")
        try {
            updatePlayerList()
        } catch (error) {
            console.error("[MediaService] Failed to initialize:", error)
        }
    }
}