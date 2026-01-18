local dot_repeatable_keymap = require("core.utils").dot_repeatable_keymap

-- Global function to set winbar for oil buffers
function _G.get_oil_winbar()
  local winid = vim.g.statusline_winid
  local win_cfg = vim.api.nvim_win_get_config(winid)
  if win_cfg.relative ~= "" then
    return ""
  end
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

local function setup_oil()
  require("oil").setup({
    columns = {
      "icon",
      "permissions",
      "size",
      "mtime",
    },
    view_options = {
      show_hidden = true,
    },
    constrain_cursor = "name",
    use_default_keymaps = false,
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
      ["<C-s>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
      ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
      ["J"] = "actions.preview_scroll_down",
      ["K"] = "actions.preview_scroll_up",
      ["<c-c>"] = "actions.close",
      ["q"] = "actions.close",
      ["H"] = "actions.parent",
      ["L"] = "actions.select",
      ["-"] = "actions.parent",
      ["<CR>"] = "actions.select",
      ["gx"] = "actions.open_external",
      ["<localleader>p"] = "actions.preview",
      ["<localleader>s"] = "actions.change_sort",
      ["<localleader>."] = "actions.toggle_hidden",
      ["<localleader>\\"] = "actions.toggle_trash",
      ["<localleader>C"] = {
        callback = function()
          local config = require("oil.config")
          if config.constrain_cursor == "name" then
            config.constrain_cursor = false
          else
            config.constrain_cursor = "name"
          end
        end,
        desc = "Toggle constrain cursor",
      },
      ["<localleader>c"] = "actions.cd",
      ["<localleader>t"] = { "actions.tcd" },
      ["<localleader>d"] = "actions.open_cwd",
      ["<localleader>r"] = "actions.refresh",
      ["<localleader>y"] = "actions.yank_entry",
      ["<localleader>q"] = "actions.send_to_qflist",
      ["<localleader>:"] = {
        "actions.open_cmdline",
        opts = {
          shorten_path = true,
          modify = ":h",
        },
        desc = "Open the command line with the current directory as an argument",
      },
    },
    float = {
      border = "single",
      max_width = 160,
    },
  })

  local function set_oil_winbar(winid)
    local win_cfg = vim.api.nvim_win_get_config(winid)
    if win_cfg.relative ~= "" then
      return
    end
    vim.api.nvim_set_option_value("winbar", "%!v:lua.get_oil_winbar()", { win = winid })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "oil",
    callback = function()
      set_oil_winbar(0)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "OilActionsPost",
    callback = function(event)
      if event.data.actions.type == "move" then
        Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
    end,
  })
end

local function toggle_oil(prompt_for_dir)
  local oil = require("oil")
  if not prompt_for_dir then
    oil.toggle_float()
  else
    ---@diagnostic disable-next-line: undefined-field
    local cwd = vim.uv.cwd() .. "/"
    vim.ui.input({
      prompt = "Toggle file explorer: ",
      default = cwd,
      completion = "dir",
    }, function(dir)
      if not dir then
        return
      end
      oil.toggle_float(dir)
    end)
  end
end

local oil_keys = {
  { "<leader>uf", function() toggle_oil(false) end, desc = "Toggle file explorer on buffer dir" },
  { "<leader>uF", function() toggle_oil(true) end, desc = "Toggle file explorer on selected dir" },
}

local oil = {
  'stevearc/oil.nvim',
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- Disable lazy loading so that `vim <dir>` and `:e <dir>` will use oil.
  lazy = false,
  keys = oil_keys,
  config = setup_oil,
}

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

return {
  oil,
  lualine,
  barbar,
  noice,
  render_markdown,
}
