local treesitter_parsers = {
  "bash",
  "c",
  "cpp",
  "diff",
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

local function managed_treesitter_buffer(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  return lang ~= nil and vim.tbl_contains(treesitter_parsers, lang)
end

local function setup_treesitter_filetype_features(buf)
  if not managed_treesitter_buffer(buf) or not vim.treesitter.get_parser(buf) then
    return
  end
  -- Enable syntax highlighting from Neovim's built-in Treesitter runtime.
  vim.treesitter.start(buf)
  -- Use Treesitter-aware indentation for better structural indent behavior.
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  -- Compute folds from syntax tree structure.
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    -- Keep folds expanded by default; folding is available on demand.
    vim.opt_local.foldenable = false
  end)
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

  if #treesitter_parsers > 0 then
    vim.notify("Treesitter: installing managed parsers", vim.log.levels.INFO)
    local install = require("nvim-treesitter").install(treesitter_parsers, {
      summary = true,
      max_jobs = 4,
    })
    if wait then
      install:wait(300000)
    end
  end
end

local function setup_treesitter(_, _)
  vim.api.nvim_create_user_command("TSInstallPreset", function()
    treesitter_install_preset(false)
  end, { desc = "Install preset Treesitter parsers" })

  -- Enable features through FileType as recommended by nvim-treesitter.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterFeatures", { clear = true }),
    callback = function(args)
      setup_treesitter_filetype_features(args.buf)
    end,
  })

  -- FileType may have fired before plugin setup; attach existing buffers too.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    setup_treesitter_filetype_features(buf)
  end
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

local treesitter_move_mappings = {
  goto_next_start = {
    { key = "]k", query = { "@block.outer", "@conditional.outer", "@loop.outer" }, desc = "Next block start" },
    { key = "]f", query = "@function.outer", desc = "Next function start" },
    { key = "]a", query = "@parameter.inner", desc = "Next parameter start" },
    { key = "]]", query = "@class.outer", desc = "Next class start" },
  },
  goto_next_end = {
    { key = "]K", query = { "@block.outer", "@conditional.outer", "@loop.outer" }, desc = "Next block end" },
    { key = "]F", query = "@function.outer", desc = "Next function end" },
    { key = "]A", query = "@parameter.inner", desc = "Next parameter end" },
    { key = "][", query = "@class.outer", desc = "Next class end" },
  },
  goto_previous_start = {
    { key = "[k", query = { "@block.outer", "@conditional.outer", "@loop.outer" }, desc = "Previous block start" },
    { key = "[f", query = "@function.outer", desc = "Previous function start" },
    { key = "[a", query = "@parameter.inner", desc = "Previous parameter start" },
    { key = "[[", query = "@class.outer", desc = "Previous class start" },
  },
  goto_previous_end = {
    { key = "[K", query = { "@block.outer", "@conditional.outer", "@loop.outer" }, desc = "Previous block end" },
    { key = "[F", query = "@function.outer", desc = "Previous function end" },
    { key = "[A", query = "@parameter.inner", desc = "Previous parameter end" },
    { key = "[]", query = "@class.outer", desc = "Previous class end" },
  },
}

local function setup_treesitter_textobjects(_, opts)
  require("nvim-treesitter-textobjects").setup(opts)

  local function attach(buf)
    if not managed_treesitter_buffer(buf) then
      return
    end
    local move = require("nvim-treesitter-textobjects.move")
    for mode_fn, mappings in pairs(treesitter_move_mappings) do
      for _, mapping in ipairs(mappings) do
        vim.keymap.set({ "n", "x", "o" }, mapping.key, function()
          move[mode_fn](mapping.query, "textobjects")
        end, { buffer = buf, desc = mapping.desc })
      end
    end
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterTextobjects", { clear = true }),
    callback = function(args)
      attach(args.buf)
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = build_treesitter,
    config = setup_treesitter,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      move = {
        set_jumps = true,
      },
    },
    config = setup_treesitter_textobjects,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    config = setup_treesitter_context,
  },
}
