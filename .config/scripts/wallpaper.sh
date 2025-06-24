#!/bin/bash
# ~/.config/scripts/wallpaper.sh
WALLPAPERS_DIR="$HOME/.config/wallpapers"
RANDOM_WALLPAPER=$(find "$WALLPAPERS_DIR" -type f | shuf -n 1)
swaybg -i "$RANDOM_WALLPAPER" -m fill &