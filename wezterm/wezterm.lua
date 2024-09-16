-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'onedarkpro_onedark'

config.font = wezterm.font_with_fallback {
    'Fira Code',
}
config.line_height = 1.1
config.font_size = 15

config.hide_tab_bar_if_only_one_tab = true

-- and finally, return the configuration to wezterm
return config
