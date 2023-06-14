local function setup_lspconfig(_, _)
  -- vim.lsp.set_log_level("debug")

  -- Mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  local opts = { noremap = true, silent = true }
  vim.keymap.set('n', '<leader>cp', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '<leader>cn', vim.diagnostic.goto_next, opts)

  -- Use an on_attach function to only map the following keys
  -- after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local bufopts = { noremap = true, silent = false, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set({ 'n', 'i' }, '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<leader>cwa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<leader>cwr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<leader>cwl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<leader>cd', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<leader>cu', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, bufopts)
    vim.keymap.set('v', '<leader>cf', ":lua vim.lsp.buf.format()<CR>", bufopts)
  end

  -- Add additional capabilities supported by nvim-cmp
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

  local servers = {
    'bashls',
    'clangd',
    'gopls',
    "jdtls",
    'pyright',
    'rust_analyzer',
    'lua_ls',
  }

  -- NOTE: Use pip to install pylsp and its plugins, do not use Mason.
  -- pip install 'python-lsp-server[all]' python-lsp-black python-lsp-isort

  -- Settings for each LSP server.
  local server_settings = {
    pylsp = {
      pylsp = {
        plugins = {
          autopep8 = { enabled = false },
          black = { enabled = true },
          flake8 = { enabled = true },
          isort = { enabled = true },
          mccabe = { enabled = false },
          pycodestyle = { enabled = false },
          pydocstyle = { enabled = false },
          pyflakes = { enabled = false },
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

  local lspconfig = require('lspconfig')
  for _, lsp in ipairs(servers) do
    local config = {
      on_attach = on_attach,
      flags = {
        -- This will be the default in neovim 0.7+
        debounce_text_changes = 150,
      },
      capabilities = capabilities,
    }
    if server_settings[lsp] ~= nil then
      config.settings = server_settings[lsp]
    end
    lspconfig[lsp].setup(config)
  end
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

return {
  {
    'hrsh7th/cmp-nvim-lsp',
  },
  {
    'neovim/nvim-lspconfig',
    config = setup_lspconfig,
  },
  {
    'jose-elias-alvarez/null-ls.nvim',
    opts = null_ls_opts,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
