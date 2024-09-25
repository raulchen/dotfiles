local function setup_onedarkpro(_, _)
  local color = require("onedarkpro.helpers")
  local colors = {
    red = '#ff5c57',
    green = '#5af78e',
    yellow = '#f3f99d',
    blue = '#57c7ff',
    magenta = '#ff6ac1',
    cyan = '#9aedfe',
    purple = color.lighten("purple", 15, "onedark"),
    orange = color.brighten("orange", 15, "onedark"),
    comment = color.lighten("comment", 5, "onedark"),
    fg = color.brighten("fg", 5, "onedark"),
    light_red = color.lighten("red", 15, "onedark"),
    bg_highlight = color.lighten("bg", 10, "onedark"),
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
    CursorLine = { bg = "${bg_highlight}", extend = true, },
    PmenuSel = { bg = "${bg_highlight}", extend = true },
    -- Plug-ins
    -- flash.nvim
    FlashLabel = { fg = "#e0b5ec", bg = "${bg}", extend = true },
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
