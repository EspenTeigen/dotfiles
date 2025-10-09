#!/usr/bin/env bash
# Cycle to next random wallpaper using swww

WALLPAPER_DIR="$HOME/Pictures/wallpapers-animated"

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    notify-send "No wallpapers" "Directory $WALLPAPER_DIR not found"
    exit 1
fi

# Find all supported wallpaper files
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null))

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    notify-send "No wallpapers" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Get current wallpaper to avoid repeats
CURRENT=$(swww query | grep -oP 'image: \K.*' | head -1)

# Try to find a different wallpaper
ATTEMPTS=0
MAX_ATTEMPTS=10
while [[ $ATTEMPTS -lt $MAX_ATTEMPTS ]]; do
    NEXT="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"
    if [[ "$NEXT" != "$CURRENT" ]] || [[ ${#WALLPAPERS[@]} -eq 1 ]]; then
        break
    fi
    ((ATTEMPTS++))
done

# Set new wallpaper with transition
swww img "$NEXT" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 1.5 \
    --transition-fps 60

# Get filename for notification
FILENAME=$(basename "$NEXT")
notify-send "Wallpaper changed" "$FILENAME"
