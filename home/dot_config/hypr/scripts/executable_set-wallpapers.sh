#!/usr/bin/env sh

WALLPAPER_DIR="$HOME/repos/dotfiles/wallpapers"

# description -> (port名, 壁紙) のマッピング
hyprctl monitors -j | jq -r '.[] | .name + " " + .description' | while read -r port desc; do
    case "$desc" in
        *IPS28UHDRC65W*)
            awww img "$WALLPAPER_DIR/17_Catppuccin_Mocha.jpg" --transition-type fade -o "$port" ;;
        *28I144UR-C65W*)
            awww img "$WALLPAPER_DIR/wallhaven-qdxpjd.jpg" --transition-type fade -o "$port" ;;
        *)
            awww img "$WALLPAPER_DIR/cat_anime-girl.png" --transition-type fade -o "$port" ;;
    esac
done
