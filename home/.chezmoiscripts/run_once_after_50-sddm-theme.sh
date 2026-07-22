#!/bin/bash
# SDDM astronaut テーマ設定（テーマ本体は sddm-astronaut-theme パッケージが
# /usr/share/sddm/themes/sddm-astronaut-theme に配置する）
set -euo pipefail
if [ ! -f /etc/sddm.conf.d/theme.conf ]; then
  echo "==> SDDM テーマを設定"
  sudo mkdir -p /etc/sddm.conf.d
  printf '[Theme]\nCurrent=sddm-astronaut-theme\n' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
fi
