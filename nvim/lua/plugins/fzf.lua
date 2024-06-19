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

local function fzf_files()
  local opts = {}
  opts.no_header = true
  opts.fzf_opts = {
    ["--header"] = "<C-G> to disable .gitignore",
  }
  local fzf_lua = require('fzf-lua')
  local cwd = vim.uv.cwd()
  local buffer_dir = vim.fn.expand("%:p:h")
  local is_relative, relative_path = fzf_lua.path.is_relative_to(buffer_dir, cwd)

  if is_relative then
    -- If the buffer directory is in CWD,
    -- use CWD as the search directory.
    opts.cwd = cwd
    if relative_path ~= "." then
      -- Add <C-I> keymap to filter buffer directory.
      opts.keymap = {
        fzf = {
          ["ctrl-i"] = "change-query(" .. relative_path .. ")",
        }
      }
      opts.fzf_opts["--header"] = opts.fzf_opts["--header"] .. " / <C-I> to filter buffer dir"
    end
    fzf_lua.files(opts)
  else
    -- If the buffer directory is not in CWD,
    -- prompt for the directory to search in.
    vim.ui.input({
      prompt = "Find in directory: ",
      default = buffer_dir,
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

local function fzf_search(default_query, default_cwd)
  if default_query == nil then
    default_query = vim.fn.expand("<cword>")
  end
  if default_cwd == nil then
    default_cwd = vim.uv.cwd()
    local buffer_dir = vim.fn.expand("%:p:h")
    if buffer_dir:sub(1, 1) == "/" and buffer_dir:find(default_cwd, 1, true) ~= 1 then
      -- If the current buffer is a normal file, and is not in the
      -- current working directory, use the buffer directory.
      default_cwd = buffer_dir
    end
  end
  vim.ui.input({
      prompt = "Search query: ",
      default = default_query,
    },
    function(query)
      if not query then
        return
      end
      vim.ui.input({
          prompt = "Search in directory: ",
          default = default_cwd,
          completion = "dir",
        },
        function(cwd)
          if not cwd then
            return
          end
          require("fzf-lua").grep({
            search = query,
            cwd = cwd,
          })
        end
      )
    end
  )
end

local function fzf_oldfiles(opts)
  opts = opts or {
    cwd_only = true
  }
  local header
  if opts.cwd_only then
    header = "<Ctrl-G> to search global"
  else
    header = "<Ctrl-G> to search CWD only"
  end
  opts.fzf_opts = {
    ["--header"] = header,
  }
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
  local wk = require("which-key")
  wk.register({ ["<leader>fg"] = { name = "git" } })
end

local fzf_lua_keys = {
  { "<leader>fa", "<cmd>FzfLua builtin<cr>", desc = "Search all Fzf commands" },
  { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume last Fzf command" },
  -- Buffers and files.
  { "<leader>ff", fzf_files, desc = "Find files" },
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
    require("fzf-lua").grep({
      search = opts.args
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
