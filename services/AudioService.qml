pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: audioService
    
    // Public properties - automatically reactive
    property real volume: 0.0
    property bool muted: false
    property string deviceName: "No Device"
    property bool ready: false
    
    // Internal state
    property var audioSink: null
    
    // Pipewire monitoring
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { updateAudioSink() }
        function onReadyChanged() { if (Pipewire.ready) updateAudioSink() }
    }
    
    // Bind the default sink
    PwObjectTracker {
        objects: audioService.audioSink ? [audioService.audioSink] : []
    }
    
    // Monitor sink readiness
    Connections {
        target: audioService.audioSink
        function onReadyChanged() {
            if (audioService.audioSink?.ready) {
                Qt.callLater(updateAudioInfo)
                audioService.ready = true
            }
        }
    }
    
    // Monitor audio property changes
    Connections {
        target: audioService.audioSink?.audio || null
        function onVolumeChanged() { if (audioService.audioSink?.audio) updateAudioInfo() }
        function onMutedChanged() { if (audioService.audioSink?.audio) updateAudioInfo() }
    }
    
    // Internal functions
    function updateAudioSink() {
        if (!Pipewire.ready) return
        
        const newSink = Pipewire.defaultAudioSink
        if (newSink !== audioSink) {
            audioSink = newSink
            if (audioSink?.ready) {
                updateAudioInfo()
                ready = true
            }
        }
    }
    
    function updateAudioInfo() {
        if (!audioSink?.audio) {
            volume = 0.0
            muted = true
            deviceName = "No Device"
            return
        }
        
        const rawVolume = audioSink.audio.volume
        const rawVolumes = audioSink.audio.volumes
        
        // Handle volume properly
        if (isNaN(rawVolume) && rawVolumes?.length > 0) {
            volume = rawVolumes[0] || 0.0
        } else {
            volume = rawVolume || 0.0
        }
        
        muted = audioSink.audio.muted || false
        deviceName = audioSink.name || audioSink.description || "Audio Device"
    }
    
    // Public API
    function setVolume(newVolume) {
        console.log("[AudioService] setVolume called with:", newVolume)
        if (!audioSink?.audio) {
            console.log("[AudioService] setVolume failed - no audioSink.audio")
            return false
        }
        try {
            audioSink.audio.volume = Math.max(0.0, Math.min(1.0, newVolume))
            console.log("[AudioService] Successfully set volume to:", audioSink.audio.volume)
            return true
        } catch (error) {
            console.error(`[AudioService] Failed to set volume:`, error)
            return false
        }
    }
    
    function toggleMute() {
        if (!audioSink?.audio) return false
        try {
            audioSink.audio.muted = !audioSink.audio.muted
            return true
        } catch (error) {
            console.error(`[AudioService] Failed to toggle mute:`, error)
            return false
        }
    }
    
    function adjustVolume(delta) {
        console.log("[AudioService] adjustVolume called with delta:", delta)
        console.log("[AudioService] Current state - ready:", ready, "volume:", volume, "audioSink:", !!audioSink, "audioSink.audio:", !!audioSink?.audio, "audioSink.audio.ready:", audioSink?.audio?.ready)
        return setVolume(volume + delta)
    }
    
    Component.onCompleted: updateAudioSink()
}