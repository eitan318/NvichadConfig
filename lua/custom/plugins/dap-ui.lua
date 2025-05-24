return {
  "rcarriga/nvim-dap-ui",
  event = "VeryLazy",
  dependencies = "mfussenegger/nvim-dap",
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end

    dap.listeners.before.event_terminated["dapui_config"] = function()
      --print("Debug session terminated.")
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      --print("Debug session exited.")
      dapui.close()
    end

  end,
}
