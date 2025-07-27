local vim = vim
    
local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
InsertMarker = require("markfoldable.insert_marker")

local spaces_id = vim.api.nvim_create_namespace('markfoldable_folder_spaces')
local arrow_id = vim.api.nvim_create_namespace('markfoldable_folder_ids')
local new_line_cursor_id = vim.api.nvim_create_namespace('markfoldable_new_line_cursor')
--
local ShiftedLine = nil
local saved_cursor = nil

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
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, 0, vim.fn.line('$'))
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, 0, vim.fn.line('$'))
end

local function MarkFoldable(config)
  ClearVirtualText()
  -- local open_marker = ""
  local open_marker = config.opened_icon
  local closed_marker = config.closed_icon
  local closed_folds_lnums = {}
    -- Define the fold expression func  

  local function MarkLines(lnum)
    if (lnum == 0) then return end
    if (IsEmptyLine(lnum)) then return end

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
    if is_current and CurrentInsert ~= lnum then
      local line = vim.fn.getline('.')
      if IsEmptyLine(lnum) then
        ShiftedLine = lnum
        -- vim.fn.setline(lnum, '--' .. line)
        --
        saved_cursor = vim.o.guicursor
        vim.o.guicursor = 'a:noCursor'
        InsertMarker(lnum - 1, "  █", 0, "inline", new_line_cursor_id, config, true, "Normal")
      end
    end

    if is_current and lnum == CurrentInsert then  
      return
    end

    return InsertMarker(lnum - 1, "  ", 0, position, spaces_id, config)
  end

  for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
    MarkLines(lnum)
  end

  if ShiftedLine ~= nil then
    local line = vim.fn.getline(ShiftedLine)
    -- local new_line = string.gsub(line, [[-]], "")
      -- vim.fn.setline(ShiftedLine, new_line)  
    ShiftedLine = nil

    vim.o.guicursor = saved_cursor  
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
