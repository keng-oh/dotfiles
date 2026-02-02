local M = {}

function M.apply(config, wezterm, utils)
  config.color_scheme = 'Tokyo Night'

  config.font = wezterm.font_with_fallback {
    { family = 'JetBrains Mono', weight = 'Medium' },
    'SF Mono',
  }
  config.font_size = utils.is_darwin(wezterm) and 14.0 or 12.0

  if not utils.is_darwin(wezterm) then
    -- LinuxでのEGL系トラブル回避
    config.front_end = 'Software'
  end

  if utils.is_darwin(wezterm) then
    config.window_background_opacity = 0.6
    config.macos_window_background_blur = 20
    config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
  end

  config.window_close_confirmation = 'NeverPrompt'

  config.window_padding = {
    left = '1cell',
    right = '1cell',
    top = '0.5cell',
    bottom = 0,
  }

  config.initial_cols = 140
  config.initial_rows = 40
end

return M
