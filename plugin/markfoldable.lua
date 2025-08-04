local vim = vim
local cmd = vim.cmd

local con = require('markfoldable.config')

con.set_default_config()
local config = con.get_config()

function MPrint(text)
  vim.notify("MarkFoldable: " .. text, vim.log.levels.ERROR)
end

-- Globals
local function def_line_object()
  return { lnum = nil, buffer_id = nil }
end

CurrentlySpacedLines = { insert = { def_line_object() }, visual = {} }
CurrentMode = 'n'
PreviousMode = 'n'

-- Locals
local saved_cursor = vim.o.guicursor

vim.api.nvim_set_hl(0, 'noCursor', { reverse = true, blend = 100 })
vim.cmd([[set guicursor=n-v-c:block-Cursor]])


-- TODO: Prevent deleting behind line number spaces in insert mode
local function HandleInsert()
  ClearCursorText()
  local noCursor = 'a:noCursor'

  if vim.o.guicursor ~= noCursor then
    saved_cursor = vim.o.guicursor
  end

  vim.o.guicursor = noCursor

  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  CurrentlySpacedLines.insert[1] = def_line_object()
  CurrentlySpacedLines.insert[1].lnum = lnum
  CurrentlySpacedLines.insert[1].buffer_id = vim.fn.bufnr('%')
  vim.fn.setline(lnum, '  ' .. line)

  local col_pos = vim.fn.getpos('.')[3]
  local new_col_pos = col_pos + 2

  local function MoveCursor()
    vim.fn.cursor(lnum, new_col_pos)
    vim.o.guicursor = saved_cursor
  end

  vim.schedule(MoveCursor)
end

local function reset_line(lnum)
  local line = vim.fn.getline(lnum)

  local start_line = string.sub(line, 3, -1)

  vim.fn.setline(lnum, start_line)
end

-- local function ResetVisualLines()
--   for k,v in ipairs(CurrentlySpacedLines.visual) do
--     if v.buffer_id == vim.fn.bufnr('%') then
--       -- MPrint(tostring(v.lnum))
--       reset_line(v.lnum)
--     end
--   end
--   CurrentlySpacedLines.visual = {}
-- end

local function get_is_visual(value)
  return value == "V" or value == "v" or value == ""
end


local function ResetCurrentlySpacedLines()
  ClearVirtualText() 
  if CurrentlySpacedLines.insert[1].lnum == nil then
    CurrentlySpacedLines.insert[1] = def_line_object()
    return
  end

  if CurrentlySpacedLines.insert[1].buffer_id ~= vim.fn.bufnr('%') then
    CurrentlySpacedLines.insert[1] = def_line_object()
    return
  end

  reset_line(CurrentlySpacedLines.insert[1].lnum)

  local col_pos = vim.fn.getpos('.')[3]
  local start_current = CurrentlySpacedLines.insert[1]

  CurrentlySpacedLines.insert[1] = def_line_object()
  local new_pos = col_pos - 2

  vim.fn.cursor(start_current.lnum, new_pos)
end

 function is_spaced(lnum)
    if lnum == CurrentlySpacedLines.insert[1].lnum then
      return true
    end

    for _,v in ipairs(CurrentlySpacedLines.visual) do
      if v.lnum == lnum then return true end
    end

    return false
 end

-- local function HandleVisualMode()
--   local lnum = vim.fn.line('.')
--   if (is_spaced(lnum)) then return end
-- 
--   local line = vim.fn.getline(lnum)
-- 
--   if lnum == CurrentlySpacedLines.insert[1].lnum then return end
--   local ind = #CurrentlySpacedLines.visual + 1
--   CurrentlySpacedLines.visual[ind] = def_line_object()
--   CurrentlySpacedLines.visual[ind].lnum = lnum
--   CurrentlySpacedLines.visual[ind].buffer_id = vim.fn.bufnr('%')
--   vim.fn.setline(lnum, '  ' .. line)
-- end


function SetMode()
  local second_to_last_mode = PreviousMode
  PreviousMode = CurrentMode

  CurrentMode = vim.fn.mode()

  local col_pos = vim.fn.getpos('.')[3]
  if CurrentMode == 'i' and (not get_is_visual(PreviousMode) or col_pos == 1) then
    HandleInsert()
  end

  if (PreviousMode == 'i' and CurrentlySpacedLines.insert[1].lnum ~= nil) then
    ResetCurrentlySpacedLines()
  end
end

function AnchorageMarkFoldable()
  require('markfoldable.mark_foldable')(config)
end

vim.on_key(function(key)
  local pressed = string.find(tostring(key), "\xfd") ~= nil
  if pressed and CurrentMode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end

  if (get_is_visual(CurrentMode)) then
    -- ClearVirtualText()
    -- HandleVisualMode()
  end
end)

-- Update fold marks on text change
function TextChanged()
  ClearFoldMarks()
  MarkFolds()
end

cmd([[autocmd BufRead,BufNewFile,CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd TextChanged * execute "lua TextChanged()"]])
cmd([[autocmd ModeChanged * execute "lua SetMode()"]])
--cmd([[autocmd InsertLeave * execute "lua ResetCurrentlySpacedLines.insert()"]])

