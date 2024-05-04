local opts = {
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

local function fzf_search(defaul_query, default_cwd)
  if defaul_query == nil then
    defaul_query = vim.fn.expand("<cword>")
  end
  if default_cwd == nil then
    default_cwd = vim.loop.cwd()
    local buffer_dir = vim.fn.expand("%:p:h")
    if not default_cwd or buffer_dir:find(default_cwd, 1, true) ~= 1 then
      -- If the current buffer is not in the current working directory,
      -- use the buffer directory.
      default_cwd = buffer_dir
    end
  end
  vim.ui.input({
      prompt = "Search query: ",
      default = defaul_query,
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

local function setup_fzf_lua()
  local fzf_lua = require("fzf-lua")
  fzf_lua.setup(opts)

  local function keymap(lhs, rhs, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end

  keymap("<leader>fa", fzf_lua.builtin, "Search all Fzf commands")
  keymap("<leader>fr", fzf_lua.resume, "Resume last Fzf command")
  -- Buffers and files.
  keymap("<leader>ff", fzf_lua.files, "Find files")
  keymap("<leader>fd", function() fzf_lua.files({ cwd = vim.fn.expand("%:p:h") }) end, "Find files in current directory")
  keymap("<leader>fh", fzf_lua.oldfiles, "Find file history")
  keymap("<leader>fb", fzf_lua.buffers, "Find buffers")
  -- Search
  keymap("<leader>fs", fzf_search, "Searh")
  keymap("<leader>fs", fzf_lua.grep_visual, "Searh visual selection", "v")
  -- Tags
  keymap("<leader>ft", fzf_lua.btags, "Find tags in current buffer")
  -- Misc
  keymap("<leader>f:", fzf_lua.command_history, "Find command history")
  keymap("<leader>f/", fzf_lua.search_history, "Find search history")
  keymap("<leader>f\"", fzf_lua.registers, "Find registers")
  keymap("<leader>f'", fzf_lua.marks, "Find marks")
  keymap("<leader>fj", fzf_lua.jumps, "Find jump list")

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function(ev)
      vim.keymap.set(
        "n",
        "<leader>ff",
        "<cmd>FzfLua quickfix<cr>",
        { buffer = ev.buf, desc = "Search quickfix" }
      )
    end,
  })
end

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = setup_fzf_lua,
}
