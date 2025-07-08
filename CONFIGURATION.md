# Quickshell Hierarchical Interface Configuration

## Path Configuration

### Environment Variables
You can override default paths using environment variables:

```bash
# Custom themes directory
export QUICKSHELL_THEMES_PATH="~/my-custom-themes"

# Custom configuration file location  
export QUICKSHELL_CONFIG_PATH="~/my-quickshell-config.json"
```

### Configuration File Overrides
Alternatively, set paths and UI preferences in your configuration file:

```json
{
  "paths": {
    "themesPath": "~/themes/quickshell",
    "configPath": "~/configs/quickshell.json"
  },
  "ui": {
    "panels": {
      "height": 36,
      "borderRadius": 12,
      "margin": 15,
      "spacing": 6
    },
    "menus": {
      "width": 350,
      "itemHeight": 40,
      "maxHeight": 500
    },
    "timing": {
      "updateInterval": 1500,
      "hoverDelay": 600,
      "animationDuration": 250
    },
    "monitors": {
      "cpu": {
        "precisionDigits": 2,
        "warningThreshold": 75.0,
        "criticalThreshold": 90.0
      }
    }
  }
}
```

## Default Paths
If no overrides are set, the system uses:
- **Themes**: `~/.local/share/quickshell/by-shell/<shell-id>/config/theme/data`
- **Config**: `~/.local/share/quickshell/by-shell/<shell-id>/config/settings/config.json`

## Priority Order
1. Environment variables (highest priority)
2. Configuration file overrides
3. Default Quickshell paths (lowest priority)

## Runtime Configuration
UI settings can be modified while Quickshell is running:

```javascript
// Via ConfigService (in QML)
configService.setUISetting("panels", "height", 40)
configService.setUISetting("menus", "width", 400)

// Settings are automatically saved and take effect immediately
// No restart required!
```

### Modifiable UI Settings
- **Panel dimensions**: height, borderRadius, margin, spacing
- **Menu layout**: width, itemHeight, maxHeight
- **Timing**: updateInterval, hoverDelay, animationDuration
- **Monitor thresholds**: warningThreshold, criticalThreshold per monitor type

## Hierarchical Menu Features

### Monitor Configuration
- **Left-click**: Navigate through hierarchy
- **Right-click monitor items**: Open detailed configuration overlay
- Look for gear icons (⚙️) indicating specialized configuration

### Navigation
- **Breadcrumbs**: Show current location (e.g., "system > performance > cpu")
- **Back/Forward**: Navigate through menu history
- **Auto-hide**: Click outside menu to close

## Development

### Debug Mode
```bash
# Enable detailed logging
export QML_CONSOLE_OUTPUT=1
quickshell
```

### Custom Themes
Place theme files in your themes directory with this structure:
```
themes/
├── my-theme/
│   ├── theme.json
│   └── colors.json
```