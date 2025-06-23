#!/usr/bin/env bash
CHOICE=$(printf "󰗼  Lock\n⏻  Power-off\n  Reboot\n󰤄  Suspend" | \
         rofi -dmenu -i -p "power" -theme ~/.config/rofi/catppuccin.rasi)
case "$CHOICE" in
  *Lock*)    hyprlock ;;
  *Power*)   systemctl poweroff ;;
  *Reboot*)  systemctl reboot ;;
  *Suspend*) systemctl suspend ;;
esac