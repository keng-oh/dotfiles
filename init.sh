#!/usr/bin/env bash
# CachyOS 新規マシン用ブートストラップ
# curl -fsSL https://raw.githubusercontent.com/keng-oh/dotfiles/master/init.sh | bash
set -euo pipefail

# 以降のスクリプトはすべて sudo があることを前提にする。
# Proxmox VE のように root が正規の管理者で sudo が入っていない環境があるため、
# 分岐はここ1箇所に閉じ込めて最初に導入しておく。
if ! command -v sudo >/dev/null 2>&1; then
  if [ "$(id -u)" != "0" ]; then
    echo "!! sudo が無く root でもないため続行できません" >&2
    exit 1
  fi
  echo "==> sudo をインストール"
  if command -v pacman >/dev/null 2>&1; then
    pacman -S --needed --noconfirm sudo
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq sudo
  fi
fi

echo "==> git / chezmoi をインストール"
if command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm git chezmoi
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq git curl
  # chezmoiはaptに無いため公式スクリプトで /usr/local/bin に導入
  if ! command -v chezmoi >/dev/null 2>&1; then
    sh -c "$(curl -fsSL get.chezmoi.io)" -- -b /usr/local/bin || \
      sudo sh -c "$(curl -fsSL get.chezmoi.io)" -- -b /usr/local/bin
  fi
else
  echo "!! 未対応のディストリビューションです" >&2
  exit 1
fi

if [ ! -d "$HOME/repos/dotfiles" ]; then
  echo "==> dotfiles をクローン"
  mkdir -p "$HOME/repos"
  git clone https://github.com/keng-oh/dotfiles "$HOME/repos/dotfiles"
fi

echo "==> chezmoi のソースディレクトリを設定"
mkdir -p "$HOME/.config/chezmoi"
printf 'sourceDir = "~/repos/dotfiles"\n' > "$HOME/.config/chezmoi/chezmoi.toml"

echo "==> 適用(パッケージインストール・セットアップスクリプト・設定配置)"
# -k: 1Password未ログインなど後続の手動ステップに依存するファイル(rclone.conf等)で
#     エラーになっても、他のファイルの適用は続行する。
# それでも該当ファイル分のエラーで終了コードが非ゼロになるため、
# set -e で止まらないよう結果に関わらず続行する(手動ステップ完了後にmake switchで再適用する前提)
chezmoi apply -k || echo "!! 一部のファイルが未適用です(1Password等の手動ステップ完了後に make switch で再適用してください)" >&2

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  echo "==> デフォルトシェルを /usr/bin/zsh に変更"
  sudo usermod -s /usr/bin/zsh "$USER"
fi

echo "✓ 完了。再ログインするとHyprlandセッション + zshが有効になります"
