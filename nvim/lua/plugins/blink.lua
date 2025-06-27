---@module 'blink.cmp'
---@type blink.cmp.Config
local blink_opts = {
  keymap = {
    preset = 'default',
    ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
    ['<CR>'] = { 'accept', 'fallback' },
    ['<Tab>'] = {
      function()
        local copilot_accept = require("plugins.ai").copilot_accept
        if not copilot_accept then return false end
        return copilot_accept()
      end,
      'snippet_forward',
      'fallback',
    },
    ['<C-y>'] = {
      function()
        local copilot_accept = require("plugins.ai").copilot_accept
        if not copilot_accept then return false end
        return copilot_accept()
      end,
      'select_and_accept',
      'fallback',
    },
  },
  cmdline = {
    keymap = {
      preset = 'cmdline',
      ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
      ['<C-y>'] = { 'select_and_accept', 'fallback' },
      ['<C-e>'] = { 'cancel', 'fallback_to_mappings' },
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
      "avante_commands",
      "avante_mentions",
      "avante_files",
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
      avante_commands = {
        name = "avante_commands",
        module = "blink.compat.source",
        score_offset = 90,
        opts = {},
      },
      avante_files = {
        name = "avante_files",
        module = "blink.compat.source",
        score_offset = 100,
        opts = {},
      },
      avante_mentions = {
        name = "avante_mentions",
        module = "blink.compat.source",
        score_offset = 1000,
        opts = {},
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
      {
        'saghen/blink.compat',
        version = '*',
        lazy = true,
        opts = {},
        config = function()
          -- monkeypatch cmp.ConfirmBehavior for Avante
          require("cmp").ConfirmBehavior = {
            Insert = "insert",
            Replace = "replace",
          }
        end,
      },
    },
  },
}
