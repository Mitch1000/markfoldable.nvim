local M = {}

_AnchorageConfigurationOptions = _AnchorageConfigurationOptions or {}

  --anchor_color = "#5f5f5f",
local default_config = {
  opened_icon = '',
  closed_icon = '',
  anchor_color = "#5f5f5f",
  anchor_bg = nil,
  bold = false,
  italic = false,
  underline = false,
  undercurl = false,
}

function M.set_default_config()
  _AnchorageConfigurationOptions = default_config
end

function M.set_config(config)
  for k, v in pairs(config) do
    _AnchorageConfigurationOptions[k] = v
  end
end

function M.get_config()
  return _AnchorageConfigurationOptions
end

return M
