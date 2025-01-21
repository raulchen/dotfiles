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
      enable = true,
      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,
      keymaps = {
        ["ac"] = { query = "@class.outer", desc = "class outer" },
        ["ic"] = { query = "@class.inner", desc = "class inner" },
        ["af"] = { query = "@function.outer", desc = "function outer" },
        ["if"] = { query = "@function.inner", desc = "function inner" },
        ["i="] = { query = "@assignment.inner", desc = "assignment outer" },
        ["a="] = { query = "@assignment.outer", desc = "assignment inner" },
        ["a/"] = { query = "@comment.outer", desc = "comment outer" },
        ["i/"] = { query = "@comment.inner", desc = "comment inner" },
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]f"] = { query = "@function.outer", desc = "Next function start" },
        ["]c"] = { query = "@class.outer", desc = "Next class start" },
      },
      goto_next_end = {
        ["]F"] = { query = "@function.outer", desc = "Next function end" },
        ["]C"] = { query = "@class.outer", desc = "Next class end" },
      },
      goto_previous_start = {
        ["[f"] = { query = "@function.outer", desc = "Previous function start" },
        ["[c"] = { query = "@class.outer", desc = "Previous class start" },
      },
      goto_previous_end = {
        ["[F"] = { query = "@function.outer", desc = "Previous function end" },
        ["[C"] = { query = "@class.outer", desc = "Previous class end" },
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
    event = { "BufReadPre", "BufNewFile" },
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
