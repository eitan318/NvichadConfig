
local plugins = {}

-- Load each plugin from the custom/plugins folder
local plugin_files = vim.fn.globpath(vim.fn.stdpath("config") .. "/lua/custom/plugins", "*.lua", false, true)

for _, file in ipairs(plugin_files) do
  local plugin = dofile(file)
  table.insert(plugins, plugin)
end

return plugins
