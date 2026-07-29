#!/usr/bin/env bash
# アクティブウィンドウのアプリケーション名(class)を表示する。
# target_cells(表示セル幅。全角=2, 半角=1)を超える場合は横スクロール(マーキー)表示にする。
target_cells=40
slicer="$HOME/.config/waybar/scripts/marquee-slice.py"
offset=0
prev_title=""

while true; do
  title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

  if [ -z "$title" ]; then
    echo ""
    sleep 0.3
    continue
  fi

  if [ "$title" != "$prev_title" ]; then
    offset=0
    prev_title="$title"
  fi

  result=$("$slicer" "$title" "$target_cells" "$offset")
  echo "${result%%$'\n'*}"
  offset="${result##*$'\n'}"

  sleep 0.3
done
