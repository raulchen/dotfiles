---------------------
-- Copilot.nvim
---------------------
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
-- Bind <C-F> to copilot-next.
vim.keymap.set('i', '<C-F>', "<Plug>(copilot-next)", {})

---------------------
-- which-key.nvim
---------------------
require("which-key").setup()

---------------------
-- gitsigns.nvim
---------------------
require("gitsigns").setup({
    signcolumn = false,
    numhl = true,
})
