local function setup_onedarkpro(_, _)
  local color = require("onedarkpro.helpers")
  local dark_colors = {
    black = '#000000',
    white = '#f1f1f0',
    gray = '#686868',
    red = '#ff5c57',
    green = '#5af78e',
    yellow = '#f3f99d',
    blue = '#57c7ff',
    purple = color.lighten('#ff6ac1', 15),
    cyan = '#9aedfe',
    orange = color.brighten("orange", 15, "onedark"),
    bg = '#282A36',
    fg = color.brighten("fg", 5, "onedark"),
    comment = color.lighten("comment", 5, "onedark"),
    cursorline = color.lighten("#282A36", 10),
    float_bg = '#323540',
  }

  local light_colors = {
    bg = color.darken("bg", 5, "onelight"),
  }

  -- highlights only for the dark theme
  local dark_highlights = {
    Identifier = { fg = "${cyan}" },
    ["@property"] = { fg = "${cyan}" },
    String = { fg = "${yellow}" },
    Character = { fg = "${yellow}" },
    ["@string"] = { fg = "${yellow}" },
    Constant = { fg = "${green}" },
    ["@constant"] = { fg = "${green}" },
  }

  for _, highlight in pairs(dark_highlights) do
    for k, v in pairs(highlight) do
      ---@diagnostic disable-next-line: assign-type-mismatch
      highlight[k] = {
        onedark = v,
      }
    end
  end

  -- common highlights for both dark and light themes
  local highlights = {
    ["@variable"] = { link = "Identifier" },
    ["@variable.parameter"] = { link = "Identifier" },
    ["@variable.member"] = { link = "Identifier" },
    ["@odp.interpolation.python"] = { link = "Identifier" }, -- Variables in f-strings.
    ["@constant.builtin"] = { link = "Constant" },
    pythonString = { link = "String" },
    SpellBad = { undercurl = true, sp = "${red}" },
    DiagnosticUnderlineError = { undercurl = true, sp = "${red}" },
    Title = { fg = "${cyan}", extend = true },
    -- Plug-ins
    -- which-key.nvim
    WhichKeyBorder = { bg = "${bg}", extend = true },
    WhichKeyNormal = { bg = "${bg}", extend = true },
    -- snacks.nvim
    SnacksPicker = { bg = "${bg}", extend = true },
    SnacksPickerBorder = { bg = "${bg}", extend = true },
  }

  for k, v in pairs(dark_highlights) do
    highlights[k] = v
  end

  local styles = {
    comments = "italic",
  }

  require("onedarkpro").setup({
    colors = {
      onedark = dark_colors,
      onelight = light_colors,
    },
    highlights = highlights,
    styles = styles,
    options = {
      cursorline = true,
      highlight_inactive_windows = false,
      lualine_transparency = true,
    }
  })
  vim.cmd [[colorscheme onedark]]
end

return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    config = setup_onedarkpro,
  },
}
