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
  ---@diagnostic disable-next-line
  dap_config.program = program
  ---@diagnostic disable-next-line
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

local dot_repeatable_keymap = require("base.utils").dot_repeatable_keymap

return {
  {
    "mfussenegger/nvim-dap",
    config = setup_dap,
    keys = {
      { "<leader>dd", function() require('dap').continue() end, desc = "Start/conintue debugger" },
      { "<leader>dt", function() require('dap').terminate() end, desc = "Terminate debugger" },
      { "<leader>db", function() require('dap').toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require('dap').list_breakpoints() end, desc = "List breakpoints" },
      { "<leader>dl", function() require('dap').run_last() end, desc = "Debug last" },
      dot_repeatable_keymap({ "<leader>ds", function() require('dap').step_over() end, desc = "Step over" }),
      dot_repeatable_keymap({ "<leader>di", function() require('dap').step_into() end, desc = "Step into" }),
      dot_repeatable_keymap({ "<leader>do", function() require('dap').step_out() end, desc = "Step out" }),
      dot_repeatable_keymap({ "<leader>dB", function() require('dap').step_back() end, desc = "Step back" }),
      { "<leader>dc", function() require('dap').run_to_cursor() end, desc = "Continue execution until current cursor" },
      { "<leader>dF", function() require('dap').restart_frame() end, desc = "Restart curent frame" },
      dot_repeatable_keymap({ "<leader>dU", function() require('dap').up() end, desc = "Go up in stacktrace" }),
      dot_repeatable_keymap({ "<leader>dD", function() require('dap').down() end, desc = "Go down in stacktrace" }),
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
      {
        "rcarriga/nvim-dap-ui",
        config = setup_dapui,
        keys = {
          { "<leader>du", function() require('dapui').toggle() end, desc = "Toggle dap-ui" },
          { "<leader>de", function() require('dapui').eval() end, desc = "Evaluate" },
        },
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
      },
    },
  },
}
