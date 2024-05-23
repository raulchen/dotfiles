return {
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function(_, _)
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",
          "clangd",
          "lua_ls",
          "pyright",
          "vimls",
        },

        require("mason-tool-installer").setup({
          ensure_installed = {
            "black",
            "debugpy",
            "isort",
          },
        }),
      })
    end,
  },
}
