{ config, pkgs, lib, ... }:

{
  # Linux固有の設定
  home.packages = with pkgs; [
    # Flatpak（GUIアプリ管理用）
    flatpak
  ];

  # Linux固有の環境変数
  home.sessionVariables = {
    # 必要に応じて追加
  };

  # Flatpakアプリのインストール
  home.activation.flatpakApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # PATH設定
    export PATH="${pkgs.flatpak}/bin:$PATH"

    # Flathubリポジトリを追加（存在しない場合）
    if ! ${pkgs.flatpak}/bin/flatpak remote-list --user | grep -q flathub; then
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    # GUIアプリをインストール
    ${pkgs.flatpak}/bin/flatpak install -y --user flathub org.wezfurlong.wezterm || true
    ${pkgs.flatpak}/bin/flatpak install -y --user flathub com.google.Chrome || true
    ${pkgs.flatpak}/bin/flatpak install -y --user flathub com.visualstudio.code || true
    ${pkgs.flatpak}/bin/flatpak install -y --user flathub io.github.ulauncher.Ulauncher || true  # Raycast代替
  '';
}
