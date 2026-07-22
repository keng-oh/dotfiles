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

    # キーリング
    gnome-keyring
    libsecret
    gcr

    # SDDM テーマ
    sddm-astronaut

    # Hyprland エコシステム（システムレベル）
    hyprland
    xdg-desktop-portal-hyprland

    # 日本語フォント
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    # Flutter (Android) 開発用
    jdk17
  ];

  # Flutter Android 開発用の環境変数（SDK本体は paru 管理）
  home.sessionVariables = {
    ANDROID_HOME = "/opt/android-sdk";
    ANDROID_SDK_ROOT = "/opt/android-sdk";
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
  };

  home.sessionPath = [
    "/opt/android-sdk/cmdline-tools/latest/bin"
    "/opt/android-sdk/platform-tools"
    "/opt/android-sdk/emulator"
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

  # multilib リポジトリを有効化（Android SDK の32bitバイナリに必要）
  home.activation.multilibSetup = lib.hm.dag.entryBefore [ "paruPackages" ] ''
    if command -v sudo >/dev/null 2>&1 && ! grep -q "^\[multilib\]" /etc/pacman.conf; then
      echo "==> pacman.conf: multilib リポジトリを有効化"
      sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
      sudo pacman -Sy --noconfirm 2>/dev/null || true
    fi
  '';

  # paru でのみ提供されるパッケージ
  home.activation.paruPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="/usr/bin:/usr/local/bin:/bin:$PATH"
    _pkgs="
      wezterm-git
      ttf-hackgen
      xdg-desktop-portal-hyprland
      google-chrome
      docker
      docker-compose
      claude-desktop
      gnome-keyring
      android-sdk-cmdline-tools-latest
      android-sdk-platform-tools
      android-sdk-build-tools
      android-emulator
      android-udev
    "
    _missing=""
    for _pkg in $_pkgs; do
      /usr/bin/paru -Qi "$_pkg" &>/dev/null || _missing="$_missing $_pkg"
    done
    if [ -n "$_missing" ]; then
      echo "==> paru: 未インストールのパッケージを追加中:$_missing"
      /usr/bin/paru -S --needed --noconfirm $_missing </dev/tty >/dev/tty 2>&1 || true
    fi
  '';

  # fcitx5 設定ファイルをコピー（シンボリックリンクだと fcitx5 が書き込めないため）
  home.activation.fcitx5Config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FCITX5_DIR="$HOME/.config/fcitx5"
    SRC="${builtins.toString ../fcitx5}"
    mkdir -p "$FCITX5_DIR/conf"
    cp --no-preserve=mode -f "$SRC/config"               "$FCITX5_DIR/config"
    cp --no-preserve=mode -f "$SRC/profile"              "$FCITX5_DIR/profile"
    cp --no-preserve=mode -f "$SRC/conf/notifications.conf" "$FCITX5_DIR/conf/notifications.conf"
    pkill fcitx5 2>/dev/null || true
    hyprctl dispatch exec "fcitx5 -d" 2>/dev/null || true
  '';

  # Docker サービスを有効化（paruインストール後）
  home.activation.dockerSetup = lib.hm.dag.entryAfter [ "paruPackages" ] ''
    if command -v sudo >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable --now docker 2>/dev/null || true
      sudo usermod -aG docker "$USER" 2>/dev/null || true
    fi
  '';

  # Android 実機デバッグ用の adbusers グループ設定（android-udev インストール後）
  home.activation.androidUdevSetup = lib.hm.dag.entryAfter [ "paruPackages" ] ''
    if command -v sudo >/dev/null 2>&1; then
      sudo usermod -aG adbusers "$USER" 2>/dev/null || true
    fi
  '';

  # Android SDK 初期セットアップ（ライセンス同意・system image取得・AVD作成）
  home.activation.androidSdkSetup = lib.hm.dag.entryAfter [ "paruPackages" ] ''
    export PATH="/usr/bin:/usr/local/bin:/bin:$PATH"
    ANDROID_SDK_DIR="/opt/android-sdk"
    SDKMANAGER="$ANDROID_SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
    AVDMANAGER="$ANDROID_SDK_DIR/cmdline-tools/latest/bin/avdmanager"

    if [ -d "$ANDROID_SDK_DIR" ] && command -v sudo >/dev/null 2>&1; then
      sudo chown -R "$USER":"$USER" "$ANDROID_SDK_DIR" 2>/dev/null || true

      if [ -x "$SDKMANAGER" ]; then
        echo "==> Android SDK: ライセンスに同意中"
        yes | "$SDKMANAGER" --sdk_root="$ANDROID_SDK_DIR" --licenses >/dev/null 2>&1 || true
        echo "==> Android SDK: platform / system-image を取得中"
        "$SDKMANAGER" --sdk_root="$ANDROID_SDK_DIR" \
          "platforms;android-36" \
          "system-images;android-36;google_apis_playstore;x86_64" >/dev/null 2>&1 || true
      fi

      if [ -x "$AVDMANAGER" ] && [ ! -d "$HOME/.android/avd/flutter_emulator.avd" ]; then
        echo "==> Android SDK: flutter_emulator AVD を作成中"
        echo no | "$AVDMANAGER" create avd \
          --path "$HOME/.android/avd/flutter_emulator.avd" \
          -n flutter_emulator \
          -k "system-images;android-36;google_apis_playstore;x86_64" >/dev/null 2>&1 || true
      fi
    fi
  '';
}
