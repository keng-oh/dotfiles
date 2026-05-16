{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    shellAliases = {
      # ls系
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      lt = "eza -T";

      # cat系
      cat = "bat";

      # git系
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      glog = "git log --oneline --graph --decorate";

      # nix/home-manager系
      hmu = "cd ~/repos/dotfiles && make update";

      # cd系
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # その他便利系
      c = "clear";
      h = "history";
      ports = "sudo netstat -tulanp";
    };

    initExtra = ''
      # zoxide（cd代替）
      eval "$(zoxide init zsh)"
      alias cd="z"
    '';
  };
}
