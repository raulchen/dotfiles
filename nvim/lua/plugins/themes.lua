local function setup_onedarkpro(_, _)
  local color = require("onedarkpro.helpers")
  local colors = {
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
    bg_light = color.lighten("#282A36", 5),
    bg_lighter = color.lighten("#282A36", 10),
  }

  local highlights = {
    Identifier = { fg = "${cyan}", extend = true },
    ["@variable"] = { link = "Identifier" },
    ["@variable.parameter"] = { link = "Identifier" },
    ["@variable.member"] = { link = "Identifier" },
    ["@odp.interpolation.python"] = { link = "Identifier" }, -- Variables in f-strings.
    ["@property"] = { fg = "${cyan}", extend = true },
    String = { fg = "${yellow}", extend = true },
    pythonString = { link = "String", extend = true },
    Character = { fg = "${yellow}", extend = true },
    ["@string"] = { fg = "${yellow}", extend = true },
    Constant = { fg = "${green}", extend = true },
    ["@constant"] = { fg = "${green}", extend = true },
    ["@constant.builtin"] = { link = "Constant" },
    SpellBad = { undercurl = true, sp = "${red}" },
    DiagnosticUnderlineError = { undercurl = true, sp = "${red}" },
    CursorLine = { bg = "${bg_lighter}", extend = true, },
    Pmenu = { bg = "${bg_light}", extend = true },
    PmenuSel = { bg = "${bg_lighter}", extend = true },
    NormalFloat = { bg = "${bg_light}", extend = true },
    FloatBorder = { bg = "${bg_light}", extend = true },
    Title = { fg = "${cyan}", extend = true },
    -- Plug-ins
    -- flash.nvim
    FlashLabel = { fg = "${black}", bg = "${yellow}", extend = true },
    -- which-key.nvim
    WhichKeyBorder = { bg = "${bg}", extend = true },
    WhichKeyNormal = { bg = "${bg}", extend = true },
  }

  local styles = {
    comments = "italic",
  }

  require("onedarkpro").setup({
    colors = colors,
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
