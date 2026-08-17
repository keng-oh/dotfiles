#!/usr/bin/env bash
# ウィンドウ切替。ワークスペース順・画面上の位置順という固定の並びで巡回する。
#
# Hyprland標準の cyclenext は同一ワークスペース内しか巡回しないため、
# ワークスペースをまたぐこの環境では使えず、自前で全ウィンドウを並べている。
# 並び順が固定なので「あのウィンドウは2回先」と手が覚えられる。
set -euo pipefail

dir="${1:-next}"

mapfile -t addrs < <(
  hyprctl clients -j |
    jq -r 'sort_by(.workspace.id, .at[1], .at[0]) | .[].address'
)

count=${#addrs[@]}
[ "$count" -lt 2 ] && exit 0

current=$(hyprctl activewindow -j | jq -r '.address // empty')

# 現在のウィンドウが並びの何番目かを探す
index=0
for i in "${!addrs[@]}"; do
  if [ "${addrs[$i]}" = "$current" ]; then
    index=$i
    break
  fi
done

if [ "$dir" = "prev" ]; then
  index=$(( (index - 1 + count) % count ))
else
  index=$(( (index + 1) % count ))
fi

hyprctl dispatch focuswindow "address:${addrs[$index]}" >/dev/null
