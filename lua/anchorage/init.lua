local M = {}
local vim = vim

--- default config
---@class BackpackConfig
M.config = {
  opened_icon = '',
  closed_icon = '',
  anchor_color = "#5f5f5f",
  anchor_bg = nil,
}

local function check_config(config)
    local err
    return not err
end

--- update global configuration with user settings
---@param config? BackpackConfig user configuration
function M.setup(config)
  if check_config(config) then
      M.config = vim.tbl_deep_extend("force", M.config, config or {})
  else
      vim.notify("Anchorage: Errors found while loading user config. Using default config.", vim.log.levels.ERROR)
  end

  function AnchorageMarkFoldable()
    require('anchorage.mark_foldable')(config)
  end

  local cmd = vim.cmd
  cmd([[nnoremap z <cmd>execute "lua AnchorageMarkFoldable()"<CR>]])

  cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
  cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
end

return M
