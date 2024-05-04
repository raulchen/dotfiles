local opts = {
  'fzf-native',
  winopts = {
    height = 0.9,
    width = 0.9,
    preview = {
      vertical = 'down:50%',
      horizontal = 'right:50%',
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

local function setup_fzf_lua()
  local fzf_lua = require('fzf-lua')
  fzf_lua.setup(opts)

  local function keymap(lhs, rhs, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end

  keymap('<leader>fa', fzf_lua.builtin, 'All Fzf commands')
  -- Buffers and files.
  keymap('<leader>ff', fzf_lua.files, 'Find files')
  keymap('<leader>fd', function() fzf_lua.files({ cwd = vim.fn.expand('%:p:h') }) end, 'Find files in current directory')
  keymap('<leader>fh', fzf_lua.oldfiles, 'Find file history')
  keymap('<leader>fb', fzf_lua.buffers, 'Find buffers')
  -- Search
  keymap('<leader>fs', fzf_lua.grep_cword, 'Searh word under cursor')
  keymap('<leader>fs', fzf_lua.grep_visual, 'Searh visual selection', 'v')
  -- Tags
  keymap('<leader>ft', fzf_lua.btags, 'Find tags in current buffer')
  -- Misc
  keymap('<leader>f:', fzf_lua.command_history, 'Find command history')
  keymap('<leader>f/', fzf_lua.search_history, 'Find search history')
  keymap('<leader>f"', fzf_lua.registers, 'Find registers')
  keymap('<leader>f\'', fzf_lua.marks, 'Find marks')
  keymap('<leader>fj', fzf_lua.jumps, 'Find jump locations')
end

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = setup_fzf_lua,
}
