local function setup_whichkey(_, _)
  local wk = require("which-key")
  ---@diagnostic disable-next-line: missing-fields
  wk.setup({
    preset = "modern",
  })
  wk.add({
    { "<leader>a", group = "ai" },
    { "<leader>b", group = "buffers" },
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "find" },
    { "<leader>fg", group = "git" },
    { "<leader>g", group = "git" },
    { "<leader>o", group = "octo", icon = { icon = " ", color = "blue" } },
    { "<leader>os", group = "search" },
    { "<leader>s", group = "sessions" },
    { "<leader>t", group = "tabs" },
    { "<leader>u", group = "ui" },
    { "<leader>w", group = "windows" },
  })
end

local flash_keys = {
  { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
  { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
}

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = setup_whichkey,
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "List buffer local keymaps",
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    keys = flash_keys,
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
}
