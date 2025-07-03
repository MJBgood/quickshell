# Performance Monitor Enhancement Roadmap

## Advanced Features (Future Implementation)

### 1. Display Editor with Building Blocks
A visual editor system that treats monitor display as configurable building blocks:

#### Components:
- **Icon Block**: Draggable icon element with customizable positioning
- **Label Block**: Text label with free positioning (before, after, anywhere)
- **Value Block**: Data representation (percentage, raw values, frequencies, etc.)
- **Separator Block**: Customizable separators (|, -, •, space, custom text)

#### Features:
- **Drag & Drop Interface**: Visual arrangement of components
- **Live Preview**: Real-time preview of display format as you edit
- **Custom Separators**: User-defined separators between elements
- **Flexible Positioning**: Icon/label can go anywhere in the sequence
- **Template System**: Save/load display templates
- **Per-Monitor Customization**: Each monitor type can have unique layouts

#### Example Configurations:
```
Template 1: "🖥️ CPU 75% | 3.2GHz"
Template 2: "75% CPU (3.2GHz)"
Template 3: "CPU: 75% • 3.2GHz"
Template 4: "75%|3.2GHz 🖥️"
```

### 2. Advanced Precision Control
Separate precision settings for different data types:

#### Precision Categories:
- **Percentage Precision**: Decimal places for percentage values (0-3)
- **Value Precision**: Decimal places for raw values (CPU raw, RAM GB)
- **Frequency Precision**: Decimal places for frequency displays
- **Context-Aware Precision**: Auto-adjust based on value ranges

#### Configuration:
```json
{
  "cpu": {
    "precision": {
      "percentage": 1,
      "rawValue": 2,
      "frequency": 1
    }
  }
}
```

### 3. Container System Architecture
Flexible container system for monitor organization:

#### Default Behavior:
- Each monitor exists as an independent container
- Monitors can be positioned independently
- No visual grouping by default

#### Grouping Options:
- **Visual Container**: Optional parent container with borders/background
- **Logical Grouping**: Group monitors without visual indicators
- **Custom Layouts**: Grid, vertical, horizontal arrangements
- **Spacing Control**: Configurable gaps between monitors
- **Conditional Grouping**: Group only when multiple monitors are enabled

#### Container Types:
```
Individual: [CPU] [RAM] [Storage]
Grouped: [CPU | RAM | Storage]
Mixed: [CPU] [RAM | Storage]
```

## Low-Hanging Fruit (Immediate Implementation)

### 1. ✅ Separate Precision Settings
- Add `percentagePrecision` and `valuePrecision` to config
- Update overlay to show both precision controls
- Implement in display logic

### 2. ✅ Individual Monitor Containers
- Separate monitors into individual components
- Remove hardcoded grouping from Performance widget
- Add optional grouping configuration

### 3. ✅ Clock Widget Context Menu
- Create ClockDataOverlay similar to MonitorDataOverlay
- Add format selection, timezone options
- Implement interactive configuration

### 4. 📋 Workspace Context Menu (Future)
- Workspace-specific configuration
- Custom workspace labels
- Visibility toggles

## Implementation Priority
1. **Phase 1**: Separate precision, individual containers, clock menu
2. **Phase 2**: Advanced container system, basic building blocks
3. **Phase 3**: Full visual editor, template system
4. **Phase 4**: Workspace integration, advanced features

## Technical Architecture Notes
- Use modular overlay system (established pattern)
- Leverage existing HyprlandFocusGrab for dismissal
- Maintain consistent theming across all overlays
- Ensure configuration persistence via ConfigService
- Follow established logging patterns for debugging