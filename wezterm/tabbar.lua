local M = {}

function M.apply(config, wezterm, utils)
  config.enable_tab_bar = true
  config.hide_tab_bar_if_only_one_tab = false
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = false
  config.tab_max_width = 32

  config.colors = {
    tab_bar = {
      background = '#1a1b26',
      active_tab = {
        bg_color = '#7aa2f7',
        fg_color = '#1a1b26',
        intensity = 'Bold',
      },
      inactive_tab = {
        bg_color = '#292e42',
        fg_color = '#545c7e',
      },
      inactive_tab_hover = {
        bg_color = '#3b4261',
        fg_color = '#c0caf5',
      },
      new_tab = {
        bg_color = '#1a1b26',
        fg_color = '#7aa2f7',
      },
    },
  }

  wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
    local pane = tab.active_pane
    local title = tab.tab_index + 1 .. ': ' .. pane.title

    if tab.is_active then
      return {
        { Foreground = { Color = '#1a1b26' } },
        { Background = { Color = '#7aa2f7' } },
        { Text = ' ' .. title .. ' ' },
      }
    end

    return {
      { Foreground = { Color = '#545c7e' } },
      { Background = { Color = '#292e42' } },
      { Text = ' ' .. title .. ' ' },
    }
  end)
end

return M
