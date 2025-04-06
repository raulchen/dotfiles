---@module 'blink.cmp'
---@type blink.cmp.Config
local blink_opts = {
  keymap = {
    preset = 'default',
    ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
    ['<Tab>'] = {
      function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
          return true
        else
          return false
        end
      end, 'snippet_forward', 'fallback' },
  },
  cmdline = {
    keymap = {
      preset = 'cmdline',
      ['<C-p>'] = { 'show_and_insert', 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { 'show_and_insert', 'select_next', 'fallback_to_mappings' },
      ['<C-y>'] = { 'select_and_accept', 'fallback' },
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
    default = { 'lsp', 'path', 'snippets', 'buffer', 'spell' },
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
      }
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
