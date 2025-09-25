#!/bin/bash

WALLPAPER_DIR="$HOME/.config/sway/wallpapers"
INDEX_FILE="/tmp/sway_wallpaper_index"

# Get all wallpapers and sort them
wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp})

# Remove failed glob patterns and sort
valid_wallpapers=()
for wp in "${wallpapers[@]}"; do
    if [[ -f "$wp" ]]; then
        valid_wallpapers+=("$wp")
    fi
done

# Sort the array
IFS=$'\n' valid_wallpapers=($(sort <<<"${valid_wallpapers[*]}"))

if [[ ${#valid_wallpapers[@]} -eq 0 ]]; then
    exit 1
fi

# Read current index, default to 0
current_index=0
if [[ -f "$INDEX_FILE" ]]; then
    current_index=$(cat "$INDEX_FILE")
fi

# Increment index, wrap around if needed
next_index=$(( (current_index + 1) % ${#valid_wallpapers[@]} ))

# Save new index
echo "$next_index" > "$INDEX_FILE"

# Set wallpaper
swaymsg output "*" bg "${valid_wallpapers[$next_index]}" fill