local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- カラースキーム
config.color_scheme = 'Tokyo Night'

-- フォント設定
config.font = wezterm.font_with_fallback({
  'HackGen Console',
  'monospace',
})
config.font_size = 12.0

-- デフォルトシェルをzshに設定
local home = os.getenv('HOME')
config.default_prog = { home .. '/.nix-profile/bin/zsh', '-l' }

-- フロントエンド設定（EGLエラー対策）
config.front_end = "Software"

-- 透過設定
config.window_background_opacity = 0.7

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

-- Ctrl+T を Zellij に渡す
config.keys = {
  {
    key = 't',
    mods = 'CTRL',
    action = wezterm.action.SendKey { key = 't', mods = 'CTRL' },
  },
  {
    key = 'T',
    mods = 'CTRL',
    action = wezterm.action.SendKey { key = 't', mods = 'CTRL' },
  },
}

return config
