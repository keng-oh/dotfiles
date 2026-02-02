{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
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
      hms = "cd \"\${DOTFILES_DIR:-$HOME/repos/dotfiles}\" && make switch";
      hmu = "cd \"\${DOTFILES_DIR:-$HOME/repos/dotfiles}\" && make update";

      # cd系
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # その他便利系
      c = "clear";
      h = "history";
    }
    // lib.optionalAttrs isLinux {
      update = "sudo apt update && sudo apt upgrade -y";
      ports = "sudo netstat -tulanp";
    }
    // lib.optionalAttrs isDarwin {
      update = "softwareupdate -ia && brew update && brew upgrade";
      ports = "lsof -nP -iTCP -sTCP:LISTEN";
    };

    initExtra = ''
      # Homebrew（macOS）
      if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # ローカル環境変数（認証情報など）
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local

      # zoxide（cd代替）
      eval "$(zoxide init zsh)"
      alias cd="z"
    '';
  };
}
