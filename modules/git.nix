{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "KENG";
      user.email = "contact@ken-g.dev";
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
