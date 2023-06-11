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
  local function Debug(opts)
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
  vim.api.nvim_create_user_command('DebugLast', function(_) require("dap").run_last() end, {})
  vim.api.nvim_create_user_command('DebugTerminate', function(_) require("dap").terminate() end, {})
  vim.api.nvim_create_user_command('Breakpoint', function(_) require("dap").toggle_breakpoint() end, {})
end

local function setup_dapui(_, _)
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
  dap = require("dap")
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open({ reset = true })
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    config = setup_dap,
  },
  {
    "rcarriga/nvim-dap-ui",
    config = setup_dapui,
  }
}
