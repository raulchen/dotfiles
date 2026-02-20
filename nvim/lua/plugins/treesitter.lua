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

local function setup_treesitter_filetype_features(buf)
  -- Enable syntax highlighting from Neovim's built-in Treesitter runtime.
  vim.treesitter.start(buf)
  -- Use Treesitter-aware indentation for better structural indent behavior.
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  -- Compute folds from syntax tree structure.
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  -- Keep folds expanded by default; folding is available on demand.
  vim.opt_local.foldenable = false
end

local function treesitter_install_preset(wait)
  if vim.fn.executable("tree-sitter") ~= 1 then
    local registry = require("mason-registry")
    local pkg = registry.get_package("tree-sitter-cli")
    if not pkg:is_installed() then
      pkg:install()
      vim.notify("Treesitter: installing tree-sitter-cli via Mason", vim.log.levels.INFO)
    end
  end

  if #treesitter_filetypes > 0 then
    vim.notify("Treesitter: installing managed parsers", vim.log.levels.INFO)
    local install = require("nvim-treesitter").install(treesitter_filetypes, {
      summary = true,
      max_jobs = 4,
    })
    if wait then
      install:wait(300000)
    end
  end
end

local function setup_treesitter(_, _)
  local ts = require("nvim-treesitter")
  ts.setup({})
  vim.api.nvim_create_user_command("TSInstallPreset", function()
    treesitter_install_preset(false)
  end, { desc = "Install preset Treesitter parsers" })

  -- Tree-sitter based folding/highlighting.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = treesitter_filetypes,
    callback = function(args)
      setup_treesitter_filetype_features(args.buf)
    end,
  })
end

local function build_treesitter()
  vim.defer_fn(function()
    -- Delay this call because mason isn't available during the build callback.
    treesitter_install_preset(true)
    require("nvim-treesitter").update():wait(300000)
  end, 1000)
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

local treesitter_textobjects_opts = {
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

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = build_treesitter,
    config = setup_treesitter,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        opts = treesitter_textobjects_opts,
      },
      {
        "nvim-treesitter/nvim-treesitter-context",
        config = setup_treesitter_context,
      }
    },
  },
}
