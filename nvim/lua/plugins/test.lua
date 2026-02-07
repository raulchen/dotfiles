return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    keys = {
      { "<leader>t", "", desc = "+test" },
      { "<leader>tn", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run current file" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      { "<leader>to", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>ta", function() require("neotest").run.attach() end, desc = "Attach to running test" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last test" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop running tests" },
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            dap = { justMyCode = false },
            runner = "pytest",
            args = { "-v" },
          }),
        },
      })
      -- Center the attach float (neotest anchors it to cursor position by default)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neotest-attach",
        callback = function(args)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == args.buf then
              local cfg = vim.api.nvim_win_get_config(win)
              if cfg.relative ~= "" then
                cfg.row = math.floor((vim.o.lines - cfg.height) / 2)
                cfg.col = math.floor((vim.o.columns - cfg.width) / 2)
                vim.api.nvim_win_set_config(win, cfg)
              end
              break
            end
          end
        end,
      })
    end,
  },
}
