{ config, pkgs, ... }:

{
  # Starship
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # direnv（プロジェクトごとの環境管理）
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # fzf
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # bat
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };
}
