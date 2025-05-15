local function setup_mason_tool_installer()
  require("mason-tool-installer").setup({
    ensure_installed = {
      { "black", version = "22.10.0" },
      "ruff",
      "debugpy",
    },
  })
  -- Manually call the check_install function,
  -- because mason-tool-installer doesn't automatically install packages
  -- when it's lazily loaded.
  require("mason-tool-installer").check_install(false, false)
end

return {
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = true,
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "lua_ls",
        "basedpyright",
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
    config = setup_mason_tool_installer,
  },
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate", -- Update registry
    opts = {},
  },
}
