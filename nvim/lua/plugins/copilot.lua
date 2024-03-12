return {
  "github/copilot.vim",
  config = function()
    -- Only enable Copilot for certain filetypes.
    vim.g.copilot_filetypes = {
      ["*"] = false,
      ["c"] = true,
      ["cpp"] = true,
      ["java"] = true,
      ["python"] = true,
      ["lua"] = true,
      ["rust"] = true,
      ["go"] = true,
      ["vim"] = true,
      ["sh"] = true,
      ["zsh"] = true,
      ["xml"] = true,
      ["gitcommit"] = true,
    }
    vim.keymap.set('i', '<C-A><C-N>', "<Plug>(copilot-next)", {desc = "Copliot next"})
    vim.keymap.set('i', '<C-A><C-P>', "<Plug>(copilot-prev)", {desc = "Copliot prev"})
    vim.keymap.set('i', '<C-A><C-A>', "<Plug>(copilot-suggest)", {desc = "Copliot suggest"})
    vim.keymap.set('i', '<C-A><C-Y>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      desc = "Copliot accept",
    })
    vim.keymap.set('i', '<C-A><C-W>', '<Plug>(copilot-accept-word)', {desc = "Copliot accept word"})
    vim.keymap.set('i', '<C-A><C-L>', '<Plug>(copilot-accept-line)', {desc = "Copliot accept line"})
  end
}
