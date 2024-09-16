local wezterm = require "wezterm"
local config = wezterm.config_builder()

-- Color scheme
config.color_scheme = "onedarkpro_snazzy"

-- Fonts
config.font = wezterm.font_with_fallback({
    "Fira Code",
})
config.font_size = 15
config.line_height = 1.1

-- Windows and tabs
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

return config
