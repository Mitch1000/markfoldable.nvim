local vim = vim
local cmd = vim.cmd

local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
local con = require('markfoldable.config')

con.set_default_config()
local config = con.get_config()

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
WasNewLine = nil 
local insert_chars = { "i", "a", "o", "I", "A", "O" }

local function isInsertChar(char)
  for i,v in ipairs(insert_chars) do
    if char == v then return true end
  end

  return false 
end

function MoveCursorOnInsert(char)
  if not isInsertChar(char) then
    return
  end
  if vim.fn.mode() == "i" then
    return
  end

  if CurrentInsert ~= nil then
    return
  end


  local lnum = vim.fn.line(".")

  if char == "o" then
    WasNewLine = true
    local function SetBlank()
      vim.fn.setline(lnum + 1, '    ')

      local function MoveCursor()
        vim.fn.cursor(lnum + 1, 3)
      end

      vim.schedule(MoveCursor) 

      CurrentInsert = lnum + 1
    end

    vim.schedule(SetBlank) 

    return
  end

  local line = vim.fn.getline(lnum)
  CurrentInsert = lnum
  vim.fn.setline(lnum, '  ' .. line .. '  ')

  local col_pos = vim.fn.getpos('.')[3]
  local new_col_pos = col_pos + 2

  if char == "A" then
    local function MoveCursor()
      vim.fn.cursor(lnum, string.len(line) + 3)
    end
    vim.schedule(MoveCursor) 
    return
  end

  if char ~= "o" then
    vim.fn.cursor(lnum, new_col_pos)
  end
end

function ResetCurrentInsert()
  local line = vim.fn.getline(CurrentInsert)
  local start_line = string.sub(line, 3, -1)


  local new_line = string.sub(start_line, 1, -3)
  vim.fn.setline(CurrentInsert, new_line)

  local col_pos = vim.fn.getpos('.')[3]
  local start_current = CurrentInsert

  CurrentInsert = nil
  local new_pos = col_pos - 2
  print(new_pos)

  if col_pos >= string.len(line) - 4 then
    vim.fn.cursor(start_current, col_pos)
    return 
  end

  if new_pos > 0 then
    vim.fn.cursor(start_current, new_pos)
  end

  if WasNewLine then
    WasNewLine = false
    CurrentInsert = nil 
  end
end

vim.on_key(MoveCursorOnInsert)

cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd BufWrite * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd InsertLeave * execute "lua ResetCurrentInsert()"]])
