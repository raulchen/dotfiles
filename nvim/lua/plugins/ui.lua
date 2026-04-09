local dot_repeatable_keymap = require("core.utils").dot_repeatable_keymap

local lualine_opts = {
  options = {
    section_separators = "",
    component_separators = "|",
    globalstatus = true,
  },
  sections = {
    lualine_c = {
      {
        "filename",
        path = 1,
      },
      {
        "navic",
      },
    },
    lualine_x = {
      {
        -- showcmd
        "%S",
        color = { fg = "orange" },
      },
      {
        -- Show macro recording message
        function()
          ---@diagnostic disable-next-line
          local mode = require("noice").api.statusline.mode.get()
          return mode:sub(#"recording " + 1)
        end,
        cond = function()
          local exist, noice = pcall(require, "noice")
          if not exist then
            return false
          end
          ---@diagnostic disable-next-line
          local mode = noice.api.statusline.mode.get()
          return mode ~= nil and mode:find("recording") ~= nil
        end,
        color = { fg = "orange" },
      },
      {
        -- Show search count
        function()
          ---@diagnostic disable-next-line
          local search = require("noice").api.status.search.get()
          -- replace multiple spaces with one space
          return search:gsub("%s+", " ")
        end,
        cond = function()
          local exist, noice = pcall(require, "noice")
          ---@diagnostic disable-next-line
          return exist and noice.api.status.search.has()
        end,
        color = { fg = "orange" },
      },
      {
        function()
          return " "
        end,
        color = function()
          local status = require("sidekick.status").get()
          if status then
            return status.kind == "Error" and "DiagnosticError" or status.busy and "DiagnosticWarn" or "Special"
          else
            return "Normal"
          end
        end,
      },
      {
        "filetype",
      },
    },
  },
}

local lualine = {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    {
      -- Show current code context.
      "SmiteshP/nvim-navic",
      opts = {
        lsp = {
          auto_attach = true,
        },
      },
    },
  },
  opts = lualine_opts,
}

local barbar_keys = {
  { "<tab>", "<cmd>BufferNext<cr>", desc = "Next buffer" },
  { "<s-tab>", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
  { "L", "<cmd>BufferNext<cr>", desc = "Next buffer" },
  { "H", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
  { "<leader>x", "<cmd>BufferClose<cr>", desc = "Close buffer" },
  { "<leader>bx", "<cmd>BufferClose<cr>", desc = "Close buffer" },
  { "<leader>bX", "<cmd>BufferPickDelete<cr>", desc = "Pick buffer to delete" },
  { "<leader>br", "<cmd>BufferRestore<cr>", desc = "Restore buffer" },
  { "<leader>bo", "<cmd>BufferCloseAllButCurrent<cr>", desc = "Only keep current buffer" },
  { "<leader>bb", "<cmd>BufferPick<cr>", desc = "Pick buffer" },
  dot_repeatable_keymap({ "<leader>bn", function() vim.cmd("BufferMoveNext") end, desc = "Move buffer to next" }),
  dot_repeatable_keymap({ "<leader>bp", function() vim.cmd("BufferMovePrevious") end, desc = "Move buffer to previous" }),
  {
    "<leader>bs",
    function()
      vim.ui.select(
        {
          "BufferNumber",
          "Directory",
          "Language",
          "Name",
          "WindowNumber",
        },
        {
          prompt = 'Sort buffers by:',
        },
        function(selected)
          if selected == nil then
            return
          end
          local cmd = "BufferOrderBy" .. selected
          vim.cmd(cmd)
        end
      )
    end,
    desc = "Sort buffers",
  }
}

local barbar = {
  'romgrk/barbar.nvim',
  version = '*',
  event = "VeryLazy",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  init = function() vim.g.barbar_auto_setup = false end,
  opts = {
    focus_on_close = 'right',
    icons = {
      buffer_index = true,
    }
  },
  keys = barbar_keys,
}

local function setup_noice()
  local opts = {
    presets = {
      long_message_to_split = true, -- long messages will be sent to a split
    },
    notify = {
      enabled = false,
    },
  }
  opts.lsp = {
    hover = { enabled = false, },
    signature = { enabled = false, },
  }
  -- Use mini view for the following verbose messages.
  local verbose_messages = {
    "lines yanked",
    -- lazy.nvim config change message
    "Config Change Detected",
    -- undo message
    "; before #",
    -- redo message
    "; after #",
  }
  opts.routes = {
    {
      filter = {
        any = {},
      },
      view = "mini",
    },
  }
  for _, msg in ipairs(verbose_messages) do
    table.insert(opts.routes[1].filter.any, {
      find = msg,
    })
  end
  require("noice").setup(opts)
end

local noice = {
  "folke/noice.nvim",
  event = "VeryLazy",
  config = setup_noice,
  dependencies = {
    "MunifTanjim/nui.nvim",
  }
}

local config_render_markdown = function(_, _)
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  local opts = {
    file_types = { 'markdown', 'octo' },
    heading = { icons = { '󰎤 ', '󰎧 ', '󰎪 ', '󰎭 ', '󰎱 ', '󰎳 ' } },
    code = {
      disable_background = true,
      language_border = '',
    },
    sign = {
      enabled = false,
    },
    completions = {
      lsp = { enabled = true },
      blink = { enabled = true, },
    },
  }
  require("render-markdown").setup(opts)
  vim.cmd [[
    hi RenderMarkdownCode guibg=None
    hi RenderMarkdownCodeInline guibg=None
  ]]
end

local render_markdown = {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = { 'markdown', 'octo' },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  config = config_render_markdown,
}

---@type LazySpec
local yazi = {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>uf",
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      "<leader>uF",
      function()
        ---@diagnostic disable-next-line: undefined-field
        local cwd = vim.uv.cwd() .. "/"
        vim.ui.input({
          prompt = "Toggle Yazi: ",
          default = cwd,
          completion = "dir",
        }, function(dir)
          if not dir then
            return
          end
          require("yazi").yazi({}, dir)
        end)
      end,
      desc = "Open Yazi on selected dir",
    },
  },
  ---@type YaziConfig | {}
  opts = {
    open_for_directories = true,
    open_multiple_tabs = true,
    keymaps = {
      show_help = "<c-h>",
      open_file_in_vertical_split = "<c-v>",
      open_file_in_horizontal_split = "<c-x>",
      open_file_in_tab = "<c-t>",
      grep_in_directory = "<c-s>",
      replace_in_directory = "<c-g>",
      cycle_open_buffers = "<c-w>",
      copy_relative_path_to_selected_files = "<c-y>",
      send_to_quickfix_list = "<c-q>",
      change_working_directory = "<c-\\>",
      open_and_pick_window = "<c-o>",
    },
    floating_window_scaling_factor = 0.95,
    integrations = {
      grep_in_directory = "snacks.picker",
      grep_in_selected_files = "snacks.picker",
      picker_add_copy_relative_path_action = "snacks.picker",
    },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}

return {
  lualine,
  barbar,
  noice,
  render_markdown,
  yazi,
}
