#!/usr/bin/env bash
# Nix を完全に削除して初期化するスクリプト
# 既存の Home Manager 環境もすべて消えるので注意

set -uo pipefail

echo "==> Nix を完全に削除します（既存の Home Manager 環境も消えます）"
read -rp "続行しますか? [y/N]: " ans
if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "中止しました"
    exit 0
fi

echo "==> nix-daemon を停止..."
sudo systemctl stop nix-daemon.service 2>/dev/null || true
sudo systemctl stop nix-daemon.socket 2>/dev/null || true
sudo systemctl disable nix-daemon.service 2>/dev/null || true
sudo systemctl disable nix-daemon.socket 2>/dev/null || true
sudo systemctl daemon-reload

echo "==> Nix 関連ファイルを削除..."
sudo rm -rf /etc/nix /nix
sudo rm -f /etc/profile.d/nix.sh /etc/profile.d/nix-daemon.sh
sudo rm -rf /root/.nix-profile /root/.nix-defexpr /root/.nix-channels
rm -rf "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels"
rm -rf "$HOME/.local/state/nix" "$HOME/.cache/nix" "$HOME/.config/nix"

echo "==> nixbld ユーザー・グループを削除..."
for i in $(seq 1 32); do
    sudo userdel "nixbld$i" 2>/dev/null || true
done
sudo groupdel nixbld 2>/dev/null || true

echo "==> シェル設定ファイルを復元..."
for f in /etc/bashrc /etc/zshrc /etc/bash.bashrc; do
    if [[ -f "${f}.backup-before-nix" ]]; then
        sudo mv "${f}.backup-before-nix" "$f"
        echo "  restored: $f"
    fi
done

echo ""
echo "✓ Nix の初期化が完了しました"
echo "  再ログイン後に bash ~/repos/dotfiles/init.sh を実行してください"
