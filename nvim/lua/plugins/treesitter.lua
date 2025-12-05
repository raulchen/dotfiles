local function setup_treesitter(_, _)
  local treesitter_filetypes = {
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
  }
  local opts = {
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = treesitter_filetypes,
  }
  opts.textobjects = {
    select = {
      enable = false,
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]k"] = { query = "@block.outer", desc = "Next block start" },
        ["]f"] = { query = "@function.outer", desc = "Next function start" },
        ["]a"] = { query = "@parameter.inner", desc = "Next parameter start" },
        ["]C"] = { query = "@class.outer", desc = "Next class start" },
      },
      goto_next_end = {
        ["]K"] = { query = "@block.outer", desc = "Next block end" },
        ["]F"] = { query = "@function.outer", desc = "Next function end" },
        ["]A"] = { query = "@parameter.inner", desc = "Next parameter end" },
      },
      goto_previous_start = {
        ["[k"] = { query = "@block.outer", desc = "Previous block start" },
        ["[f"] = { query = "@function.outer", desc = "Previous function start" },
        ["[a"] = { query = "@parameter.inner", desc = "Previous parameter start" },
        ["[C"] = { query = "@class.outer", desc = "Previous class start" },
      },
      goto_previous_end = {
        ["[K"] = { query = "@block.outer", desc = "Previous block end" },
        ["[F"] = { query = "@function.outer", desc = "Previous function end" },
        ["[A"] = { query = "@parameter.inner", desc = "Previous parameter end" },
      },
    },
  }
  require("nvim-treesitter.configs").setup(opts)
  -- Tree-sitter based folding.
  for _, filetype in ipairs(treesitter_filetypes) do
    vim.api.nvim_create_autocmd(
      'FileType',
      {
        pattern = filetype,
        command = 'setlocal foldmethod=expr foldexpr=nvim_treesitter#foldexpr() nofoldenable',
      }
    )
  end
end

local function setup_treesitter_context(_, _)
  require("treesitter-context").setup {
    multiline_threshold = 1,
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
    event = { "BufNew" },
    build = ":TSUpdate",
    config = setup_treesitter,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      {
        "nvim-treesitter/nvim-treesitter-context",
        config = setup_treesitter_context,
      }
    },
  },
}
