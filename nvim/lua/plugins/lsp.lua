-- Settings for each LSP server.
local server_settings = {
  basedpyright = {
    -- Use ruff to organize imports.
    disableOrganizeImports = true,
    basedpyright = {
      analysis = {
        -- NOTE: `typeCheckingMode` and `diagnosticSeverityOverrides` doesn't seem to
        -- work on projects with a local pyrightconfig.json file
        --
        -- Use a less-strict type checking mode.
        typeCheckingMode = "standard",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        diagnosticSeverityOverrides = {
          -- Ignores "Variable not allowed in type expression".
          reportInvalidTypeForm = false,
        },
      },
    },
  },
  lua_ls = {
    Lua = {
      format = {
        enable = true,
        defaultConfig = {
          align_array_table = "false",
          align_continuous_assign_statement = "false",
          align_continuous_rect_table_field = "false",
          align_if_branch = "false",
        },
      },
    },
  },
}

local function setup_server(server)
  -- Add additional capabilities supported by nvim-cmp
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  local config = {
    capabilities = capabilities,
    on_attach = function(client, buf)
      if client.name == "clangd" then
        -- Like "a.vim", use command "A" for switching between source/header files.
        vim.api.nvim_buf_create_user_command(buf, 'A', "ClangdSwitchSourceHeader", { nargs = 0 })
      end
    end,
  }
  if server_settings[server] ~= nil then
    config.settings = server_settings[server]
  end
  local lspconfig = require('lspconfig')
  lspconfig[server].setup(config)
end



local function setup_lspconfig(_, _)
  vim.lsp.set_log_level("warn")

  local float_win_opts = { border = 'single' }

  -- Global mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  local keymap = vim.keymap.set
  keymap('n', '<leader>cx', function() vim.diagnostic.open_float(float_win_opts) end,
    { desc = "Show diagnostics in a floating window." })
  keymap('n', '<leader>cX', vim.diagnostic.setqflist, { desc = "Show all diagnostics" })

  keymap('n', '[d', function() vim.diagnostic.jump({ count = 1, float = false }) end,
    { desc = "Go to previous diagnostic" })
  keymap('n', ']d', function() vim.diagnostic.jump({ count = -1, float = false }) end, { desc = "Go to next diagnostic" })

  -- Buffer local mappings.
  local on_attach = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Mappings.
    local function map(mode, key, cmd, desc)
      local opts = { buffer = ev.buf, desc = desc }
      vim.keymap.set(mode, key, cmd, opts)
    end

    local wk = require("which-key")
    local gp = require('goto-preview')

    local has_picker, picker = pcall(require, "snacks.picker")
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    if has_picker then
      map('n', 'gd', picker.lsp_definitions, "Go to definition")
      map('n', 'gr', picker.lsp_references, "Search references")
      map('n', '<leader>cd', picker.lsp_declarations, "Go to declaration")
      map('n', '<leader>ci', picker.lsp_implementations, "Go to implementation")
      map('n', '<leader>ct', picker.lsp_type_definitions, "Go to type definition")
      map('n', '<leader>cs', picker.lsp_symbols, "Search LSP symbols")
      map('n', '<leader>cS', picker.lsp_workspace_symbols, "Search LSP symbols in workspace")
    else
      map('n', 'gd', vim.lsp.buf.definition, "Go to definition")
      map('n', 'gr', vim.lsp.buf.references, "Search references")
      map('n', '<leader>cd', vim.lsp.buf.declaration, "Go to declaration")
      map('n', '<leader>ci', vim.lsp.buf.implementation, "Go to implementation")
      map('n', '<leader>ct', vim.lsp.buf.type_definition, "Go to type definition")
      map('n', '<leader>cs', vim.lsp.buf.document_symbol, "Search LSP symbols")
      map('n', '<leader>cS', vim.lsp.buf.workspace_symbol, "Search LSP symbols in workspace")
    end
    map('n', 'gD', gp.goto_preview_definition, "Preview definition")
    map('n', '<leader>cD', gp.goto_preview_declaration, "Preview declaration")
    map('n', '<leader>cI', gp.goto_preview_implementation, "Preview implementation")
    map('n', '<leader>cT', gp.goto_preview_type_definition, "Preview type definition")

    map('n', 'K', function() vim.lsp.buf.hover(float_win_opts) end, "Display hover information")
    map('i', '<C-k>', function() vim.lsp.buf.signature_help(float_win_opts) end, "Show signature")

    map('n', '<leader>cr', vim.lsp.buf.rename, "Rename symbol under cursor")
    map('n', '<leader>ca', vim.lsp.buf.code_action, "Code action")

    wk.add({
      buffer = ev.buf,
      { "<leader>cw", name = "workspace" },
    })
    map('n', '<leader>cwa', vim.lsp.buf.add_workspace_folder, "Add workspace folder")
    map('n', '<leader>cwr', vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
    map('n', '<leader>cwl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List workspace folders")
  end
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = on_attach,
  })

  local mason_lspconfig = require("mason-lspconfig")
  local installed_servers = mason_lspconfig.get_installed_servers()
  local handles = {}
  for _, server in ipairs(installed_servers) do
    handles[server] = setup_server
  end
  mason_lspconfig.setup_handlers(handles)
end


local function setup_goto_preview()
  require('goto-preview').setup({
    default_mappings = false,
    height = 30,
    post_open_hook = function(_, win)
      -- Close the current preview window with <Esc> or 'q'.
      local function close_window()
        vim.api.nvim_win_close(win, true)
      end
      vim.keymap.set('n', '<Esc>', close_window, { buffer = true })
      vim.keymap.set('n', 'q', close_window, { buffer = true })
    end,
  })
end

local function setup_tiny_inline_diagnostic()
  vim.diagnostic.config({
    -- Disable signs.
    signs = false,
    virtual_text = {
      -- Disable messages, only show markers.
      format = function(_) return "" end,
      prefix = "󰊠",
      spacing = 0,
    },
  })
  require('tiny-inline-diagnostic').setup({
    preset = "ghost",
    options = {
      multiple_diag_under_cursor = true,
      virt_texts = {
        priority = 9999,
      },
    },
  })
end

return {
  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" },
    config = setup_lspconfig,
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'hrsh7th/cmp-nvim-lsp',
      {
        'rmagatti/goto-preview',
        config = setup_goto_preview,
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        "~/.hammerspoon/Spoons/EmmyLua.spoon/annotations",
      },
    },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000, -- needs to be loaded in first
    config = setup_tiny_inline_diagnostic,
  },
}
