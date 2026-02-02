local M = {}

function M.apply(config, wezterm, utils)
  -- カーソル/スクロールなど、OSに依存しない基本挙動
  config.cursor_blink_rate = 500
  config.default_cursor_style = 'BlinkingBar'

  config.scrollback_lines = 10000
  config.enable_scroll_bar = false

  -- macOSはCommandキー、LinuxはCtrlキーを「同じ操作感」のモディファイアとして使う
  local MOD = utils.is_darwin(wezterm) and 'CMD' or 'CTRL'
  local MOD_SHIFT = MOD .. '|SHIFT'

  -- キーバインド（タブ/ペイン操作を中心に統一）
  config.keys = {
    -- タブ操作
    { key = 't', mods = MOD, action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = MOD, action = wezterm.action.CloseCurrentTab { confirm = false } },
    { key = '[', mods = MOD, action = wezterm.action.ActivateTabRelative(-1) },
    { key = ']', mods = MOD, action = wezterm.action.ActivateTabRelative(1) },
    { key = '1', mods = MOD, action = wezterm.action.ActivateTab(0) },
    { key = '2', mods = MOD, action = wezterm.action.ActivateTab(1) },
    { key = '3', mods = MOD, action = wezterm.action.ActivateTab(2) },
    { key = '4', mods = MOD, action = wezterm.action.ActivateTab(3) },
    { key = '5', mods = MOD, action = wezterm.action.ActivateTab(4) },

    -- ペイン分割
    { key = 'd', mods = MOD, action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = MOD_SHIFT, action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'w', mods = MOD_SHIFT, action = wezterm.action.CloseCurrentPane { confirm = false } },

    -- ペイン移動
    { key = 'h', mods = MOD, action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 'l', mods = MOD, action = wezterm.action.ActivatePaneDirection 'Right' },
    { key = 'k', mods = MOD, action = wezterm.action.ActivatePaneDirection 'Up' },
    { key = 'j', mods = MOD, action = wezterm.action.ActivatePaneDirection 'Down' },

    -- ペインリサイズ
    { key = 'LeftArrow', mods = MOD_SHIFT, action = wezterm.action.AdjustPaneSize { 'Left', 5 } },
    { key = 'RightArrow', mods = MOD_SHIFT, action = wezterm.action.AdjustPaneSize { 'Right', 5 } },
    { key = 'UpArrow', mods = MOD_SHIFT, action = wezterm.action.AdjustPaneSize { 'Up', 5 } },
    { key = 'DownArrow', mods = MOD_SHIFT, action = wezterm.action.AdjustPaneSize { 'Down', 5 } },

    -- その他
    { key = 'f', mods = MOD, action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
    { key = 'k', mods = MOD_SHIFT, action = wezterm.action.ClearScrollback 'ScrollbackAndViewport' },
    { key = 'p', mods = MOD_SHIFT, action = wezterm.action.ActivateCommandPalette },
  }

  -- マウス操作（macOS/Linuxとも、MOD + クリックでリンクを開く）
  config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = MOD,
      action = wezterm.action.OpenLinkAtMouseCursor,
    },
  }
end

return M
