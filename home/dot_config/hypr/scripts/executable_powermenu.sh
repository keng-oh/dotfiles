#!/usr/bin/env bash
options="󰐥  Shutdown\n󰒲  Sleep\n󰜉  Reboot\n󰌾  Lock\n󰗽  Logout"
chosen=$(echo -e "$options" | wofi \
  --show dmenu \
  --prompt "" \
  --width 220 \
  --height 235 \
  --no-actions \
  --insensitive)
case "$chosen" in
  "󰐥  Shutdown") systemctl poweroff ;;
  "󰒲  Sleep")    systemctl suspend ;;
  "󰜉  Reboot")   systemctl reboot ;;
  "󰌾  Lock")     hyprlock ;;
  "󰗽  Logout")   hyprctl dispatch exit ;;
esac
