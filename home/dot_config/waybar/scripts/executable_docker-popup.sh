#!/usr/bin/env bash
# 稼働中のDockerコンテナ一覧を右上のポップアップで表示する(閲覧のみ)。
style="$HOME/.config/wofi/docker-style.css"

# 既に開いていれば閉じるだけ(トグル)。
# --style のパスでこのポップアップ専用のwofiプロセスだけを狙い、
# ランチャー用のwofiを誤って閉じないようにする。
if pkill -f -- "--style $style" 2>/dev/null; then
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  lines="Docker デーモンが停止しています"
  count=1
else
  lines=$(docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null \
    | awk -F'\t' '{printf "%-24s %s\n", $1, $2}')
  count=$(printf '%s' "$lines" | grep -c .)
  if [ "$count" -eq 0 ]; then
    lines="稼働中のコンテナはありません"
    count=1
  fi
fi

# 選択しても何もしない(一覧表示のみ)
printf '%s\n' "$lines" | wofi \
  --show dmenu \
  --prompt "" \
  --width 520 \
  --lines "$count" \
  --no-actions \
  --insensitive \
  --hide-search \
  --location top_right \
  --xoffset -20 \
  --yoffset 10 \
  --style "$style" >/dev/null
