#!/usr/bin/env bash
# Initialize swww and set initial wallpaper

set -e

# Wallpaper directory (NOT in dotfiles)
WALLPAPER_DIR="$HOME/Pictures/wallpapers-animated"
FALLBACK_COLOR="#1a1b26"

# Wait for swww daemon to be ready
sleep 1

# Check if wallpaper directory exists and has content
if [[ -d "$WALLPAPER_DIR" ]] && [[ -n "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]]; then
    # Get random wallpaper
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.png" -o -iname "*.jpg" \) | shuf -n 1)

    if [[ -n "$WALLPAPER" ]]; then
        # Set wallpaper with smooth transition
        swww img "$WALLPAPER" \
            --transition-type fade \
            --transition-duration 2 \
            --transition-fps 60
        echo "Set wallpaper: $WALLPAPER"
    else
        # No valid wallpapers, use solid color
        swww clear "$FALLBACK_COLOR"
        echo "No wallpapers found, using solid color"
    fi
else
    # Directory doesn't exist or is empty
    swww clear "$FALLBACK_COLOR"
    echo "Wallpaper directory not found, using solid color"
    echo "Create $WALLPAPER_DIR and add wallpapers"
fi
