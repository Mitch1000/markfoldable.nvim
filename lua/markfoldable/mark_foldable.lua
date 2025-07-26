local vim = vim

local IsEmptyLine = require('markfoldable.helpers.is_empty_line')

local spaces_id = vim.api.nvim_create_namespace('folder_spaces')
local arrow_id = vim.api.nvim_create_namespace('folder_ids')


local ShiftedLine = nil

local function GetIsOpen(lnum)
  local total_lines = vim.fn.line('$')
  if (lnum + 1 >= total_lines) then return false end
  if not (vim.fn.foldclosed(lnum + 1) == -1) then return false end
  return true
end

local function GetNextLineNr(lnum)
  local i = 1
  local nextLineNum = lnum + i
  while (IsEmptyLine(nextLineNum) and i < vim.fn.line('$')) do
    nextLineNum = lnum + i
    i = i + 1
  end

  return nextLineNum
end

local function IsMarked(lnum)
  local nextLineNum = GetNextLineNr(lnum)
  local indent = vim.fn.indent(lnum)
  local nextIndent = vim.fn.indent(nextLineNum)

  if IsEmptyLine(lnum) then return false end

  if (nextIndent <= indent) then return false end

  if (IsEmptyLine(nextLineNum)) then return false end
  return true
end

local function ClearVirtualText()
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, spaces_id, 0, vim.fn.line('$'))
  vim.api.nvim_buf_clear_namespace(bnr, spaces_id, 0, vim.fn.line('$'))
  vim.api.nvim_buf_clear_namespace(bnr, arrow_id, 0, vim.fn.line('$'))
  vim.api.nvim_buf_clear_namespace(bnr, arrow_id, 0, vim.fn.line('$'))
end

local function MarkFoldable(config)
  ClearVirtualText()
  -- local open_marker = ""
  local open_marker = config.opened_icon
  local closed_marker = config.closed_icon
  local closed_folds_lnums = {}
  -- Define the fold expression func
  local InsertMarker = require("markfoldable.insert_marker")

  local function MarkLines(lnum)
    if (lnum == 0) then return end

    if not IsMarked(lnum) then return end

    local is_open = GetIsOpen(lnum)

    if is_open then table.insert(closed_folds_lnums, lnum) end
    local mark = is_open and open_marker or closed_marker
    InsertMarker(lnum - 1, mark, 0, "overlay", arrow_id, config, is_open)
  end

  local function SpaceLines(lnum, position)
    if lnum <= 0 then return end
    if lnum > vim.fn.line('w$') then return end

    local is_current = vim.fn.line('.') == lnum

    local is_shifted = ShiftedLine == lnum
    local is_modded = ModifiedLine == lnum

    local line = vim.fn.getline(lnum)
    local started = vim.fn.getpos('.')[3] < 4 
    local ended = vim.fn.getpos('.')[3] >= 4 
    local has_shifted = CurrentInsert == nil

    if is_shifted and ended then
      local new_col_pos = vim.fn.getpos('.')[3] - 2 
      
      local function Shift()
        vim.fn.cursor(lnum, new_col_pos)
      end
      vim.schedule(Shift)
      ShiftedLine = nil 
      CurrentInsert = nil
    end

    -- local is_at_start = vim.fn.getpos('.')[3] < 4 and is_shifted 
    if is_current and InsertLine ~= lnum and started and not has_shifted then
      if not IsEmptyLine(lnum) then
        vim.fn.setline(lnum, '  ' .. line)
        ModifiedLine = lnum 
        SpacedLine = lnum
        ShiftedLine = lnum
        return
      end
    end

    -- if lnum == ModifiedLine and vim.fn.getpos('.')[3] > 1 then
    --   ResetModifiedLine()
    --   ModifiedLine = nil
    -- end

    return InsertMarker(lnum - 1, "  ", 0, position, spaces_id, config)
  end

  if SpacedLine ~= nil then
    local line = vim.fn.getline(SpacedLine)
    local new_line = string.gsub(line, "  ", "", 1)
    vim.fn.setline(SpacedLine, new_line)

    SpacedLine = nil
    ModifiedLine = nil
  end

  for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
    MarkLines(lnum)
  end

  for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
    SpaceLines(lnum, "inline")
  end
end

local hasErrored = false

return function(config)
  if (hasErrored == true) then return end

  local status, result = pcall(MarkFoldable, config)

  if not status then
    hasErrored = true
  end
  return result
end
