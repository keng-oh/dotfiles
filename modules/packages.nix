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
    nodejs_20
    python311
    php83

    # その他
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
  ];
}
