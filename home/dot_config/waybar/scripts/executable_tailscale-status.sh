#!/usr/bin/env bash
# Tailscale接続状態をwaybar用JSONで出力する
state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState' 2>/dev/null)
if [ "$state" = "Running" ]; then
  ip=$(tailscale ip -4 2>/dev/null | head -1)
  echo "{\"text\": \"󰖂\", \"class\": \"connected\", \"tooltip\": \"Tailscale: 接続中 ($ip)\"}"
else
  echo "{\"text\": \"󰖂\", \"class\": \"disconnected\", \"tooltip\": \"Tailscale: 切断\"}"
fi
