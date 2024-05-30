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
    nvim_lsp = "LSP",
    buffer = "Buffer",
    path = "Path",
    luasnip = "LuaSnip",
    spell = "Spell",
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
      {
        name = 'buffer',
        option = {
          -- Complete text from all buffers.
          get_bufnrs = function()
            return vim.api.nvim_list_bufs()
          end
        }
      },
      { name = 'path' },
      { name = 'luasnip' },
      { name = 'spell' },
    },
    ---@diagnostic disable-next-line
    formatting = {
      format = function(entry, vim_item)
        vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
        vim_item.menu = string.format('[%s]', source_display_names[entry.source.name])
        return vim_item
      end
    },
  })
end

return {
  {
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    config = setup_cmp,
    dependencies = {
      {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path",   -- source for file system paths
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
