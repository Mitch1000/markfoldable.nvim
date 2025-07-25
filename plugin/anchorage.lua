local vim = vim
local cmd = vim.cmd

local con = require('anchorage.config')

con.set_default_config()
local config = con.get_config()

function AnchorageMarkFoldable()
  require('anchorage.mark_foldable')(config)
end

vim.on_key(function(key)
  local pressed = string.find(tostring(key), "\xfd") ~= nil

  if pressed and vim.api.nvim_get_mode().mode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end
end)

cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
