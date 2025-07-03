#!/bin/bash

# Simple script to cache Quickshell documentation for development

CACHE_DIR=".docs"
CACHE_FILE="$CACHE_DIR/quickshell-hyprland.md"
CACHE_AGE_DAYS=7

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Check if cache exists and is recent
if [[ -f "$CACHE_FILE" ]]; then
    # Check if cache is less than 7 days old
    if [[ $(find "$CACHE_FILE" -mtime -$CACHE_AGE_DAYS 2>/dev/null) ]]; then
        echo "Documentation cache is recent (< $CACHE_AGE_DAYS days old)"
        echo "Use --force to refresh anyway"
        exit 0
    fi
fi

# Check for --force flag
if [[ "$1" == "--force" ]] || [[ ! -f "$CACHE_FILE" ]]; then
    echo "Fetching fresh Quickshell documentation..."
    echo "# Quickshell Hyprland Integration Documentation" > "$CACHE_FILE"
    echo "# Cached on: $(date)" >> "$CACHE_FILE"
    echo "" >> "$CACHE_FILE"
    echo "This would fetch from Context7 MCP server..." >> "$CACHE_FILE"
    echo "Documentation cached to $CACHE_FILE"
else
    echo "Cache exists but is older than $CACHE_AGE_DAYS days"
    echo "Run with --force to refresh"
fi