local vim = vim
local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
local InsertMarker = require("markfoldable.insert_marker")
local GetHighlightColor = require("markfoldable.get_highlight_color")
local cursor_fg = GetHighlightColor("Cursor", "guibg")
local cursor_bg = GetHighlightColor("CursorLine", "guibg")
local default_config = require('markfoldable.config').get_default_config()
local cursor_config = {}

for k,v in pairs(default_config) do
  cursor_config[k] = v
end

cursor_config.anchor_color = cursor_fg
cursor_config.anchor_bg = cursor_bg

local spaces_id = vim.api.nvim_create_namespace('markfoldable_folder_spaces')
local arrow_id = vim.api.nvim_create_namespace('markfoldable_folder_ids')
new_line_cursor_id = vim.api.nvim_create_namespace('markfoldable_new_line_cursor')
local new_line_cursor_lnum = nil
local current_buff_length = nil

local saved_cursor = vim.o.guicursor

function SpaceLine(lnum, position, config)
  if lnum <= 0 then return end
  if lnum > vim.fn.line('w$') then return end
  local is_current = vim.fn.line('.') == lnum

  if is_current and CurrentMode == 'i' then return end

  -- for handling buffer switching
  --if is_current and CurrentlySpacedLines.insert[1].lnum == lnum then
  --  if CurrentlySpacedLines.insert[1].buffer_id ~= vim.fn.bufnr('%') then
  --    CurrentlySpacedLines.insert[1] = { lnum = nil, buffer_id = nil }
  --    -- CurrentlySpacedLines.visual = {}
  --  else
  --    return
  --  end
  --end

  local higroup = 'MarkFoldableMarkerSpacer'
  return InsertMarker(lnum - 1, "  ", 0, position, spaces_id, config, higroup)
end

function SpaceLines(config)
  for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
    SpaceLine(lnum, "inline", config)
  end
end

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

function ClearVirtualText()
  local line_start = vim.fn.line('w0')
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, spaces_id, line_start, line_end)
  vim.api.nvim_buf_clear_namespace(bnr, arrow_id, line_start, line_end)
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, line_start, line_end)
end

function ClearSpaces()
  local line_start = vim.fn.line('w0')
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, spaces_id, line_start, line_end)
end

function ClearFoldMarks()
  local line_start = vim.fn.line('w0')
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, arrow_id, line_start, line_end)
end

function ClearCursorText()
  local line_start = vim.fn.line('w0')
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, line_start, line_end)
end


local function MarkFoldable(config)
  if CurrentMode == 'i' then
    return
  end

  local buff_len = vim.fn.line('$')
  if current_buff_length ~= buff_len then
    ClearVirtualText()
  end

  current_buff_length = buff_len

  -- local open_marker = ""
  local open_marker = config.opened_icon
  local closed_marker = config.closed_icon
  local closed_folds_lnums = {}
    -- Define the fold expression func

  local function MarkFold(lnum)
    if (lnum == 0) then return end
    if (IsEmptyLine(lnum)) then return end

    if not IsMarked(lnum) then return end

    local is_open = GetIsOpen(lnum)

    if is_open then table.insert(closed_folds_lnums, lnum) end
    local mark = is_open and open_marker or closed_marker

    local higroup = 'AnchorageAccordianMarkerClosed'
    if is_open then higroup = 'AnchorageAccordianMarkerOpen' end

    InsertMarker(lnum - 1, mark, 0, "overlay", arrow_id, config, higroup)
   end

 function MarkFolds()
   for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
     MarkFold(lnum)
   end
 end


  MarkFolds()

  local line = vim.fn.getline('.')
  -- Handle cursor positon for empty lines
  if CurrentMode == 'n' then
    local bnr = vim.fn.bufnr('%')

    if new_line_cursor_lnum ~= nil then
      vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, new_line_cursor_lnum - 1, new_line_cursor_lnum)
    end

    if string.len(line) < 1 then
      local noCursor = 'a:noCursor'


      if vim.o.guicursor ~= noCursor then
        saved_cursor = vim.o.guicursor
      end

      vim.o.guicursor = noCursor
      local higroup_cursor = 'MarkFoldableCursor'
      local lnum = vim.fn.line('.')
      new_line_cursor_lnum = lnum
      InsertMarker(lnum - 1, "  █", 0, "inline", new_line_cursor_id, cursor_config, higroup_cursor)
    else
      new_line_cursor_lnum = nil
      vim.o.guicursor = saved_cursor
    end
  end

  SpaceLines(config)
end

local hasErrored = false

return function(config)
  if (hasErrored == true) then return end

  -- local status, result = pcall(MarkFoldable, config)
  return MarkFoldable(config)

--  if not status then
--    hasErrored = true
--  end
--  return result
end
