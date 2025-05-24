
-- Clear all existing C++ configurations

local M = {}

function M.setup()
  local dap = require("dap")

  -- Override the DAP configuration for C++
  dap.configurations.cpp = {
    {
      name = "Launch executable",
      type = "codelldb", -- Or the adapter you are using
      request = "launch",
      program = function()
        local local_config_path = vim.fn.getcwd() .. "/local.lua"
        local status, config = pcall(dofile, local_config_path)
        if status and config and config.executable then
          return config.executable
        else
          print("Error: Could not load executable from local.lua")
          return nil
        end
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    },
  }

--   -- Define the CoreCLR adapter for .NET
-- dap.adapters.coreclr = {
--   type = 'executable',
--   command = 'C:/tools/netcoredbg/netcoredbg.exe', -- Full path to netcoredbg.exe
--   args = {'--interpreter=vscode'},
-- }
--
-- Debug configurations for C# (WPF projects)
dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch WPF App",
    request = "launch",

    program = function()
      local local_config_path = vim.fn.getcwd() .. "/local.lua"
      local status, config = pcall(dofile, local_config_path)
      if status and config and config.executable then
        return config.executable
      else
        print("Error: Could not load executable from local.lua")
        return nil
      end
    end,

    cwd = vim.fn.getcwd(),
    stopAtEntry = false,
    console = "integratedTerminal", -- Optional: "internalConsole", "integratedTerminal" or "externalTerminal"
  },
}
end
return M

