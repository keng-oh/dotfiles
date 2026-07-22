#!/usr/bin/env bash
# CachyOS 新規マシン用ブートストラップ
# curl -fsSL https://raw.githubusercontent.com/keng-oh/dotfiles/master/init.sh | bash
set -euo pipefail

echo "==> git / chezmoi をインストール"
sudo pacman -S --needed --noconfirm git chezmoi

if [ ! -d "$HOME/repos/dotfiles" ]; then
  echo "==> dotfiles をクローン"
  mkdir -p "$HOME/repos"
  git clone https://github.com/keng-oh/dotfiles "$HOME/repos/dotfiles"
fi

echo "==> chezmoi のソースディレクトリを設定"
mkdir -p "$HOME/.config/chezmoi"
printf 'sourceDir = "~/repos/dotfiles"\n' > "$HOME/.config/chezmoi/chezmoi.toml"

echo "==> 適用(パッケージインストール・セットアップスクリプト・設定配置)"
chezmoi apply

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  echo "==> デフォルトシェルを /usr/bin/zsh に変更"
  sudo usermod -s /usr/bin/zsh "$USER"
fi

echo "✓ 完了。再ログインするとHyprlandセッション + zshが有効になります"
