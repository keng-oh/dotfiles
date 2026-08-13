#!/usr/bin/env bash
# アクティブウィンドウのアプリケーション名(class)を表示する。
# target_cells(表示セル幅。全角=2, 半角=1)を超える場合は横スクロール(マーキー)表示にする。
target_cells=40
slicer="$HOME/.config/waybar/scripts/marquee-slice.py"
offset=0
prev_title=""
static_line=""
first=1

# 注: waybarはモニターごとにバーを生成し、このスクリプトもバーの数だけ起動する。
# 複数プロセスが並走しているのは正常なので、重複起動を防いではいけない。

while true; do
  title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

  if [ -z "$title" ]; then
    # 空表示は一度出せば十分なので、状態が変わった時だけ出力する
    if [ "$prev_title" != "__empty__" ]; then
      echo ""
      prev_title="__empty__"
      static_line=""
    fi
    sleep 0.3
    continue
  fi

  if [ "$title" != "$prev_title" ]; then
    offset=0
    prev_title="$title"
    static_line=""
    first=1
  fi

  # target_cells に収まる名前はスクロールせず、出力が毎回同じになる。
  # slicerはPython起動で1回あたり11msかかるので、確定した行はキャッシュして呼ばない。
  if [ -n "$static_line" ]; then
    sleep 0.3
    continue
  fi

  result=$("$slicer" "$title" "$target_cells" "$offset")
  line="${result%%$'\n'*}"
  offset="${result##*$'\n'}"
  echo "$line"

  # offset=0 のまま返るのは収まりきった時だけ。スクロール中も一周すると0に戻るため、
  # 判定はタイトル変更直後の1回目に限る。
  if [ "$first" = "1" ] && [ "$offset" = "0" ]; then
    static_line="$line"
  fi
  first=0

  sleep 0.3
done
