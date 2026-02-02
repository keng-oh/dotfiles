{ config, pkgs, ... }:

{
  # GitHub Copilot CLI - MCP設定（環境変数から認証情報を読み込む想定）
  xdg.configFile."github-copilot/config.json".text = builtins.toJSON {
    mcpServers = {
      git = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-git" ];
      };
      github = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-github" ];
      };
      docker = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-docker" ];
      };
      fetch = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-fetch" ];
      };
      atlassian = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-atlassian" ];
      };
    };
  };

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
