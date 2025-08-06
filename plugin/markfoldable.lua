local vim = vim

local cmd = vim.cmd

local con = require('markfoldable.config')

con.set_default_config()

local config = con.get_config()

function MPrint(error)
  vim.notify("Markfoldable: " .. error, vim.log.levels.ERROR)
end

CurrentMode = vim.fn.mode()

PreviousMode = vim.fn.mode()
-- Locals
-- local saved_cursor = vim.o.guicursor
local clear_spaces = require('markfoldable.mark_foldable').clear_spaces
local clear_fold_marks = require('markfoldable.mark_foldable').clear_fold_marks
local space_lines = require('markfoldable.mark_foldable').space_lines
local mark_folds = require('markfoldable.mark_foldable').mark_folds
local default_config = require('markfoldable.config').get_default_config()
local get_highlight_color = require("markfoldable.get_highlight_color")
local InsertMarker = require("markfoldable.insert_marker")
local write_virtual_text = require('markfoldable.mark_foldable').write_virtual_text

local saved_cursor = [[i:block]]

local higroup_cursor = 'MarkFoldableCursor'
local current_buff_length = nil
local insert_space_id = vim.api.nvim_create_namespace('markfoldable_insert_space')
local insert_space_overlay_id = vim.api.nvim_create_namespace('markfoldable_insert_space_overlay')
local new_line_cursor_lnum = nil
local new_line_cursor_id = vim.api.nvim_create_namespace('markfoldable_new_line_cursor')
local noCursor = 'a:noCursor'
local current_top_lnum = 1

local cursor_config = {}

for k,v in pairs(default_config) do
  cursor_config[k] = v
end

local function get_cursor_config()
  local cursor_fg = get_highlight_color("Cursor", "guibg")
  local cursor_bg = get_highlight_color("CursorLine", "guibg")

  cursor_config.anchor_color = cursor_fg
  cursor_config.anchor_bg = cursor_bg
  return cursor_config
end

-- End Locals
vim.api.nvim_set_hl(0, 'noCursor', { reverse = true, blend = 100 })

-- vim.cmd([[set guicursor=n-v-c:block-Cursor]])
local function highlight_range(start_line, start_col, end_line, end_col)
  vim.api.nvim_buf_set_extmark(
    0, -- Buffer number (0 for current buffer)
    new_line_cursor_id, -- Namespace (0 for default)
    start_line, -- 0-indexed start line
    start_col, -- 0-indexed start column
    {
      end_row = end_line, -- 0-indexed end line
      end_col = end_col, -- 0-indexed end column
      hl_group = "Cursor" -- Name of your custom highlight group
    }
  )
end

local function clear_cursor_text()
  local line_start = vim.fn.line('w0') - 1
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, line_start, line_end)
end

local function clear_current_line_space()
  local line_start = vim.fn.line('w0') - 1
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, insert_space_id, line_start, line_end)
  vim.api.nvim_buf_clear_namespace(bnr, insert_space_overlay_id, line_start, line_end)
end

local function get_is_in_menu()
  local win_id = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win_id).relative ~= '' then
    return true
  end

  if vim.fn.pumvisible() ~= 0 then
    return true
  end

  for _,v in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(v).relative ~= '' then
      return true
    end
  end

  return false
end

local function handle_empty_line(lnum, background)
  local function hide_cursor()
    if vim.o.guicursor ~= noCursor then
      saved_cursor = vim.o.guicursor
    end

    vim.o.guicursor = noCursor
  end

    local line = vim.fn.getline(lnum)
    local bnr = vim.fn.bufnr('%')

    if new_line_cursor_lnum ~= nil then
      vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, new_line_cursor_lnum - 1, new_line_cursor_lnum)
    end

    if string.len(line) < 1 then
      hide_cursor()
      --local new_line_cursor_lnum = lnum
      local c_config = get_cursor_config()
      c_config.anchor_bg = background or c_config.anchor_bg
      InsertMarker(lnum - 1, "  █", 0, "overlay", new_line_cursor_id, c_config, higroup_cursor)
    else
      new_line_cursor_lnum = nil
      local function enable_cursor()
        vim.o.guicursor = saved_cursor
      end
      vim.schedule(enable_cursor)
    end
end

local function handle_normal_mode(background)
  local lnum = vim.fn.line('.')
  handle_empty_line(lnum, background)
end

