{ config, pkgs, ... }:

{
  imports = [
    ./modules/common/packages.nix
    ./modules/common/git.nix
    ./modules/common/ssh.nix
    ./modules/common/zsh.nix
    ./modules/common/zellij.nix
    ./modules/common/wezterm.nix
    ./modules/common/cli-tools.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
