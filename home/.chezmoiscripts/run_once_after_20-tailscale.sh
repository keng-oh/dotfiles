#!/bin/bash
# Tailscale クライアント（公式インストールスクリプト経由）
# systemd/root統合が必要なため、pacmanではなく公式スクリプトでインストールする
set -euo pipefail
# CIでは外部サービスのインストールはスキップ
[ -n "${CI:-}" ] && exit 0
if ! command -v tailscale >/dev/null 2>&1; then
  echo "==> Tailscale をインストール中"
  curl -fsSL https://tailscale.com/install.sh | sudo sh
fi
sudo systemctl enable --now tailscaled 2>/dev/null || true
