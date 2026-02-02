local M = {}

function M.apply(config, wezterm, utils)
  local shell = os.getenv('SHELL')
  local home = os.getenv('HOME')
  local user = os.getenv('USER')

  local candidates = {}

  if shell ~= nil then
    table.insert(candidates, shell)
  end

  if utils.is_darwin(wezterm) then
    if user ~= nil then
      table.insert(candidates, '/etc/profiles/per-user/' .. user .. '/bin/zsh')
    end
    table.insert(candidates, '/run/current-system/sw/bin/zsh')
    table.insert(candidates, '/opt/homebrew/bin/zsh')
    table.insert(candidates, '/bin/zsh')
  else
    if home ~= nil then
      table.insert(candidates, home .. '/.nix-profile/bin/zsh')
    end
    table.insert(candidates, '/run/current-system/sw/bin/zsh')
    table.insert(candidates, '/bin/zsh')
  end

  local chosen = utils.first_existing(candidates)
  if chosen ~= nil then
    config.default_prog = { chosen, '-l' }
  end
end

return M
