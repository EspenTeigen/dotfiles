#!/bin/bash

WALLPAPER_DIR="$HOME/.config/sway/wallpapers"
INTERVAL=600  # Change wallpaper every 10 minutes (600 seconds)

# Function to set wallpaper on all outputs
set_wallpaper() {
    local wallpaper="$1"
    swaymsg output "*" bg "$wallpaper" fill
}

# Function to get next wallpaper in sequence
get_next_wallpaper() {
    ~/.config/sway/scripts/cycle-wallpaper.sh
}

# Set initial wallpaper
get_next_wallpaper

# Main rotation loop
while true; do
    sleep $INTERVAL
    get_next_wallpaper
done