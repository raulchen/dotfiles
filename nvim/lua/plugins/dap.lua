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

local function dap_keys()
  local _repeatable = require("core.utils").dot_repeatable_keymap
  local _dap = function() return require("dap") end
  return {
    { "<leader>dd", function() _dap().continue() end, desc = "Start/conintue debugger" },
    { "<leader>dt", function() _dap().terminate() end, desc = "Terminate debugger" },
    { "<leader>db", function() _dap().toggle_breakpoint() end, desc = "Toggle breakpoint" },
    { "<leader>dB", function() _dap().list_breakpoints(true) end, desc = "List breakpoints" },
    { "<leader>dC", function() _dap().set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Conditional breakpoint" },
    { "<leader>dE", function() _dap().set_exception_breakpoints() end, desc = "Exception breakpoint" },
    { "<leader>dl", function() _dap().run_last() end, desc = "Debug last" },
    _repeatable({ "<leader>ds", function() _dap().step_over() end, desc = "Step over" }),
    _repeatable({ "<leader>di", function() _dap().step_into() end, desc = "Step into" }),
    _repeatable({ "<leader>do", function() _dap().step_out() end, desc = "Step out" }),
    { "<leader>dc", function() _dap().run_to_cursor() end, desc = "Continue execution until current cursor" },
    { "<leader>dF", function() _dap().restart_frame() end, desc = "Restart curent frame" },
    _repeatable({ "<leader>dU", function() _dap().up() end, desc = "Go up in stacktrace" }),
    _repeatable({ "<leader>dD", function() _dap().down() end, desc = "Go down in stacktrace" }),
    { "<leader>dp", function() _dap().pause() end, desc = "Pause" },
  }
end

local function setup_dapui(_, _)
  local dapui = require("dapui")
  dapui.setup()
  local dap = require("dap")
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open({ reset = true })
  end
end

local dapui_keys = {
  { "<leader>du", function() require('dapui').toggle() end, desc = "Toggle dap-ui" },
  { "<leader>de", function() require('dapui').eval() end, desc = "Evaluate" },
}

local function setup_dap_python()
  local python_adapter = vim.fn.executable("uv") == 1 and "uv" or "python3"
  require("dap-python").setup(python_adapter)
end

local dap_python_keys = {
  { "<localleader>d", "", desc = "+debug", ft = "python" },
  { "<localleader>dm", function() require('dap-python').test_method() end, desc = "Debug current method", ft = "python" },
  { "<localleader>dc", function() require('dap-python').test_class() end, desc = "Debug current class", ft = "python" },
}

return {
  {
    "mfussenegger/nvim-dap",
    config = setup_dap,
    keys = dap_keys,
    dependencies = {
      {
        "mfussenegger/nvim-dap-python",
        config = setup_dap_python,
        keys = dap_python_keys,
      },
      {
        "rcarriga/nvim-dap-ui",
        config = setup_dapui,
        keys = dapui_keys,
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
      },
    },
  },
}
