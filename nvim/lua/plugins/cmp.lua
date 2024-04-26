local function setup_cmp(_, _)
  local luasnip = require('luasnip')
  local cmp = require('cmp')
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
      ['<tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<s-tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = {
      { name = 'nvim_lsp' },
      { name = 'buffer' },
      { name = 'path' },
      { name = 'luasnip' },
      { name = 'spell' },
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
        'L3MON4D3/LuaSnip',
        dependencies = { 'rafamadriz/friendly-snippets' },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
      'saadparwaiz1/cmp_luasnip',
    }
  }
}
