#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# OS判定
detect_system() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "mac"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "ubuntu"
    fi
}

# Nix をこのセッションで有効化
source_nix() {
    local nix_daemon='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    local nix_profile="$HOME/.nix-profile/etc/profile.d/nix.sh"
    if [[ -e "$nix_daemon" ]]; then
        # shellcheck source=/dev/null
        source "$nix_daemon"
    elif [[ -e "$nix_profile" ]]; then
        # shellcheck source=/dev/null
        source "$nix_profile"
    fi
}

# Nix インストール
install_nix() {
    if command -v nix &>/dev/null; then
        echo "==> Nix: インストール済み"
        return
    fi
    echo "==> Nixをインストール中..."
    sh <(curl -L https://nixos.org/nix/install) --daemon
    source_nix
}

# Flakes を有効化
enable_flakes() {
    local nix_conf="$HOME/.config/nix/nix.conf"
    mkdir -p "$(dirname "$nix_conf")"
    if ! grep -q "experimental-features" "$nix_conf" 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> "$nix_conf"
        echo "==> Flakes: 有効化しました"
    else
        echo "==> Flakes: 設定済み"
    fi
}

# Home Manager を適用
apply_home_manager() {
    local system="$1"
    echo "==> Home Managerを適用中 ($system)..."
    cd "$DOTFILES_DIR"
    nix flake update --impure
    if command -v home-manager &>/dev/null; then
        home-manager switch --impure -b backup --flake ".#$system"
    else
        nix run home-manager/master --impure -- switch --impure -b backup --flake ".#$system"
    fi
}

# zsh をデフォルトシェルに設定
setup_zsh() {
    local zsh_path
    zsh_path=$(command -v zsh 2>/dev/null || echo "$HOME/.nix-profile/bin/zsh")

    if [[ ! -x "$zsh_path" ]]; then
        echo "⚠ zshが見つかりません。スキップします"
        return
    fi

    if ! grep -qF "$zsh_path" /etc/shells 2>/dev/null; then
        echo "==> /etc/shellsにzshを追加中..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        echo "==> デフォルトシェルをzshに変更中..."
        sudo usermod -s "$zsh_path" "$USER"
        echo "==> 完了（再ログイン後に反映されます）"
    else
        echo "==> zsh: 設定済み"
    fi
}

main() {
    echo "==> dotfiles セットアップ開始"
    echo ""

    source_nix
    install_nix
    enable_flakes

    local system
    system=$(detect_system)

    apply_home_manager "$system"
    setup_zsh

    echo ""
    echo "✓ セットアップ完了！"
    echo "  再ログインするとzshが起動します"
}

main
