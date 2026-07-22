#!/bin/bash
# Docker サービス有効化と各種グループ設定
set -euo pipefail

echo "==> Docker サービスを有効化"
sudo systemctl enable --now docker 2>/dev/null || true
sudo usermod -aG docker "$USER" 2>/dev/null || true

# Android 実機デバッグ用（android-udev）
sudo usermod -aG adbusers "$USER" 2>/dev/null || true

# swayncはhyprland.confのexec-onceで起動するため、
# pacmanパッケージ同梱のsystemdユニットとの二重起動を防ぐ
systemctl --user mask swaync.service 2>/dev/null || true
