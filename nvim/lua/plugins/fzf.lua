local fzf_lua_opts = {
  "fzf-native",
  winopts = {
    height = 0.9,
    width = 0.9,
    preview = {
      vertical = "down:50%",
      horizontal = "right:50%",
      flip_columns = 140,
    },
  },
  keymap = {
    fzf = {
      ["ctrl-q"] = "toggle-all",
      ["ctrl-u"] = "half-page-up",
      ["ctrl-d"] = "half-page-down",
      ["ctrl-k"] = "preview-up",
      ["ctrl-j"] = "preview-down",
      ["ctrl-/"] = "toggle-preview",
    },
  },
}

local function is_relative_to(buffer_dir, cwd)
  local fzf_lua = require('fzf-lua')
  if not fzf_lua.path.is_absolute(buffer_dir) then
    -- If buffer directory is not absolute (e.g., plugin-specific paths),
    -- treat it as CWD.
    return true, "."
  end
  return fzf_lua.path.is_relative_to(buffer_dir, cwd)
end

local function format_header_str(bind, text, cur_header)
  local utils = require("fzf-lua.utils")
  if cur_header then
    cur_header = cur_header .. ", "
  else
    cur_header = ":: "
  end
  local bind_hl = not utils.is_hl_cleared("FzfLuaHeaderBind") and "FzfLuaHeaderBind" or nil
  local bind_str = utils.ansi_from_hl(bind_hl, bind)

  local text_hl = not utils.is_hl_cleared("FzfLuaHeaderText") and "FzfLuaHeaderText" or nil
  local text_str = utils.ansi_from_hl(text_hl, text)
  return cur_header .. string.format("<%s> to %s", bind_str, text_str)
end

local function oil_current_dir()
  local exists, oil = pcall(require, "oil")
  if not exists then
    return nil
  end
  return oil.get_current_dir()
end

local function fzf_files(opts)
  opts = opts or {}
  opts.header = format_header_str("ctrl-g", "toggle gitignore")

  -- Support switching to search directories.
  local search_dirs_bind = "ctrl-r"
  if opts.search_dirs then
    opts.fd_opts = [[--color=never --type d --hidden --follow --exclude .git]]
    opts.find_opts = [[-type d -not -path '*/\.git/*' -printf '%P\n']]
    opts.header = format_header_str(search_dirs_bind, "search files", opts.header)
  else
    opts.header = format_header_str(search_dirs_bind, "search dirs", opts.header)
  end
  opts.actions = {
    [search_dirs_bind] = function(_, o)
      local new_opts = {
        cwd = o.cwd,
        search_dirs = not o.search_dirs,
      }
      fzf_files(new_opts)
    end
  }

  ---@diagnostic disable-next-line: undefined-field
  local cwd = opts.cwd or oil_current_dir() or vim.uv.cwd()
  local buffer_dir = vim.fn.expand("%:p:h")
  local is_relative, relative_path = is_relative_to(buffer_dir, cwd)

  local fzf_lua = require('fzf-lua')
  if is_relative then
    -- If the buffer directory is in CWD,
    -- use CWD as the search directory.
    opts.cwd = cwd
    if relative_path ~= "." then
      -- Add <C-I> keymap to filter buffer directory.
      opts.keymap = {
        fzf = {
          ["ctrl-i"] = "change-query(" .. relative_path .. "/)",
        }
      }
      opts.header = format_header_str("ctrl-i", "filter buffer dir", opts.header)
    end
    fzf_lua.files(opts)
  else
    -- If the buffer directory is not in CWD,
    -- prompt for the directory to search in.
    vim.ui.input({
      prompt = "Find in directory: ",
      default = buffer_dir .. "/",
      completion = "dir",
    }, function(dir)
      if not dir then
        return
      end
      opts.cwd = dir
      fzf_lua.files(opts)
    end)
  end
end

