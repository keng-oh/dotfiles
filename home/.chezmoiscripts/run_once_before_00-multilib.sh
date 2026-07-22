#!/bin/bash
# multilib リポジトリを有効化（Android SDK の32bitバイナリに必要）
set -euo pipefail
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo "==> pacman.conf: multilib リポジトリを有効化"
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
fi
