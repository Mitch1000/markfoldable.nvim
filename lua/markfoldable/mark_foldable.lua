local vim = vim
------------------ Locals -------------------------
local is_empty_line = require('markfoldable.helpers.is_empty_line')
local InsertMarker = require("markfoldable.insert_marker")
local con = require('markfoldable.config')
local get_is_open = require('markfoldable.line').get_is_open
local get_is_marked = require('markfoldable.line').get_is_marked
local conf = con.get_config()

local spaces_id = vim.api.nvim_create_namespace('markfoldable_folder_spaces')
local arrow_id = vim.api.nvim_create_namespace('markfoldable_folder_ids')
local current_buff_length = nil
local open_marker = conf.opened_icon
local closed_marker = conf.closed_icon
local closed_folds_lnums = {}

local function space_line(lnum, position, config)
  if lnum <= 0 then return end
  if lnum > vim.fn.line('w$') then return end
  local is_current = vim.fn.line('.') == lnum

  if is_current and CurrentMode == 'i' then
    return
  end

  local higroup = 'MarkFoldableMarkerSpacer'
  return InsertMarker(lnum - 1, "  ", 0, position, spaces_id, config, higroup)
end

local function mark_fold(lnum)
  if (lnum == 0) then return end
  if (is_empty_line(lnum)) then return end

  if not get_is_marked(lnum) then return end

  local is_open = get_is_open(lnum)

  if is_open then table.insert(closed_folds_lnums, lnum) end
  local mark = is_open and open_marker or closed_marker

  local higroup = 'AnchorageAccordianMarkerClosed'
  if is_open then higroup = 'AnchorageAccordianMarkerOpen' end

  InsertMarker(lnum - 1, mark, 0, "overlay", arrow_id, conf, higroup)
end

----------------------- Exported Functions -----------------------------------
 function space_lines(config, start, endl)
  for lnum = start,endl,1 do
    space_line(lnum, "inline", config)
  end
end

local function mark_folds()
  for lnum = vim.fn.line('w0') - 1,vim.fn.line('w$'),1 do
    mark_fold(lnum)
  end
end

local function clear_spaces()
  local line_start = vim.fn.line('w0') - 1
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, spaces_id, line_start, line_end)
end

local function clear_fold_marks()
  local line_start = vim.fn.line('w0') - 1
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, arrow_id, line_start, line_end)
end

local function clear_virtual_text()
  clear_spaces()
  clear_fold_marks()
end

local function write_virtual_text(config)
  if CurrentMode == 'i' then
    return
  end

  local buff_len = vim.fn.line('$')
  if current_buff_length ~= buff_len then
    clear_virtual_text()
  end

  current_buff_length = buff_len

  mark_folds()

  -- space_lines(config, vim.fn.line('w0') - 1,vim.fn.line('w$'))
  -- space_lines(config, vim.fn.line('w0') - 1,vim.fn.line('w$'))
  space_lines(config, 1, vim.fn.line('$') + 1)
end

return {
  write_virtual_text = write_virtual_text,
  clear_spaces = clear_spaces,
  space_lines = space_lines,
  mark_folds = mark_folds,
}
