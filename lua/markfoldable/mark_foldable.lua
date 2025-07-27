local vim = vim
local IsEmptyLine = require('markfoldable.helpers.is_empty_line')
local InsertMarker = require("markfoldable.insert_marker")
local GetHighlightColor = require("markfoldable.get_highlight_color")
local cursor_fg = GetHighlightColor("Cursor", "guifg")
local cursor_bg = GetHighlightColor("Cursor", "guibg")
local default_config = require('markfoldable.config').get_default_config()
local cursor_config = {}
for k,v in pairs(default_config) do
  cursor_config[k] = v
end

cursor_config.anchor_color = cursor_bg
cursor_config.anchor_bg = cursor_fg

local spaces_id = vim.api.nvim_create_namespace('markfoldable_folder_spaces')
local arrow_id = vim.api.nvim_create_namespace('markfoldable_folder_ids')
local new_line_cursor_id = vim.api.nvim_create_namespace('markfoldable_new_line_cursor')

local saved_cursor = vim.o.guicursor

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

    local higroup = 'AnchorageAccordianMarkerClosed'
    if is_open then higroup = 'AnchorageAccordianMarkerOpen' end

    InsertMarker(lnum - 1, mark, 0, "overlay", arrow_id, config, higroup)
 end

  local function SpaceLines(lnum, position)
    if lnum <= 0 then return end
    if lnum > vim.fn.line('w$') then return end
    local is_current = vim.fn.line('.') == lnum

    if is_current and lnum == CurrentInsert then
      return
    end

    local higroup = 'MarkFoldableMarkerSpacer'
    return InsertMarker(lnum - 1, "  ", 0, position, spaces_id, config, higroup)
  end

  for lnum = vim.fn.line('w0'),vim.fn.line('w$'),1 do
    MarkLines(lnum)
  end

  local line = vim.fn.getline('.')
  if vim.fn.mode() == 'n' then
    if string.len(line) < 1 then
      local noCursor = 'a:noCursor'

      if vim.o.guicursor ~= noCursor then
        saved_cursor = vim.o.guicursor
      end

      vim.o.guicursor = noCursor
      local higroup_cursor = 'MarkFoldableCursor'
      local lnum = vim.fn.line('.')
      InsertMarker(lnum - 1, "  █", 0, "inline", new_line_cursor_id, cursor_config, higroup_cursor)
    else
      vim.o.guicursor = saved_cursor
    end
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
