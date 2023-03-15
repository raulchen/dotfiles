---@diagnostic disable: deprecated
vim.cmd [[
source ~/.vimrc
]]

require("mason").setup()
require("mason-lspconfig").setup()

-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
require("neodev").setup({
    library = { plugins = { "nvim-dap-ui" }, types = true },
})

-- === lspconfig ===

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

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
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>f', vim.lsp.buf.formatting, bufopts)
  vim.keymap.set('v', '<leader>f', "<cmd>lua vim.lsp.buf.range_formatting()<CR>", bufopts)
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
local lspconfig = require('lspconfig')
local config = {
    on_attach = on_attach,
    flags = {
        -- This will be the default in neovim 0.7+
        debounce_text_changes = 150,
    },
    capabilities = capabilities,
}
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup(config)
end

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
    snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-d>'] = cmp.mapping.scroll_docs( -4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-_>'] = cmp.mapping.complete(), -- "C-_" is "ctrl+/"
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<C-n>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<C-p>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable( -1) then
            luasnip.jump( -1)
          else
            fallback()
          end
        end, { 'i', 's' }),
    }),
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
}

local dap = require('dap')
dap.adapters.codelldb = {
    type = 'server',
    port = "${port}",
    executable = {
        command = 'codelldb',
        args = { "--port", "${port}" },
    }
}
dap.configurations.cpp = {
    {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        args = function()
          local args = vim.fn.input('Arguments: ')
          return vim.fn.split(args, " ", true)
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
    },
}

local dapui = require("dapui")
dapui.setup({
    icons = {
        expanded = "▾",
        cuurent_frame = "●",
        collapsed = "▸",
    },
    controls = {
        icons = {
            disconnect = "🚫",
            pause = "⏸️",
            play = "▶️",
            run_last = "🔂",
            step_back = "↩️",
            step_into = "⬇️",
            step_out = "⬆️",
            step_over = "➡️",
            terminate = "⏹️",
        },
    }
})
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open({ reset = true })
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

function Debug(opts)
  local dap = require("dap")
  local args = vim.fn.split(opts.args, " ", true)
  -- remove empty strings from args
  for i = #args, 1, -1 do
    if args[i] == "" then
      table.remove(args, i)
    end
  end
  if #args == 0 then
    dap.continue()
    return
  end
  local program = args[1]
  local program_args = { unpack(args, 2) }

  local ft = vim.bo.filetype
  local configs = dap.configurations[ft]
  if configs == nil then
    print("Filetype \"" .. ft .. "\" has no dap configs")
    return
  end
  local dap_config = configs[1]
  if #configs > 1 then
    vim.ui.select(
        configs,
        {
            prompt = "Select config to run: ",
            format_item = function(config)
              return config.name
            end
        },
        function(config)
          dap_config = config
        end
    )
  end
  dap_config = vim.deepcopy(dap_config)
  dap_config.program = program
  dap_config.args = program_args
  dap.run(dap_config)
end

vim.api.nvim_create_user_command('Debug', Debug, { nargs = '?' })
vim.api.nvim_create_user_command('DebugLast', function(opts) require("dap").run_last() end, {})
vim.api.nvim_create_user_command('DebugTerminate', function(opts) require("dap").terminate() end, {})
vim.api.nvim_create_user_command('Breakpoint', function(opts) require("dap").toggle_breakpoint() end, {})

-- Only enable Copilot for certain filetypes.
vim.g.copilot_filetypes = {
    ["*"] = false,
    ["c"] = true,
    ["cpp"] = true,
    ["java"] = true,
    ["python"] = true,
    ["lua"] = true,
    ["rust"] = true,
    ["go"] = true,
    ["vim"] = true,
    ["sh"] = true,
    ["zsh"] = true,
    ["xml"] = true,
    ["gitcommit"] = true,
}
-- Bind <C-F> to copilot-next.
vim.keymap.set('i', '<C-F>', "<Plug>(copilot-next)", {})
