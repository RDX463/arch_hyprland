#!/usr/bin/env bash
WALL=$(find ~/Pictures/Wallpapers -type f | shuf -n1)
hyprctl hyprpaper preload "$WALL"
hyprctl hyprpaper wallpaper "eDP-1,$WALL"