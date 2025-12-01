local function copilot_suggest(fn_name, visible_only)
  local ok, copilot = pcall(require, "copilot.suggestion")
  if not ok or not copilot then
    vim.notify("Copilot plugin not found", vim.log.levels.WARN)
    return false
  end

  if visible_only == nil then
    visible_only = true
  end
  if visible_only and not copilot.is_visible() then
    return false
  end

  copilot[fn_name]()
  return true
end

---@module 'blink.cmp'
---@type blink.cmp.Config
local blink_opts = {
  keymap = {
    preset = 'none',
    ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },
    ['<Tab>'] = {
      function() return copilot_suggest("accept") end,
      function() -- sidekick next edit suggestion
        return require("sidekick").nes_jump_or_apply()
      end,
      'snippet_forward',
      'fallback',
    },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
    ['<C-e>'] = {
      function() return copilot_suggest("accept_line") end,
      'fallback',
    },
    ['<Esc>'] = {
      function() return copilot_suggest("dismiss") end,
      'cancel',
      'fallback',
    },
    ['<C-s>'] = {
      function() return copilot_suggest("next", false) end,
    },
    ['<C-S-s>'] = {
      function() return copilot_suggest("prev", false) end,
    },
  },
  cmdline = {
    keymap = {
      preset = 'none',
      ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
      ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
      ['<Tab>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
      ['<S-Tab>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
      ['<Esc>'] = { 'cancel', 'fallback' },
    },
    sources = function()
      local type = vim.fn.getcmdtype()
      -- Search forward and backward
      if type == '/' or type == '?' then return { 'buffer' } end
      -- Command line
      if type == ':' then return { 'cmdline', 'buffer' } end
      -- Input (vim.fn.input())
      if type == '@' then return { 'buffer' } end
      return {}
    end,
    completion = {
      menu = { auto_show = false },
      ghost_text = { enabled = true },
    },
  },
  appearance = {
    nerd_font_variant = 'mono'
  },
  completion = {
    accept = {
      auto_brackets = {
        -- Whether to auto-insert brackets for functions
        enabled = false,
      }
    },
    documentation = {
      auto_show = true,
      window = { border = 'single' }
    },
    menu = {
      max_height = 15,
      border = 'single',
      draw = {
        columns = { { 'kind_icon' }, { 'label', 'label_description' }, { 'source_name' } },
      },
    },
  },
  signature = {
    enabled = true,
    window = {
      border = 'single',
      show_documentation = true,
    }
  },
  sources = {
    default = {
      'lsp',
      'path',
      'snippets',
      'buffer',
      'spell',
    },
    providers = {
      buffer = {
        opts = {
          -- Make the buffer source include all normal buffers.
          get_bufnrs = function()
            return vim.tbl_filter(function(bufnr)
              return vim.bo[bufnr].buftype == ''
            end, vim.api.nvim_list_bufs())
          end
        }
      },
      path = {
        opts = {
          -- Make the path source relative to the current working directory,
          -- instead of the buffer directory.
          get_cwd = function(_)
            return vim.fn.getcwd()
          end,
        },
      },
      spell = {
        name = 'Spell',
        module = 'blink-cmp-spell',
        score_offset = -10,
      },
    }
  },
  fuzzy = { implementation = "prefer_rust_with_warning" }
}

return {
  {
    'saghen/blink.cmp',
    event = {
      'InsertEnter',
      'CmdlineEnter',
    },
    version = '*',
    opts = blink_opts,
    opts_extend = { 'sources.default' },
    dependencies = {
      'rafamadriz/friendly-snippets',
      'ribru17/blink-cmp-spell',
    },
  },
}
