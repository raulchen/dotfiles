return {
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "lua_ls",
        "pyright",
        "vimls",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = true,
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "black",
        "debugpy",
        "ruff",
      },
    },
  },
  {
    "williamboman/mason.nvim",
    lazy = true,
    build = ":MasonUpdate", -- Update registry
    opts = {},
  },
}
