{ config, pkgs, lib, ... }:

{
  # macOS固有の設定
  home.packages = with pkgs; [
    # macOS専用ツール（必要に応じて追加）
  ];

  home.sessionVariables = { };

  programs.zsh.shellAliases = {
    hms = "home-manager switch --impure --flake ~/repos/dotfiles#mac";
  };

  # Homebrew Caskアプリのインストール
  home.activation.homebrewCasks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Homebrewがインストールされているか確認
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrewがインストールされていません。先にHomebrewをインストールしてください:"
      echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      exit 1
    fi

    # GUIアプリをインストール
    brew install --cask wezterm || true
    brew install --cask google-chrome || true
    brew install --cask visual-studio-code || true
    brew install --cask raycast || true
    brew install --cask obsidian || true
    brew install --cask discord || true
    brew install --cask spotify || true
    brew install --cask 1password || true
  '';
}
