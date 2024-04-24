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

  vim.api.nvim_create_user_command('Debug', Debug, { nargs = '?' })
end

local function setup_dapui(_, _)
  local dapui = require("dapui")
  dapui.setup()
  local dap = require("dap")
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open({ reset = true })
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    config = setup_dap,
    keys = {
      { "<leader>dd", "<cmd>lua require('dap').continue()<cr>", desc = "Start/conintue debugger" },
      { "<leader>dt", "<cmd>lua require('dap').terminate()<cr>", desc = "Terminate debugger" },
      { "<leader>db", "<cmd>lua require('dap').toggle_breakpoint()<cr>", desc = "Toggle breakpoint" },
      { "<leader>dB", "<cmd>lua require('dap').list_breakpoints()<cr>", desc = "List breakpoints" },
      { "<leader>dl", "<cmd>lua require('dap').run_last()<cr>", desc = "Debug last" },
      { "<leader>ds", "<cmd>lua require('dap').step_over()<cr>", desc = "Step over" },
      { "<leader>di", "<cmd>lua require('dap').step_into()<cr>", desc = "Step into" },
      { "<leader>do", "<cmd>lua require('dap').step_out()<cr>", desc = "Step out" },
      { "<leader>dB", "<cmd>lua require('dap').step_back()<cr>", desc = "Step back" },
      { "<leader>dc", "<cmd>lua require('dap').run_to_cursor()<cr>", desc = "Continue execution until current cursor" },
      { "<leader>dF", "<cmd>lua require('dap').restart_frame()<cr>", desc = "Restart curent frame" },
      { "<leader>dU", "<cmd>lua require('dap').up()<cr>", desc = "Go up in stacktrace" },
      { "<leader>dD", "<cmd>lua require('dap').down()<cr>", desc = "Go down in stacktrace" },
    },
    dependencies = {
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
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    config = setup_dapui,
    keys = {
      { "<leader>du", "<cmd>lua require('dapui').toggle()<cr>", desc = "Toggle dap-ui" },
      { "<leader>de", "<cmd>lua require('dapui').eval()<cr>", desc = "Evaluate" },
    }
  },
}
