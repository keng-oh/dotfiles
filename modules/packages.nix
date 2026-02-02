{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.packages = with pkgs; [
    # CLI essentials
    git
    neovim
    gitui
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
    awscli2
    kubectl
    tree-sitter

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
  ]
  ++ lib.optionals isDarwin [
    colima
    docker-client
  ]
  ++ lib.optionals isLinux [
    docker
  ]
  ++ lib.optionals (pkgs ? github-copilot-cli) [
    github-copilot-cli
  ];
}
