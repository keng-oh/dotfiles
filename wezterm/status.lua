local M = {}

function M.apply(config, wezterm, utils)
  wezterm.on('update-right-status', function(window, pane)
    local cwd = pane:get_current_working_dir()
    local cwd_display = ''
    if cwd and cwd.file_path then
      local home = os.getenv('HOME')
      if home ~= nil and home ~= '' then
        cwd_display = cwd.file_path:gsub(home, '~')
      else
        cwd_display = cwd.file_path
      end
    end

    local time = wezterm.strftime '%H:%M'

    local bat = ''
    local ok, batteries = pcall(wezterm.battery_info)
    if ok and batteries ~= nil then
      for _, b in ipairs(batteries) do
        bat = string.format('%.0f%%', b.state_of_charge * 100)
        break
      end
    end

    local nf = wezterm.nerdfonts or {}
    local folder_icon = nf.md_folder or 'dir'
    local clock_icon = nf.md_clock or 'time'
    local battery_icon = nf.md_battery or 'bat'

    window:set_right_status(wezterm.format {
      { Foreground = { Color = '#545c7e' } },
      { Text = ' ' },
      { Foreground = { Color = '#7aa2f7' } },
      { Text = folder_icon .. ' ' },
      { Foreground = { Color = '#c0caf5' } },
      { Text = cwd_display },
      { Foreground = { Color = '#545c7e' } },
      { Text = '  ' },
      { Foreground = { Color = '#9ece6a' } },
      { Text = clock_icon .. ' ' },
      { Foreground = { Color = '#c0caf5' } },
      { Text = time },
      { Foreground = { Color = '#545c7e' } },
      { Text = '  ' },
      { Foreground = { Color = '#e0af68' } },
      { Text = battery_icon .. ' ' },
      { Foreground = { Color = '#c0caf5' } },
      { Text = bat },
      { Text = '  ' },
    })
  end)
end

return M
