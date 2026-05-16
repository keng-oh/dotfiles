{ config, pkgs, lib, ... }:

{
  # Ubuntu/Pop!OS固有の設定
  home.sessionVariables = { };

  # fcitx5 環境変数（Wayland用）
  home.file.".config/environment.d/fcitx.conf".text = ''
    GTK_IM_MODULE=fcitx
    QT_IM_MODULE=fcitx
    XMODIFIERS=@im=fcitx
  '';

  programs.zsh.shellAliases = {
    update = "sudo apt update && sudo apt upgrade -y";
    hms = "home-manager switch --impure --flake ~/repos/dotfiles#ubuntu";
  };

  home.activation.ubuntuApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # snap アプリ
    sudo snap install wezterm --classic || true
    sudo snap install code --classic || true
    sudo snap install obsidian --classic || true
    sudo snap install discord || true
    sudo snap install spotify || true
    sudo snap install 1password || true

    # Chrome（wget → apt）
    if ! command -v google-chrome-stable &>/dev/null; then
      wget -q -O /tmp/google-chrome.deb \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      sudo apt install -y /tmp/google-chrome.deb
      rm /tmp/google-chrome.deb
    fi

    # fcitx5（日本語入力）
    sudo apt install -y \
      fcitx5 \
      fcitx5-mozc \
      fcitx5-config-qt \
      fcitx5-frontend-gtk3 \
      fcitx5-frontend-gtk4 \
      fcitx5-frontend-qt5 \
      fcitx5-frontend-qt6
    im-config -n fcitx5

    # Docker Engine
    if ! command -v docker &>/dev/null; then
      curl -fsSL https://get.docker.com | sudo sh
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
    fi
  '';
}
