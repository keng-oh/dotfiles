#!/bin/bash
# システムカラースキーム（GTK4/libadwaita アプリ向け）
# dconfはバイナリDBのためファイル配置では反映できず、loadで書き込む
set -euo pipefail
# CIやD-Busセッションが無い環境ではスキップ
[ -n "${CI:-}" ] && exit 0
if command -v dconf >/dev/null 2>&1; then
  dconf load /org/gnome/desktop/interface/ <<'EOF'
[/]
color-scheme='prefer-dark'
cursor-size=24
cursor-theme='Adwaita'
gtk-theme='adw-gtk3-dark'
icon-theme='Papirus-Dark'
EOF
fi
