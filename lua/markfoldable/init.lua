local vim = vim
local M = {}

local default_config = require('markfoldable.config').get_default_config()

--- default config
---@class MarkFoldableConfig

local function check_config(config)
  local err
  for k in pairs(config) do
    if default_config[k] ~= nil then
      local default_type = type(default_config[k])
      local v = config[k]
      if type(v) ~= default_type then
        err = [[Config value: "]] .. tostring(k) .. [[" must be of type: "]] .. default_type .. [[".]]
        return err
      end
    end
  end
  return err
end

--- update global configuration with user settings
---@param config? MarkFoldableConfig user configuration
function M.setup(config)
  if type(config) ~= 'table' then return end

  local error = check_config(config)
  if not error then
    require('markfoldable.config').set_config(config)
  else
    vim.notify("Anchorage: Errors found while loading user config. Using default config. " .. error, vim.log.levels.ERROR)
  end
end

return M
