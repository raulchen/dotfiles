return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {},
  },
}