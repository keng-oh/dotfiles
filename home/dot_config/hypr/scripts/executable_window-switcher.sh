#!/usr/bin/env bash
# 開いているウィンドウの一覧を画面中央に出し、選んだウィンドウへ移動する。
# 素早く切り替えたいときは Super+Tab(固定順で即移動)を使い、
# 目的のウィンドウを目で探したいときはこちらを使う。
set -euo pipefail

style="$HOME/.config/wofi/switcher-style.css"

# wofiのdmenuモードは選択履歴をキャッシュし、よく選んだ項目を先頭へ繰り上げる。
# ウィンドウ一覧では並び順が崩れて邪魔なので、毎回消してから使う。
# (/dev/null を指定すると空行が1件のエントリとして表示されてしまうため、
#  実ファイルを指定して起動前に削除する)
cache="${XDG_RUNTIME_DIR:-/tmp}/wofi-window-switcher"
rm -f "$cache"

# 既に開いていれば閉じるだけ(トグル)
if pkill -f -- "--style $style" 2>/dev/null; then
  exit 0
fi

# 表示用の行と、その行に対応するウィンドウアドレスの対応表を作る。
# アドレスを行に埋め込むとwofi上に見えてしまうため、表示テキストとは分けて保持する。
declare -A addr_of
display=""

while IFS=$'\t' read -r line addr; do
  [ -z "$addr" ] && continue
  addr_of["$line"]="$addr"
  display+="$line"$'\n'
done < <(
  # モニター順、その中はワークスペース番号順に並べる(同じ番号内は画面上の位置順)。
  # モニターは番号で持っているので名前に置き換える。
  monitors=$(hyprctl monitors -j)
  hyprctl clients -j | jq -r --argjson mons "$monitors" '
    ($mons | map({key: (.id | tostring), value: .name}) | from_entries) as $names
    | sort_by(.monitor, .workspace.id, .at[1], .at[0])
    | .[]
    | "[\($names[.monitor | tostring] // "?")] [\(.workspace.id)] \(.title)\t\(.address)"
  '
)

[ -z "$display" ] && exit 0

# 高さはウィンドウ数に合わせる(多すぎるときは画面からはみ出さないよう頭打ち)
lines=$(printf '%s' "$display" | grep -c .)
[ "$lines" -gt 15 ] && lines=15

# 末尾の改行を残すとwofiがその後ろを空の項目として拾ってしまうため削る
selected=$(printf '%s' "${display%$'\n'}" | wofi \
  --show dmenu \
  --prompt "window title" \
  --width 720 \
  --lines "$lines" \
  --no-actions \
  --insensitive \
  --location center \
  --define single_click=true \
  --cache-file "$cache" \
  --style "$style")

if [ -n "${selected:-}" ] && [ -n "${addr_of[$selected]:-}" ]; then
  hyprctl dispatch focuswindow "address:${addr_of[$selected]}" >/dev/null
fi