-- TODO: Prevent deleting behind line number spaces in insert mode
local function handle_insert_mode()
  vim.o.guicursor = saved_cursor
  if vim.o.guicursor ~= noCursor then
    saved_cursor = vim.o.guicursor
  end

  local lnum = vim.fn.line('.')
  handle_empty_line(lnum)

  local col_pos = vim.fn.getpos('.')[3]

  local function shiftcursor()
    local cursor_pos = vim.fn.getpos('.')[3]
    if cursor_pos < 2 then
      vim.o.guicursor = noCursor
      local line = vim.fn.getline(lnum)
      local line_length = string.len(line)
      if line_length > 0  then
        highlight_range(lnum - 1, 0, lnum - 1, 1)
      end
    else
      vim.o.guicursor = saved_cursor
    end
  end

  if col_pos < 2 then
    vim.o.guicursor = noCursor
    vim.schedule(shiftcursor)
  else
    vim.o.guicursor = saved_cursor
  end

  local function shift(shift_lnum)
    -- To prevent first character from jumping when writing in at in insert mode
    --
    local bnr = vim.fn.bufnr('%')
    vim.api.nvim_buf_clear_namespace(bnr, insert_space_id, shift_lnum - 1, shift_lnum)
    vim.api.nvim_buf_clear_namespace(bnr, insert_space_overlay_id, shift_lnum - 1, shift_lnum)
    InsertMarker(shift_lnum - 1, "  ", 0, "overlay", insert_space_overlay_id, get_cursor_config(), higroup_cursor)
    InsertMarker(shift_lnum - 1, "  ", 0, "inline", insert_space_id, get_cursor_config(), higroup_cursor)
  end

  shift(lnum)
end

--------- Trigger on auto commands -----------
function _MarkFoldableAuCommandModeChange()
  PreviousMode = CurrentMode

  CurrentMode = vim.fn.mode()

  if CurrentMode == 'i' then
    local lnum = vim.fn.line('.')
    -- clear space above and below current line to account for inserting in newline
    clear_spaces(math.max(lnum - 2, 1), lnum + 2)
    space_lines(config, vim.fn.line('w0') - 1,vim.fn.line('w$') + 1)

    handle_insert_mode()
    return
  end

  if PreviousMode == 'i' and CurrentMode == 'n' then
    local function clear()
      clear_current_line_space()
      handle_empty_line(vim.fn.line('.'))
    end
    local col_pos = vim.fn.getpos('.')[3]

    if col_pos == 1 then
      local lnum = vim.fn.line('.')
      space_lines(config, lnum - 1, lnum)
    end

    local function defered_clear()
      vim.schedule(clear)
    end

    vim.schedule(defered_clear)
  end

  if CurrentMode == 'n' then
    handle_normal_mode()
  end
end

-- Update fold marks on text change
function _MarkFoldableAuCommandTextChanged()
  if CurrentMode == 'n' then
    handle_normal_mode()
  end
  if get_is_in_menu() then return end
  mark_folds()
end

local function write_v_text()
  write_virtual_text(config)
end

function _MarkFoldableAuCommandBufRead()
  --vim.schedule(write_v_text)
  write_virtual_text(config)
  local buff_len = vim.fn.line('w$')

  if current_buff_length ~= buff_len then
    local function clear_marks()
      clear_fold_marks()
      clear_spaces(vim.fn.line('w0') - 1, vim.fn.line('w$'))
      space_lines(config, vim.fn.line('w0') - 1, vim.fn.line('w$'))
      mark_folds()
    end
    vim.schedule(clear_marks)
  end

  current_buff_length = buff_len

  if CurrentMode == 'i' then
    vim.schedule(handle_insert_mode)
  end

  if CurrentMode == 'n' then
    handle_normal_mode()
  end

  if CurrentMode == 'v' or CurrentMode == 'V' or CurrentMode == [[]] then
    local background = get_highlight_color("Normal", "guibg")
    handle_normal_mode(background)
  end

  local top_lnum = vim.fn.line('w0')
  if current_top_lnum ~= top_lnum then
    vim.schedule(mark_folds)
    current_top_lnum = top_lnum
  end
end

cmd([[autocmd BufRead,BufNewFile,CursorMoved,CursorMovedI * execute "lua _MarkFoldableAuCommandBufRead()"]])
cmd([[autocmd TextChanged * execute "lua _MarkFoldableAuCommandTextChanged()"]])
cmd([[autocmd ModeChanged * execute "lua _MarkFoldableAuCommandModeChange()"]])

vim.on_key(function(key)
  clear_cursor_text()
  if get_is_in_menu() then return end

  local pressed = string.find(tostring(key), "\xfd") ~= nil
  if pressed and vim.api.nvim_get_mode().mode == "n" then
    vim.schedule(write_v_text)
  end
end)
