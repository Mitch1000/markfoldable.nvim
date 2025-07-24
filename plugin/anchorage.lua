local vim = vim
local cmd = vim.cmd

local config = require('anchorage.config')

function Sched()
end

function AnchorageMarkFoldable()
  require('anchorage.mark_foldable')(config)
end


function AnchorageMarkFoldableSleep()
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
