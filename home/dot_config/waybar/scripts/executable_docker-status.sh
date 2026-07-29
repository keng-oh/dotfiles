#!/usr/bin/env bash
# 稼働中のDockerコンテナ状況をwaybar用JSONで出力する。
# 数字は出さず、色(class)で状態を示す:
#   running   … 1個以上稼働中(正常)
#   error     … unhealthy / restarting のコンテナあり
#   stopped   … 稼働0(デーモンは動作中)
#   unavailable … dockerデーモンに接続できない

esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

icon="󰡨"

if ! docker info >/dev/null 2>&1; then
  echo "{\"text\": \"$icon\", \"class\": \"unavailable\", \"tooltip\": \"Docker: 停止中\"}"
  exit 0
fi

running=$(docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null)
count=$(printf '%s' "$running" | grep -c . )

if [ "$count" -eq 0 ]; then
  total=$(docker ps -aq 2>/dev/null | wc -l)
  echo "{\"text\": \"$icon\", \"class\": \"stopped\", \"tooltip\": \"稼働中のコンテナなし (停止中: ${total})\"}"
  exit 0
fi

if printf '%s' "$running" | grep -qiE 'unhealthy|restarting'; then
  class="error"
else
  class="running"
fi

tooltip=$(printf '%s' "$running" \
  | awk -F'\t' '{printf "%s  (%s)\n", $1, $2}' \
  | esc \
  | sed -e 's/$/\\n/' \
  | tr -d '\n' \
  | sed -e 's/\\n$//')

echo "{\"text\": \"$icon\", \"class\": \"$class\", \"tooltip\": \"稼働中 ${count}件\\n\\n${tooltip}\"}"
