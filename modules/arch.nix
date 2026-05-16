{ config, pkgs, lib, ... }:

{
  imports = [ ./hyprland.nix ];

  home.packages = with pkgs; [
    # エディタ
    vscode

    # ブラウザ
    google-chrome

    # コミュニケーション
    discord

    # 音楽
    spotify

    # ノート
    obsidian

    # パスワード管理
    _1password-gui

    # ランチャー
    ulauncher

    # Docker
    docker
    docker-compose

    # Hyprland エコシステム（システムレベル）
    hyprland
    xdg-desktop-portal-hyprland

    # 日本語フォント
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

  ];

  # 日本語入力
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

  programs.zsh.shellAliases = {
    update = "paru -Syu";
    hms = "home-manager switch --impure --flake ~/repos/dotfiles#arch";
  };

  # paru でのみ提供されるパッケージ
  home.activation.paruPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /usr/bin/paru ]; then
      /usr/bin/paru -S --needed --noconfirm \
        wezterm \
        ttf-hackgen-nerd \
        xdg-desktop-portal-hyprland
    fi
  '';

  # Docker サービスを有効化
  home.activation.dockerSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v sudo >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
    fi
  '';
}
