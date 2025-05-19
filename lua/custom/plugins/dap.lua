return {
  "mfussenegger/nvim-dap",
  config = function(_, _)
    -- Load DAP key mappings
    require("core.utils").load_mappings("dap")
    -- Load project-specific DAP configurations
    require("custom.configs.dap").setup()
  end,
}

