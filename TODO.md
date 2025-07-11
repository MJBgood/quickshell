# Quickshell Project TODO

## 🧹 Current Cleanup Phase

### Critical Issues to Fix First
- [ ] Fix mouse interaction system - clicks are being blocked everywhere
- [ ] Restore proper top-center hover activation for dashboard menu
- [ ] Fix icon display issues (CPU and notification widgets)
- [ ] Ensure dashboard animation works like caelestia (fluid growth from border)

### Project Cleanup Tasks
- [x] Remove unused bar components (`DynamicBar.qml`, `QuickMenu.qml`)
- [ ] Audit `@components/widgets/` directory for unused files
- [ ] Audit `@components/overlays/` directory for unused files  
- [ ] Audit `@services/` directory for unused services
- [ ] Clean up import statements across all files
- [ ] Remove legacy/commented code blocks
- [ ] Standardize file naming conventions

## 🔧 Bar.qml Optimizations (Post-Cleanup)

### Code Structure Improvements
- [ ] Create reusable `WidgetContainer` component to eliminate 60+ lines of duplicate code per widget
- [ ] Replace fragile anchoring chain with proper Layout system
- [ ] Extract inline quick menu (lines 915-1034) to separate component file
- [ ] Consolidate redundant service property definitions

### Configuration System Cleanup  
- [ ] Standardize configuration API usage (choose between `getValue()` vs `getEntityProperty()`)
- [ ] Remove inconsistent configuration access patterns
- [ ] Audit entity ID naming conventions across widgets

### Performance Optimizations
- [ ] Use singleton services directly instead of property passing where possible
- [ ] Optimize widget visibility bindings
- [ ] Review and optimize re-render triggers

## 🎨 Dashboard System (Post-Cleanup)

### Core Functionality
- [ ] Implement proper caelestia-style mouse detection without click blocking
- [ ] Fix height-based animation system for dashboard growth
- [ ] Add proper semi-transparent background overlay
- [ ] Implement click-outside-to-close behavior

### Visual Polish
- [ ] Ensure dashboard cards match caelestia's clean design
- [ ] Add proper progress indicators for system metrics
- [ ] Fix icon theming and color consistency
- [ ] Add smooth hover effects and transitions

## 🔍 Research & Implementation Tasks

### Icon System Research
- [ ] Research proper SVG icon implementation in Quickshell using Context7 MCP server
- [ ] Investigate Hyprland-compatible icon systems and best practices  
- [ ] Determine if Quickshell supports Qt SVG rendering without Qt5Compat
- [ ] Evaluate alternatives: system theme icons, icon fonts, or custom SVG loader
- [ ] Create implementation plan for proper icon system (SVG vs alternatives)

## 📁 File Organization (Future)

### Directory Structure Review
- [ ] Consider moving common components to `@components/common/`
- [ ] Organize overlays by type (menus, popups, etc.)
- [ ] Group related services together
- [ ] Create proper component documentation

### Import Optimization
- [ ] Remove unused imports across all files
- [ ] Standardize import order and grouping
- [ ] Use relative imports consistently

## 🧪 Testing & Validation (Final Phase)

### Functionality Testing
- [ ] Test all widget interactions and context menus
- [ ] Verify theme switching works correctly
- [ ] Test multi-monitor support
- [ ] Validate configuration persistence

### Performance Testing  
- [ ] Monitor startup time and memory usage
- [ ] Test for memory leaks in animations
- [ ] Verify smooth 60fps animations
- [ ] Check CPU usage during normal operation

---

## 📋 Completion Criteria

**Cleanup Phase Complete When:**
- All unused files identified and removed
- No broken imports or references
- All widgets load without errors
- Mouse interaction works normally

**Optimization Phase Complete When:**
- Bar.qml uses reusable components
- Configuration API is consistent
- No duplicate code patterns remain
- Dashboard system works like caelestia

**Project Complete When:**
- All functionality works as intended
- Performance is optimal
- Code is clean and maintainable
- Documentation is up to date