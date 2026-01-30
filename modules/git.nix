{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "KENG";
    userEmail = "contact@ken-g.dev";
    delta.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
    };
  };
}
