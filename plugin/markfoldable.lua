local vim = vim
local cmd = vim.cmd

--vim.api.nvim_set_hl(0, 'MarkFoldableCursor', { link = "Cursor" })

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
local default_config = require('markfoldable.config').get_default_config()
local cursor_config = {}
local GetHighlightColor = require("markfoldable.get_highlight_color")
local cursor_fg = GetHighlightColor("Cursor", "guibg")
local cursor_bg = GetHighlightColor("CursorLine", "guibg")
local higroup_cursor = 'MarkFoldableCursor'
local insert_space_id = vim.api.nvim_create_namespace('markfoldable_insert_space')
local new_line_cursor_lnum = nil
local new_line_cursor_id = vim.api.nvim_create_namespace('markfoldable_new_line_cursor')

for k,v in pairs(default_config) do
  cursor_config[k] = v
end

cursor_config.anchor_color = cursor_fg
cursor_config.anchor_bg = cursor_bg
cursor_config.blend = 50
-- End Locals


vim.api.nvim_set_hl(0, 'noCursor', { reverse = true, blend = 100 })
-- vim.cmd([[set guicursor=n-v-c:block-Cursor]])
function HighlightRange(start_line, start_col, end_line, end_col)
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

local function ClearCursorText()
  local line_start = vim.fn.line('w0')
  local line_end = vim.fn.line('w$')
  local bnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, line_start, line_end)
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

local function HandleNormal()
  local line = vim.fn.getline('.')
  local bnr = vim.fn.bufnr('%')
  ClearCursorText()

  if new_line_cursor_lnum ~= nil then
    vim.api.nvim_buf_clear_namespace(bnr, new_line_cursor_id, new_line_cursor_lnum - 1, new_line_cursor_lnum)
  end

  if string.len(line) < 1 then
    local noCursor = 'a:noCursor'


    if vim.o.guicursor ~= noCursor then
      saved_cursor = vim.o.guicursor
    end

    vim.o.guicursor = noCursor
    local lnum = vim.fn.line('.')
    --local new_line_cursor_lnum = lnum
    local InsertMarker = require("markfoldable.insert_marker")
    InsertMarker(lnum - 1, "  █", 0, "overlay", new_line_cursor_id, cursor_config, higroup_cursor)
  else
    new_line_cursor_lnum = nil
    vim.o.guicursor = saved_cursor
  end
end

-- TODO: Prevent deleting behind line number spaces in insert mode
local function HandleInsert()
  ClearCursorText()
  local noCursor = 'a:noCursor'

  vim.o.guicursor = saved_cursor
  if vim.o.guicursor ~= noCursor then
    saved_cursor = vim.o.guicursor
  end


  local lnum = vim.fn.line('.')


  local InsertMarker = require("markfoldable.insert_marker")

  local col_pos = vim.fn.getpos('.')[3]
  local function ShiftCursor()
    local cursor_pos = vim.fn.getpos('.')[3]
    if cursor_pos < 2 then
      vim.o.guicursor = noCursor
      local line = vim.fn.getline(lnum)
      local line_length = string.len(line)
      if line_length > 0  then
        HighlightRange(lnum - 1, 0, lnum - 1, 1)
      end
    else
      vim.o.guicursor = saved_cursor
    end
  end

  if col_pos < 2 then
    vim.o.guicursor = noCursor
    vim.schedule(ShiftCursor)
  else
    vim.o.guicursor = saved_cursor
  end

  local function Shift()
    InsertMarker(lnum - 1, "  ", 0, "inline", insert_space_id, cursor_config, higroup_cursor)
  end
  vim.schedule(Shift)
end

function SetMode()
  --if get_is_in_menu() then return end

  PreviousMode = CurrentMode

  CurrentMode = vim.fn.mode()

  if CurrentMode == 'i' then
    ClearSpaces()
    SpaceLines(config)

    HandleInsert()
  end

  if PreviousMode == 'i' then
    local function Clear()
      ClearCursorText()
      local line_start = vim.fn.line('w0')
      local line_end = vim.fn.line('w$')
      local bnr = vim.fn.bufnr('%')
      vim.api.nvim_buf_clear_namespace(bnr, insert_space_id, line_start, line_end)

      ClearSpaces()
      SpaceLines(config)
      vim.o.guicursor = saved_cursor
    end
    vim.schedule(Clear)
  end
  if CurrentMode == 'n' then
    vim.schedule(HandleNormal)
  end
end

function AnchorageMarkFoldable()
  require('markfoldable.mark_foldable')(config)
end


vim.on_key(function(key)
  if get_is_in_menu() then return end

  local pressed = string.find(tostring(key), "\xfd") ~= nil
  if pressed and CurrentMode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end

  if CurrentMode == 'i' then
    HandleInsert()
  end

  -- Handle cursor positon for empty lines
  if CurrentMode == 'n' then
    vim.schedule(HandleNormal)
  end
end)


-- Update fold marks on text change
function TextChanged()
  if get_is_in_menu() then return end
  ClearCursorText()
  MarkFolds()
end

--require('markfoldable.mark_foldable')(config)
cmd([[autocmd BufRead,BufNewFile,CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd TextChanged * execute "lua TextChanged()"]])
cmd([[autocmd ModeChanged * execute "lua SetMode()"]])
-- cmd([[autocmd InsertLeave * execute "lua ResetCurrentlySpacedLines.insert()"]])

