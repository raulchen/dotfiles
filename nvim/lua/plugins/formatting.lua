return {
  "stevearc/conform.nvim",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format file or range",
    },
    {
      "<leader>cF",
      function()
        if vim.g.enable_auto_format then
          vim.g.enable_auto_format = false
          print("Auto-format off")
        else
          vim.g.enable_auto_format = true
          print("Auto-format on")
        end
      end,
      mode = "",
      desc = "Toogle auto-format",
    }
  },
  opts = {
    formatters_by_ft = {
      python = { "isort", "black" },
    },
    ---@diagnostic disable-next-line
    format_on_save = function(bufnr)
      if not vim.g.enable_auto_format then
        return
      end
      return { timeout_ms = 1000, lsp_fallback = true }
    end,
  },
  init = function()
    vim.g.enable_auto_format = true
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
