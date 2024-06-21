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
  local source_all_buffers = {
    name = 'buffer',
    option = {
      -- Complete text from all buffers.
      get_bufnrs = function()
        return vim.api.nvim_list_bufs()
      end
    }
  }
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
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      source_all_buffers,
      { name = 'path' },
      { name = 'spell' },
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
  })

  -- Set up search completion.
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      source_all_buffers,
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
  })

  -- Set up command-line completion.
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'cmdline' },
      { name = 'path' },
      source_all_buffers,
      { name = 'spell' },
    },
    ---@diagnostic disable-next-line
    formatting = format_opts,
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
