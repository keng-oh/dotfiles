{ config, pkgs, lib, ... }:

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

  # Tailscale クライアント（公式インストールスクリプト経由、Linuxのみ）
  # Nixパッケージだとtailscaledのsystemd/root統合が上手くいかないため、
  # docker等と同様に公式スクリプトでシステムにインストールする
  home.activation.tailscaleSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ "$(uname)" = "Linux" ] && command -v sudo >/dev/null 2>&1; then
      if ! command -v tailscale >/dev/null 2>&1; then
        echo "==> Tailscale をインストール中"
        curl -fsSL https://tailscale.com/install.sh | sudo sh
      fi
      if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable --now tailscaled 2>/dev/null || true
      fi
    fi
  '';
}
