pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: icons
    
    // System and application icons
    readonly property var categoryIcons: ({
        WebBrowser: "web",
        Printing: "print",
        Security: "security",
        Network: "chat",
        Development: "code",
        IDE: "code",
        TextEditor: "edit_note",
        Audio: "music_note",
        Music: "music_note",
        Player: "music_note",
        Game: "sports_esports",
        FileManager: "folder",
        Settings: "settings",
        TerminalEmulator: "terminal",
        Utility: "build",
        Monitor: "monitor_heart",
        Graphics: "photo_library",
        System: "computer",
        Office: "description"
    })
    
    // CPU related icons
    function getCpuIcon(): string {
        return "memory"; // CPU/processor icon
    }
    
    // GPU related icons  
    function getGpuIcon(): string {
        return "smart_display"; // GPU/graphics icon
    }
    
    // Memory related icons
    function getMemoryIcon(): string {
        return "developer_board"; // RAM/memory icon
    }
    
    // Storage related icons
    function getStorageIcon(): string {
        return "storage"; // Storage/disk icon
    }
    
    // Temperature related icons
    function getTemperatureIcon(): string {
        return "device_thermostat"; // Temperature icon
    }
    
    // Network related icons
    function getNetworkIcon(strength: int): string {
        if (strength >= 80) return "signal_wifi_4_bar";
        if (strength >= 60) return "network_wifi_3_bar";
        if (strength >= 40) return "network_wifi_2_bar";
        if (strength >= 20) return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }
    
    // Audio related icons
    function getVolumeIcon(volume: real, muted: bool): string {
        if (muted) return "volume_off";
        if (volume >= 0.7) return "volume_up";
        if (volume >= 0.3) return "volume_down";
        return "volume_mute";
    }
    
    // Battery related icons
    function getBatteryIcon(level: real, charging: bool): string {
        if (charging) {
            if (level >= 0.9) return "battery_charging_full";
            if (level >= 0.6) return "battery_charging_80";
            if (level >= 0.5) return "battery_charging_50";
            if (level >= 0.3) return "battery_charging_30";
            return "battery_charging_20";
        } else {
            if (level >= 0.9) return "battery_full";
            if (level >= 0.6) return "battery_5_bar";
            if (level >= 0.5) return "battery_4_bar";
            if (level >= 0.3) return "battery_3_bar";
            if (level >= 0.15) return "battery_2_bar";
            return "battery_1_bar";
        }
    }
    
    // Brightness related icons
    function getBrightnessIcon(): string {
        return "brightness_6";
    }
    
    // Power related icons
    function getPowerIcon(): string {
        return "power_settings_new";
    }
    
    // Notification related icons
    function getNotificationIcon(summary: string): string {
        const lower = summary.toLowerCase();
        if (lower.includes("battery")) return "power";
        if (lower.includes("network") || lower.includes("wifi")) return "wifi";
        if (lower.includes("audio") || lower.includes("volume")) return "volume_up";
        if (lower.includes("brightness")) return "brightness_6";
        if (lower.includes("screenshot")) return "screenshot";
        if (lower.includes("update")) return "system_update";
        if (lower.includes("error") || lower.includes("failed")) return "error";
        if (lower.includes("warning")) return "warning";
        if (lower.includes("success") || lower.includes("complete")) return "check_circle";
        return "notifications"; // Default notification icon
    }
    
    // Clock related icons
    function getClockIcon(): string {
        return "schedule";
    }
    
    // Calendar related icons
    function getCalendarIcon(): string {
        return "calendar_month";
    }
    
    // Settings related icons
    function getSettingsIcon(): string {
        return "settings";
    }
    
    // Menu related icons
    function getMenuIcon(): string {
        return "menu";
    }
    
    // Close related icons
    function getCloseIcon(): string {
        return "close";
    }
    
    // Expand/collapse icons
    function getExpandIcon(expanded: bool): string {
        return expanded ? "expand_less" : "expand_more";
    }
}