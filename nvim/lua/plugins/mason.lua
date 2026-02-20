local mason_tool_installer = {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  cmd = {
    "MasonToolsInstall",
    "MasonToolsInstallSync",
    "MasonToolsUpdate",
    "MasonToolsUpdateSync",
    "MasonToolsClean",
  },
  dependencies = {
    "mason-org/mason.nvim",
    "mason-org/mason-lspconfig.nvim",
  },
  opts = {
    ensure_installed = {
      "bashls",
      "clangd",
      "lua_ls",
      "basedpyright",
      "vimls",
      "black",
      "ruff",
      "debugpy",
      "tree-sitter-cli",
    },
    run_on_start = false,
  },
}

local mason = {
  "mason-org/mason.nvim",
  cmd = "Mason",
  build = ":MasonUpdate", -- Update registry
  opts = {
    PATH = "append", -- Lower priority than system PATH
  },
}

local mason_lspconfig = {
  "mason-org/mason-lspconfig.nvim",
  lazy = true,
  dependencies = {
    "mason-org/mason.nvim",
  },
  opts = {
    automatic_enable = false,
  },
}

if os.getenv("NVIM_DEV") == "0" then
  return {}
end

return {
  mason_tool_installer,
  mason,
  mason_lspconfig,
}
