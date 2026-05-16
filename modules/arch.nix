{ config, pkgs, lib, ... }:

{
  imports = [ ./hyprland.nix ];

  home.sessionVariables = { };

  # fcitx5 環境変数（Wayland用）
  home.file.".config/environment.d/fcitx.conf".text = ''
    GTK_IM_MODULE=fcitx
    QT_IM_MODULE=fcitx
    XMODIFIERS=@im=fcitx
  '';

  programs.zsh.shellAliases = {
    update = "paru -Syu";
    hms = "home-manager switch --impure --flake ~/repos/dotfiles#arch";
  };

  # GUIアプリをparu経由でインストール
  home.activation.archApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v paru >/dev/null 2>&1; then
      paru -S --needed --noconfirm \
        wezterm \
        google-chrome \
        visual-studio-code-bin \
        ulauncher \
        obsidian \
        discord \
        spotify \
        1password \
        docker \
        docker-compose \
        fcitx5 \
        fcitx5-mozc \
        fcitx5-qt \
        fcitx5-gtk \
        fcitx5-configtool \
        hyprland \
        xdg-desktop-portal-hyprland \
        ttf-hackgen-nerd
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
    else
      echo "⚠ paru が見つかりません。手動でGUIアプリをインストールしてください"
      echo "  paru -S wezterm google-chrome visual-studio-code-bin ulauncher obsidian discord spotify 1password docker docker-compose"
    fi
  '';
}
