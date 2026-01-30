{ config, pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = {}

      if wezterm.config_builder then
        config = wezterm.config_builder()
      end

      -- カラースキーム
      config.color_scheme = 'Tokyo Night'

      -- フォント設定
      config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
      config.font_size = 12.0

      -- デフォルトシェルをzshに設定
      config.default_prog = { 'zsh', '-l' }

      -- フロントエンド設定（EGLエラー対策）
      config.front_end = "WebGpu"
      config.webgpu_power_preference = "LowPower"

      -- ウィンドウ設定
      config.window_padding = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
      }

      -- タブバー設定
      config.use_fancy_tab_bar = false
      config.tab_bar_at_bottom = false
      config.hide_tab_bar_if_only_one_tab = true

      -- その他
      config.enable_scroll_bar = false
      config.window_close_confirmation = 'NeverPrompt'

      return config
    '';
  };
}