local function fzf_search(opts)
  opts = opts or {}

  -- If search query is not provided, prompt for it.
  if opts.search == nil then
    local default_query = vim.fn.expand("<cword>")
    vim.ui.input({ prompt = "Search query: ", default = default_query, },
      function(query)
        if not query then return end
        opts.search = query
        fzf_search(opts)
      end)
    return
  end

  -- If cwd is not provided, prompt for it.
  if opts.cwd == nil then
    assert(opts.cwd == nil)
    ---@diagnostic disable-next-line: undefined-field
    local default_cwd = oil_current_dir() or vim.uv.cwd()
    local buffer_dir = vim.fn.expand("%:p:h")
    local is_relative, _ = is_relative_to(buffer_dir, default_cwd)
    if not is_relative then
      -- If the buffer directory is not in CWD,
      -- use buffer directory as the search directory.
      default_cwd = buffer_dir
    end
    if default_cwd:sub(-1) ~= "/" then
      default_cwd = default_cwd .. "/"
    end
    vim.ui.input({ prompt = "Search in directory: ", default = default_cwd, completion = "dir", },
      function(cwd)
        if not cwd then return end
        opts.cwd = cwd
        fzf_search(opts)
      end)
    return
  end

  assert(opts.search ~= nil)
  assert(opts.cwd ~= nil)
  require("fzf-lua").grep(opts)
end

local function fzf_oldfiles(opts)
  opts = opts or {
    cwd_only = true
  }
  if opts.cwd_only then
    opts.header = format_header_str("ctrl-g", "search global")
  else
    opts.header = format_header_str("ctrl-g", "search CWD")
  end
  opts.actions = {
    ["ctrl-g"] = {
      fn = function(_, o)
        local new_opts = {
          cwd = o.cwd,
          cwd_only = not o.cwd_only,
          resume = true,
        }
        fzf_oldfiles(new_opts)
      end,
    }
  }
  require("fzf-lua").oldfiles(opts)
end

local function setup_fzf_lua()
  local fzf_lua = require("fzf-lua")
  fzf_lua.setup(fzf_lua_opts)
  fzf_lua.register_ui_select()
end

local fzf_lua_keys = {
  { "<leader>fa", "<cmd>FzfLua builtin<cr>", desc = "Search all Fzf commands" },
  { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume last Fzf command" },
  -- Buffers and files.
  { "<leader>ff", fzf_files, desc = "Find files" },
  { "<leader>fF", function() fzf_files({ search_dirs = true }) end, desc = "Find directories" },
  { "<leader>fh", fzf_oldfiles, desc = "Find CWD file history" },
  { "<leader>fH", function() fzf_oldfiles({ cwd_only = false }) end, desc = "Find global file history" },
  { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find buffers" },
  -- Search
  { "<leader>fs", fzf_search, desc = "Search" },
  { "<leader>fs", "<cmd>lua require('fzf-lua').grep_visual()<cr>", desc = "Searh visual selection", mode = "v" },
  -- Tags
  { "<leader>ft", "<cmd>FzfLua btags<cr>", desc = "Find tags in current buffer" },
  -- Misc
  { "<leader>f:", "<cmd>FzfLua command_history<cr>", desc = "Find command history" },
  { "<leader>f/", "<cmd>FzfLua search_history<cr>", desc = "Find search history" },
  { "<leader>f\"", "<cmd>FzfLua registers<cr>", desc = "Find registers" },
  { "<leader>f'", "<cmd>FzfLua marks<cr>", desc = "Find marks" },
  { "<leader>fj", "<cmd>FzfLua jumps<cr>", desc = "Find jump list" },
  -- git
  { "<leader>fga", "<cmd>FzfLua git_stash<cr>", desc = "Git stash" },
  { "<leader>fgb", "<cmd>FzfLua git_branches<cr>", desc = "Git branches" },
  { "<leader>fgf", "<cmd>FzfLua git_files<cr>", desc = "Git files" },
  { "<leader>fgh", "<cmd>FzfLua git_bcommits<cr>", desc = "Git file history" },
  { "<leader>fgl", "<cmd>FzfLua git_commits<cr>", desc = "Git log" },
  { "<leader>fgs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
  { "<leader>fgt", "<cmd>FzfLua git_tags<cr>", desc = "Git tags" },
  --  quickfix
  { "<leader>ff", "<cmd>FzfLua quickfix<cr>", desc = "Search quickfix", ft = "qf" },
}

vim.api.nvim_create_user_command(
  "Rg",
  function(opts)
    fzf_search({
      search = opts.args,
    })
  end,
  { nargs = "?" }
)

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = fzf_lua_keys,
  cmd = { "FzfLua", },
  config = setup_fzf_lua,
  -- Exporting following functions for other modules to use.
  fzf_files = fzf_files,
  fzf_oldfiles = fzf_oldfiles,
}
