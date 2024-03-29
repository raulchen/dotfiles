local function setup_lspconfig(_, _)
  vim.lsp.set_log_level("warn")

  -- Global mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  local keymap = vim.keymap.set
  keymap('n', '<leader>ce', vim.diagnostic.setloclist, { desc = "Show all errors/warnings" })
  keymap('n', '[e', vim.diagnostic.goto_prev, { desc = "Previous error/warning" })
  keymap('n', ']e', vim.diagnostic.goto_next, { desc = "Next error/warning" })

  -- Buffer local mappings.
  local on_attach = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    local function map(mode, key, cmd, desc)
      local opts = { buffer = ev.buf, desc = desc }
      vim.keymap.set(mode, key, cmd, opts)
    end

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    map('n', 'gd', vim.lsp.buf.definition, "Go to definition")
    map('n', 'gi', vim.lsp.buf.implementation, "Go to implementation")
    map('n', 'gt', vim.lsp.buf.type_definition, "Go to type definition")
    map('n', 'K', vim.lsp.buf.hover, "Display hover information")
    map({ 'n', 'i' }, '<C-k>', vim.lsp.buf.signature_help, "Show signature")

    map('n', '<leader>cd', vim.lsp.buf.declaration, "Go to declaration")
    map('n', '<leader>cr', vim.lsp.buf.rename, "Rename symbol under cursor")
    map('n', '<leader>ca', vim.lsp.buf.code_action, "Code action")
    map('n', '<leader>cu', vim.lsp.buf.references, "Show usages")
    map('n', '<leader>ci', vim.lsp.buf.incoming_calls, "Show incoming calls")
    map('n', '<leader>co', vim.lsp.buf.outgoing_calls, "Show outgoing calls")

    map('n', '<leader>cf', vim.lsp.buf.format, "Format code")
    map('v', '<leader>cf', ":lua vim.lsp.buf.format()<CR>", "Format selected code")

    map('n', '<leader>cs', vim.lsp.buf.document_symbol, "List symbols in current buffer")
    map('n', '<leader>cS', vim.lsp.buf.workspace_symbol, "Search symbols in workspace")

    map('n', '<leader>cwa', vim.lsp.buf.add_workspace_folder, "Add workspace folder")
    map('n', '<leader>cwr', vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
    map('n', '<leader>cwl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List workspace folders")

    local gp = require('goto-preview')
    map('n', 'gD', gp.goto_preview_definition, "Preview definition")
    map('n', 'gT', gp.goto_preview_type_definition, "Preview type definition")
    map('n', 'gI', gp.goto_preview_implementation, "Preview implementation")
  end
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = on_attach,
  })
end

-- Settings for each LSP server.
local server_settings = {
  pyright = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  lua_ls = {
    Lua = {
      workspace = {
        -- Add the Neovim runtime files to the path.
        library = vim.api.nvim_get_runtime_file('', true),
        -- Avoid annoying prompts.
        -- https://github.com/neovim/nvim-lspconfig/issues/1700#issuecomment-1033127328
        checkThirdParty = false,
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

local function null_ls_opts()
  local null_ls = require('null-ls')
  return {
    sources = {
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.isort,
    },
  }
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

return {
  {
    'hrsh7th/cmp-nvim-lsp',
  },
  {
    'neovim/nvim-lspconfig',
    config = setup_lspconfig,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "bashls",
        "clangd",
        "lua_ls",
        "pyright",
      },
      handlers = {
        setup_server,
      },
    },
  },
  {
    'nvimtools/none-ls.nvim',
    opts = null_ls_opts,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    'j-hui/fidget.nvim',
    tag = 'legacy',
    opts = {},
  },
  {
    'rmagatti/goto-preview',
    config = setup_goto_preview,
  },
}
