# Hyprland Configuration Setup

## Global Shortcut for Settings

Add this line to your `~/.config/hypr/hyprland.conf`:

```bash
# Quickshell settings overlay
bind = SUPER, comma, global, quickshell:show-settings
```

This binds `Super + ,` to open the settings overlay.

## Alternative Shortcuts

You can customize the key combination:

```bash
# Alternative bindings
bind = SUPER_SHIFT, s, global, quickshell:show-settings
bind = SUPER, F12, global, quickshell:show-settings
bind = CTRL_ALT, t, global, quickshell:show-settings
```

## Access Methods

The settings overlay can be opened via:

1. **Global shortcut**: `Super + ,` (after adding to Hyprland config)
2. **Right-click**: Right-click anywhere on the bar
3. **Programmatic**: Call `showSettings()` from QML code

## Reload Configuration

After editing your Hyprland config:
```bash
hyprctl reload
```

The global shortcut will be immediately available.