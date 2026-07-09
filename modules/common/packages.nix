{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # CLI essentials
    git
    neovim
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    delta
    zoxide
    zellij

    # 開発ツール
    nodejs_22
    python311
    php83
    ruby
    go
    flutter

    # その他
    blueman
    wtype
    htop
    btop
    curl
    wget
    tree
    gh
    tldr
    lazygit
    lazydocker
    navi

    # シークレット管理
    doppler

    # AI
    claude-code
  ];
}
