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

SpacedLine = nil
ModifiedLine = nil
-- to prevent inserting spaces in blank lines
InsertLine = nil
AddedEnds = nil 
CurrentInsert = nil 

function ResetSpaceLine()
  if IsEmptyLine(SpacedLine) then
    vim.fn.setline(SpacedLine, "")  
    SpacedLine = nil
  end
end

function MoveCursorOnInsert()
  local line = vim.fn.getline(".")
  local lnum = vim.fn.line(".")
  local is_new_line = string.len(line) < 1

  if IsEmptyLine(lnum) then
    InsertLine = lnum
  end
  CurrentInsert = lnum
  
  if vim.fn.getpos('.')[3] == 1 then
    local function MoveCursor()
      if vim.fn.getpos('.')[3] == 1 then
         --vim.fn.cursor(lnum, '3')
         vim.fn.setpos('.', {0, lnum, 3, 0})
      end
    end
    vim.schedule(MoveCursor) 
    --vim.defer_fn(MoveCursor, 500) 
  else
    ResetModifiedLine()
  end
end

function ResetModifiedLine()
  local line = vim.fn.getline(ModifiedLine)
  local new_line = string.gsub(line, "  ", "", 1)
  vim.fn.setline(ModifiedLine, new_line)
end

function ResetCurrentInsert()
  CurrentInsert = nil
end


cmd([[autocmd BufRead,BufNewFile, * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd VimLeavePre,BufWritePre * execute "lua ResetModifiedLine()"]])
cmd([[autocmd BufWrite * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd InsertEnter * execute "lua MoveCursorOnInsert()"]])
cmd([[autocmd InsertLeave * execute "lua ResetCurrentInsert()"]])
cmd([[autocmd ModeChanged * execute "lua ResetSpaceLine()"]])
