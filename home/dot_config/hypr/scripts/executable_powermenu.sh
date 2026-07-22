#!/usr/bin/env bash
# ボタンを正方形・横並びにするため、フォーカス中のモニターの実効サイズから
# 表示領域を動的計算してwlogoutを絞り込む。
# 上下はwlogout独自の--margin-top/bottom、左右はCSS paddingで制御する
# (--margin-left/rightだと左右が非対称にレンダリングされる問題があったため)
read -r mon_w mon_h <<< "$(hyprctl monitors -j | jq -r '
  .[] | select(.focused==true) |
  if (.transform % 2 == 1)
  then "\((.height/.scale)|floor) \((.width/.scale)|floor)"
  else "\((.width/.scale)|floor) \((.height/.scale)|floor)"
  end
')"

button_count=5
button_size=200

row_w=$((button_count * button_size))
padding_lr=$(( (mon_w - row_w) / 2 ))
margin_tb=$(( (mon_h - button_size) / 2 ))
[ "$padding_lr" -lt 0 ] && padding_lr=0
[ "$margin_tb" -lt 0 ] && margin_tb=0

tmp_css=$(mktemp --suffix=.css)
trap 'rm -f "$tmp_css"' EXIT

cat "$HOME/.config/wlogout/style.css" > "$tmp_css"
cat >> "$tmp_css" <<EOF
window {
  padding-left: ${padding_lr}px;
  padding-right: ${padding_lr}px;
}
EOF

wlogout \
  --layout "$HOME/.config/wlogout/layout.json" \
  --css "$tmp_css" \
  --buttons-per-row 5 \
  --margin-top "$margin_tb" \
  --margin-bottom "$margin_tb"
