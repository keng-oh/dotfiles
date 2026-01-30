{ config, pkgs, ... }:

{
  # WezTermの設定ファイルのみ管理（インストールは別途Flatpakで行う）
  home.file.".config/wezterm/wezterm.lua".source = ../wezterm/wezterm.lua;
}
