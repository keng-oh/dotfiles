local wezterm = require 'wezterm'

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local utils = require 'utils'

require('shell').apply(config, wezterm, utils)
require('appearance').apply(config, wezterm, utils)
require('tabbar').apply(config, wezterm, utils)
require('status').apply(config, wezterm, utils)
require('keys').apply(config, wezterm, utils)

return config
