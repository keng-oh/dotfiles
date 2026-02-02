{ config, pkgs, lib, ... }:

{
  # macOS固有の設定
  home.packages = with pkgs; [
    # macOS専用ツール（必要に応じて追加）
  ];

  # macOS固有の環境変数
  home.sessionVariables = {
    DOTFILES_DIR = "$HOME/repos/dotfiles";
  };

  # Homebrew Caskアプリのインストール
  home.activation.homebrewCasks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Homebrew（PATHに無い場合もあるため/opt/homebrewを優先して探す）
    BREW=""
    if [ -x /opt/homebrew/bin/brew ]; then
      BREW="/opt/homebrew/bin/brew"
    elif command -v brew >/dev/null 2>&1; then
      BREW="brew"
    fi

    if [ -z "$BREW" ]; then
      echo "⚠ Homebrewが見つかりません。GUIアプリのインストールをスキップします。"
      echo "  必要なら先にHomebrewをインストールしてください:"
      echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    else
      # GUIアプリをインストール
      "$BREW" install --cask wezterm || true
      "$BREW" install --cask google-chrome || true
      "$BREW" install --cask visual-studio-code || true
      "$BREW" install --cask raycast || true
      "$BREW" install --cask clipy || true
      "$BREW" install --cask google-japanese-ime || true
      "$BREW" install --cask karabiner-elements || true
      "$BREW" install --cask postman || true
      "$BREW" install --cask tableplus || true
      "$BREW" install --cask slack || true
      "$BREW" install --cask github || true
      "$BREW" install --cask meld || true
    fi
  '';
}
