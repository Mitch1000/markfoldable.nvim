local M = {}

local vim = vim

--- default config
---@class BackpackConfig

local function check_config(config)
    local err = false
    return not err
end

--- update global configuration with user settings
---@param config? BackpackConfig user configuration
function M.setup(config)
  if check_config(config) then
      require('anchorage.config').set_config(config)
  else
      vim.notify("Anchorage: Errors found while loading user config. Using default config.", vim.log.levels.ERROR)
  end
end

return M
