
return {
  "neovim/nvim-lspconfig",
  config = function()
    require "plugins.configs.lspconfig" -- Default NvChad config
    require "custom.configs.lspconfig"  -- Custom LSP configuration
  end,
}
