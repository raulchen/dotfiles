local function setup_nvimtree(_, _)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  require("nvim-tree").setup({})
end

local oil_opts = {
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
    ["<CR>"] = "actions.select",
    ["L"] = "actions.select",
    ["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
    ["<C-s>"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
    ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
    ["<C-p>"] = "actions.preview",
    ["<c-c>"] = "actions.close",
    ["q"] = "actions.close",
    ["<leader>r"] = "actions.refresh",
    ["-"] = "actions.parent",
    ["H"] = "actions.parent",
    ["_"] = "actions.open_cwd",
    ["`"] = "actions.cd",
    ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
    ["gs"] = "actions.change_sort",
    ["gx"] = "actions.open_external",
    ["g."] = "actions.toggle_hidden",
    ["g\\"] = "actions.toggle_trash",
  },
  float = {
    max_width = 160,
  },
}

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

local function setup_whichkey(_, _)
  local wk = require("which-key")
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

local lualine_opts = {
  options = {
    section_separators = "",
    component_separators = "|",
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
        -- Show macro recording message
        function()
          ---@diagnostic disable-next-line
          local mode = require("noice").api.statusline.mode.get()
          local substr_idx = mode:find("recording")
          return mode:sub(substr_idx)
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
        color = { fg = "#ff9e64" },
      },
      -- Show search count
      {
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
        color = { fg = "#ff9e64" },
      },
      {
        "copilot",
        show_colors = true,
      },
      {
        "filetype",
      },
    },
  },
}

local function setup_indent_blankline(_, _)
  require("ibl").setup {
    indent = { char = "▏" },
    scope = { enabled = true },
  }
end

local function setup_alpha()
  local alpha = require("alpha")
  local startify = require("alpha.themes.startify")
  local fzf = require("plugins.fzf")

  startify.section.top_buttons.val = {
    startify.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    ---@diagnostic disable-next-line: param-type-mismatch
    startify.button("f", "󰈞  Find files", fzf.fzf_files),
    ---@diagnostic disable-next-line: param-type-mismatch
    startify.button("h", "󰋚  Find current dir file history", fzf.fzf_oldfiles),
    startify.button("s", "  Restore current dir session", "<cmd>SessionManager load_current_dir_session<CR>"),
    startify.button("q", "󰅚  Quit Neovim", ":qa<CR>"),
  }
  startify.section.bottom_buttons.val = {}
  alpha.setup(startify.opts)
end

local function setup_noice()
  local opts = {}
  opts.lsp = {
    override = {
      -- override the default lsp markdown formatter with Noice
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      -- override the lsp markdown formatter with Noice
      ["vim.lsp.util.stylize_markdown"] = true,
      -- override cmp documentation with Noice (requires nvim-cmp)
      ["cmp.entry.get_documentation"] = true,
    },
  }
  -- Use mini view for the following verbose messages.
  local verbose_messages = {
    "written",
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

local dot_repeatable_keymap = require("base.utils").dot_repeatable_keymap

local barbar_keys = {
  { "<tab>", "<cmd>BufferNext<cr>", desc = "Next buffer" },
  { "<s-tab>", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
  { "<leader>x", "<cmd>BufferClose<cr>", desc = "Close buffer" },
  { "<leader>br", "<cmd>BufferRestore<cr>", desc = "Restore buffer" },
  { "<leader>bo", "<cmd>BufferCloseAllButCurrent<cr>", desc = "Only keep current buffer" },
  { "<leader>bb", "<cmd>BufferPick<cr>", desc = "Pick buffer" },
  { "<leader>bx", "<cmd>BufferPickDelete<cr>", desc = "Pick buffer to delete" },
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

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = setup_nvimtree,
    keys = {
      { "<leader>ut", "<cmd>NvimTreeFindFileToggle!<cr>", desc = "Toggle nvim-tree" },
    },
  },
  {
    'stevearc/oil.nvim',
    opts = oil_opts,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- Disable lazy loading so that `vim <dir>` and `:e <dir>` will use oil.
    lazy = false,
    keys = {
      { "<leader>uf", function() toggle_oil(false) end, desc = "Toggle file explorer on buffer dir" },
      { "<leader>uF", function() toggle_oil(true) end, desc = "Toggle file explorer on selected dir" },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = setup_indent_blankline,
  },
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
    "nvim-lualine/lualine.nvim",
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
      {
        'AndreM222/copilot-lualine',
      },
    },
    opts = lualine_opts,
  },
  {
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
  },
  {
    "nyngwang/NeoZoom.lua",
    opts = {},
    keys = {
      { '<c-w>z', '<cmd>NeoZoomToggle<cr>', desc = "Toggle zoom" },
      { '<leader>wz', '<cmd>NeoZoomToggle<cr>', desc = "Toggle zoom" },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    config = setup_noice,
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        opts = {
          stages = "fade",
          timeout = 2000,
        },
      }
    }
  },
  {
    'goolord/alpha-nvim',
    event = "VimEnter",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = setup_alpha,
  },
}
