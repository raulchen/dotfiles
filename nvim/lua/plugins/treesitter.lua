local function setup_treesitter(_, _)
  local opts = {
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "json",
      "lua",
      "luadoc",
      "luap",
      "markdown",
      "markdown_inline",
      "python",
      "vim",
      "vimdoc",
      "yaml",
    },
  }
  require("nvim-treesitter.configs").setup(opts)
  -- Tree-sitter based folding.
  vim.cmd [[
    set foldmethod=expr
    set foldexpr=nvim_treesitter#foldexpr()
    set nofoldenable
  ]]
end

local function setup_treesitter_context(_, _)
  require("treesitter-context").setup {
    multiline_threshold = 5,
  }
  vim.cmd([[
    hi TreesitterContextBottom gui=underline guisp=Grey
    hi TreesitterContextLineNumberBottom gui=underline guisp=Grey
  ]])
  vim.keymap.set("n", "[x", function()
    require("treesitter-context").go_to_context()
  end, { desc = "Go to context beginning" })
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = setup_treesitter,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-context",
        config = setup_treesitter_context,
      }
    },
  },
}
