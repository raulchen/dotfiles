local function Debug(opts)
  local args = vim.fn.split(opts.args, " ", true)
  -- remove empty strings from args
  for i = #args, 1, -1 do
    if args[i] == "" then
      table.remove(args, i)
    end
  end
  local dap = require("dap")
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

local function setup_dap(_, _)
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

  local keymap = vim.keymap.set
  keymap('n', '<leader>dd', dap.continue, { desc = 'Start/conintue debugger', })
  keymap('n', '<leader>dt', dap.terminate, { desc = 'Terminate debugger', })
  keymap('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle breakpoint', })
  keymap('n', '<leader>dB', dap.list_breakpoints, { desc = 'List breakpoints', })
  keymap('n', '<leader>dl', dap.run_last, { desc = 'Debug last', })

  keymap('n', '<leader>ds', dap.step_over, { desc = 'Step over', })
  keymap('n', '<leader>di', dap.step_into, { desc = 'Step into', })
  keymap('n', '<leader>do', dap.step_out, { desc = 'Step out', })
  keymap('n', '<leader>dB', dap.step_back, { desc = 'Step back', })

  keymap('n', '<leader>dc', dap.run_to_cursor, { desc = 'Continue execution until current cursor', })
  keymap('n', '<leader>dF', dap.restart_frame, { desc = 'Restart curent frame', })

  keymap('n', '<leader>dU', dap.up, { desc = 'Go up in stacktrace', })
  keymap('n', '<leader>dD', dap.down, { desc = 'Go down in stacktrace', })

  vim.api.nvim_create_user_command('Debug', Debug, { nargs = '?' })
end

local function setup_dapui(_, _)
  local dapui = require("dapui")
  dapui.setup()
  local dap = require("dap")
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open({ reset = true })
  end
  local keymap = vim.keymap.set
  keymap({ 'n', 'v' }, '<leader>de', dapui.eval, { desc = 'Evaluate', })
  keymap({ 'n', 'v' }, '<leader>du', function() dapui.toggle({ reset = true }) end, { desc = 'Toggle dap-ui', })
end

return {
  {
    "mfussenegger/nvim-dap",
    config = setup_dap,
  },
  {
    "rcarriga/nvim-dap-ui",
    config = setup_dapui,
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function(_, _)
      local dap_python = require("dap-python")
      dap_python.setup(vim.fn.stdpath('data') .. "/mason/packages/debugpy/venv/bin/python")
      dap_python.resolve_python = function()
        return 'python'
      end
      local keymap = vim.keymap.set
      keymap('n', '<leader>dM', dap_python.test_method, { desc = 'Debug current method', })
      keymap('n', '<leader>dC', dap_python.test_class, { desc = 'Debug current class', })
    end,
  },
}
