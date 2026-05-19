{ config, pkgs, lib, ... }:

{
  imports = [ ./hyprland.nix ];

  home.packages = with pkgs; [
    # エディタ
    vscode

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
    export PATH="/usr/bin:/usr/local/bin:/bin:$PATH"
    if command -v paru >/dev/null 2>&1; then
      echo "==> paru: パッケージをインストール中..."
      /usr/bin/paru -S --needed \
        wezterm-git \
        ttf-hackgen \
        xdg-desktop-portal-hyprland \
        google-chrome \
        </dev/tty >/dev/tty 2>&1 || true
    else
      echo "⚠ paru が見つかりません (PATH=$PATH)"
    fi
  '';

  # fcitx5 設定ファイルをコピー（シンボリックリンクだと fcitx5 が書き込めないため）
  home.activation.fcitx5Config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FCITX5_DIR="$HOME/.config/fcitx5"
    SRC="${builtins.toString ../fcitx5}"
    mkdir -p "$FCITX5_DIR/conf"
    cp -f "$SRC/config"               "$FCITX5_DIR/config"
    cp -f "$SRC/profile"              "$FCITX5_DIR/profile"
    cp -f "$SRC/conf/notifications.conf" "$FCITX5_DIR/conf/notifications.conf"
    pkill fcitx5 2>/dev/null || true
    fcitx5 -d 2>/dev/null &
  '';

  # Docker サービスを有効化
  home.activation.dockerSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v sudo >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
    fi
  '';
}
