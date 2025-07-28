local vim = vim
local cmd = vim.cmd

local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
local con = require('markfoldable.config')

con.set_default_config()
local config = con.get_config()

vim.api.nvim_set_hl(0, 'noCursor', { reverse = true, blend = 100 })
vim.cmd([[set guicursor=n-v-c:block-Cursor]])

local saved_cursor = vim.o.guicursor

function AnchorageMarkFoldable()
  require('markfoldable.mark_foldable')(config)
end

vim.on_key(function(key)
  local pressed = string.find(tostring(key), "\xfd") ~= nil

  if pressed and vim.api.nvim_get_mode().mode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end
end)


local function get_def_ins()
  return { lnum = nil, buffer_id = nil }
end

CurrentInsert = get_def_ins()
-- local insert_chars = { "i", "a", "o", "I", "A", "O" }

function HandleInsert()
  ClearVirtualText()
  local noCursor = 'a:noCursor'

  if vim.o.guicursor ~= noCursor then
    saved_cursor = vim.o.guicursor
  end

  vim.o.guicursor = noCursor

  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  CurrentInsert.lnum = lnum
  CurrentInsert.buffer_id = vim.fn.bufnr('%')
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
  if CurrentInsert.lnum == nil then
    CurrentInsert = get_def_ins()
    return
  end

  if CurrentInsert.buffer_id ~= vim.fn.bufnr('%') then
    CurrentInsert = get_def_ins()
    return
  end

  local line = vim.fn.getline(CurrentInsert.lnum)

  local start_line = string.sub(line, 3, -1)

  vim.fn.setline(CurrentInsert.lnum, start_line)

  local col_pos = vim.fn.getpos('.')[3]
  local start_current = CurrentInsert

  CurrentInsert = get_def_ins()
  local new_pos = col_pos - 2

  vim.fn.cursor(start_current.lnum, new_pos)
end

  cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
-- cmd([[autocmd BufWrite * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd InsertLeave * execute "lua ResetCurrentInsert()"]])
cmd([[autocmd InsertEnter * execute "lua HandleInsert()"]])

