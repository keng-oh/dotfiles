{ config, pkgs, ... }:

{
  # WezTermの設定（分割Luaをrequireで読み込む）
  # NOTE: ~/.config/wezterm が既にディレクトリとして存在するケースがあるため、
  # ディレクトリ丸ごとの置き換えではなく、ファイル単位で配布する。
  xdg.configFile."wezterm/wezterm.lua".source = ../wezterm/wezterm.lua;
  xdg.configFile."wezterm/utils.lua".source = ../wezterm/utils.lua;
  xdg.configFile."wezterm/shell.lua".source = ../wezterm/shell.lua;
  xdg.configFile."wezterm/appearance.lua".source = ../wezterm/appearance.lua;
  xdg.configFile."wezterm/tabbar.lua".source = ../wezterm/tabbar.lua;
  xdg.configFile."wezterm/status.lua".source = ../wezterm/status.lua;
  xdg.configFile."wezterm/keys.lua".source = ../wezterm/keys.lua;
}
