local function setup_cmp(_, _)
  local luasnip = require('luasnip')
  local cmp = require('cmp')
  local kind_icons = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰇽",
    Variable = "󰂡",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
  }
  local source_display_names = {
    buffer = "Buffer",
    cmdline = "CMD",
    luasnip = "Snip",
    nvim_lsp = "LSP",
    path = "Path",
    spell = "Spell",
  }
  local format_opts = {
    format = function(entry, vim_item)
      vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
      vim_item.menu = string.format('[%s]', source_display_names[entry.source.name])
      return vim_item
    end
  }

  -- Define sources.
  local source_lsp = { name = 'nvim_lsp', priority = 10, max_item_count = 10 }
  local source_luasnip = { name = 'luasnip', priority = 10, max_item_count = 10 }
  local source_buffer = {
    name = 'buffer',
    priority = 5,
    max_item_count = 10,
    option = {
      -- Complete text from all buffers.
      get_bufnrs = function()
        return vim.api.nvim_list_bufs()
      end
    }
  }
  local source_path = { name = 'path', priority = 5, max_item_count = 15 }
  local source_spell = { name = 'luasnip', priority = 1, max_item_count = 10 }
  local source_cmdline = { name = 'cmdline', priority = 10, max_item_count = 15 }

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<CR>'] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
    }),
    sources = {
      source_lsp,
      source_luasnip,
      source_buffer,
      source_path,
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
  })

  -- Set up search completion.
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      source_buffer,
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
  })

  -- Set up command-line completion.
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      source_cmdline,
      source_path,
      source_buffer,
      source_spell,
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
  })

  cmp.setup.cmdline("@", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      source_path,
      source_buffer,
    },
  })
end

return {
  {
    'hrsh7th/nvim-cmp',
    event = {
      "InsertEnter",
      "CmdlineEnter",
    },
    config = setup_cmp,
    dependencies = {
      {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path",   -- source for file system paths
        'hrsh7th/cmp-cmdline',
        'f3fora/cmp-spell',
        {
          'L3MON4D3/LuaSnip',
          dependencies = { 'rafamadriz/friendly-snippets' },
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end,
        },
      },
      'saadparwaiz1/cmp_luasnip',
    }
  }
}
