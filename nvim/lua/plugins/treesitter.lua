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
        ["aa"] = { query = "@parameter.outer", desc = "parameter outer" },
        ["ia"] = { query = "@parameter.inner", desc = "parameter inner" },
        ["al"] = { query = "@loop.outer", desc = "loop outer" },
        ["il"] = { query = "@loop.inner", desc = "loop inner" },
        ["ad"] = { query = "@conditional.outer", desc = "condition outer" },
        ["id"] = { query = "@conditional.inner", desc = "condition inner" },
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
        ["]a"] = { query = "@parameter.outer", desc = "Next parameter start" },
      },
      goto_next_end = {
        ["]F"] = { query = "@function.outer", desc = "Next function end" },
        ["]C"] = { query = "@class.outer", desc = "Next class end" },
      },
      goto_previous_start = {
        ["[f"] = { query = "@function.outer", desc = "Previous function start" },
        ["[c"] = { query = "@class.outer", desc = "Previous class start" },
        ["[a"] = { query = "@parameter.outer", desc = "Previous parameter start" },
      },
      goto_previous_end = {
        ["[F"] = { query = "@function.outer", desc = "Previous function end" },
        ["[C"] = { query = "@class.outer", desc = "Previous class end" },
      },
      -- Below will go to either the start or the end, whichever is closer.
      goto_next = {
        ["]d"] = { query = "@conditional.outer", desc = "Next condition start/end" },
        ["]l"] = { query = "@loop.outer", desc = "Next loop start/end" },
      },
      goto_previous = {
        ["[d"] = { query = "@conditional.outer", desc = "Previous condition start/end" },
        ["[l"] = { query = "@loop.outer", desc = "Previous loop start/end" },
      }
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
      "nvim-treesitter/nvim-treesitter-textobjects",
      {
        "nvim-treesitter/nvim-treesitter-context",
        config = setup_treesitter_context,
      }
    },
  },
}
