{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };

  # Zellijの設定ファイルを管理
  home.file.".config/zellij/config.kdl" = {
    source = ../zellij/config.kdl;
    force = true;  # 既存ファイルを常に上書き
  };
}
