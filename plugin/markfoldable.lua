local vim = vim
local cmd = vim.cmd

local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
local con = require('markfoldable.config')

con.set_default_config()
local config = con.get_config()
local saved_cursor = nil

vim.api.nvim_set_hl(0, 'noCursor', { reverse = true, blend = 100 })
vim.cmd([[set guicursor=n-v-c:block-Cursor]])

function AnchorageMarkFoldable()
  require('markfoldable.mark_foldable')(config)
end

vim.on_key(function(key)
  local pressed = string.find(tostring(key), "\xfd") ~= nil

  if pressed and vim.api.nvim_get_mode().mode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end
end)

CurrentInsert = nil
local insert_chars = { "i", "a", "o", "I", "A", "O" }

function HandleInsert()
  saved_cursor = vim.o.guicursor
  vim.o.guicursor = 'a:noCursor'
  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  CurrentInsert = lnum
  vim.fn.setline(lnum, '  ' .. line)

  local col_pos = vim.fn.getpos('.')[3]
  local new_col_pos = col_pos + 2
  local function MoveCursor()
    vim.fn.cursor(lnum, new_col_pos)
    vim.o.guicursor = saved_cursor
  end
  vim.schedule(MoveCursor)
end

function ResetCurrentInsert()
  if CurrentInsert == nil then
    return
  end
  local line = vim.fn.getline(CurrentInsert)

  local start_line = string.sub(line, 3, -1)

  vim.fn.setline(CurrentInsert, start_line)

  local col_pos = vim.fn.getpos('.')[3]
  local start_current = CurrentInsert

  CurrentInsert = nil
  local new_pos = col_pos - 2

  vim.fn.cursor(start_current, new_pos)
end

cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd BufWrite * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd InsertLeave * execute "lua ResetCurrentInsert()"]])
cmd([[autocmd InsertEnter * execute "lua HandleInsert()"]])
