local vim = vim
local cmd = vim.cmd

--vim.api.nvim_set_hl(0, 'MarkFoldableCursor', { link = "Cursor" })
vim.api.nvim_set_hl(0, 'MarkFoldableCursor', { fg = 'red', bg = 'blue' })

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

-- TODO: Prevent deleting behind line number spaces in insert mode
local function HandleInsert()
  ClearCursorText()
  local noCursor = 'a:noCursor'

  vim.o.guicursor = saved_cursor
  if vim.o.guicursor ~= noCursor then
    saved_cursor = vim.o.guicursor
  end



  local lnum = vim.fn.line('.')
  local col_pos = vim.fn.getpos('.')[3]

  local default_config = require('markfoldable.config').get_default_config()
  local cursor_config = {}
  local GetHighlightColor = require("markfoldable.get_highlight_color")
  local cursor_fg = GetHighlightColor("Cursor", "guibg")
  local cursor_bg = GetHighlightColor("CursorLine", "guibg")

  for k,v in pairs(default_config) do
    cursor_config[k] = v
  end

  cursor_config.anchor_color = cursor_fg
  cursor_config.anchor_bg = cursor_bg

  local higroup_cursor = 'MarkFoldableCursor'

  local InsertMarker = require("markfoldable.insert_marker")

  local function ShiftCursor()
    --local pos = vim.fn.getpos('.')
    --MPrint(pos[1] .. " " .. pos[2] .. " " .. pos[3] .. " " .. pos[4])
    -- MPrint(col_pos)

    local line = vim.fn.getline(lnum)
    local line_length = string.len(line)
    local position = math.min(col_pos + 1, line_length)
    local marker = line_length > 0 and "█" or "  █"
    InsertMarker(lnum - 1, marker, position, "overlay", new_line_cursor_id, cursor_config, higroup_cursor)
  end

  if col_pos < 2 then
    vim.o.guicursor = noCursor
    vim.schedule(ShiftCursor)
  end

  local function Shift()
    InsertMarker(lnum - 1, "  ", 0, "inline", new_line_cursor_id, cursor_config, higroup_cursor)
  end
  vim.schedule(Shift)
end

function SetMode()
  --if get_is_in_menu() then return end

  PreviousMode = CurrentMode

  CurrentMode = vim.fn.mode()

  --local col_pos = vim.fn.getpos('.')[3]

  if CurrentMode == 'i' then
    ClearSpaces()
    SpaceLines(config)

    HandleInsert()
  end

  if PreviousMode == 'i' then
    local function Clear()
      ClearCursorText()
      vim.o.guicursor = saved_cursor
    end
    vim.schedule(Clear)
  end
end

function AnchorageMarkFoldable()
  -- if get_is_in_menu() then return end
  require('markfoldable.mark_foldable')(config)
end


vim.on_key(function(key)
--  if CurrentMode == 'i' then
--    for _,v in ipairs(vim.api.nvim_list_wins()) do
--      if vim.api.nvim_win_get_config(v).relative ~= '' then
--        MPrint(vim.api.nvim_win_get_config(v).relative)
--      end
--    end
--  end

  if get_is_in_menu() then return end

  local pressed = string.find(tostring(key), "\xfd") ~= nil
  if pressed and CurrentMode == "n" then
    vim.schedule(AnchorageMarkFoldable)
  end

  if CurrentMode == 'i' then
    HandleInsert()
  end
end)

-- Update fold marks on text change
function TextChanged()
  if get_is_in_menu() then return end
  ClearFoldMarks()
  MarkFolds()
end

--require('markfoldable.mark_foldable')(config)
cmd([[autocmd BufRead,BufNewFile,CursorMoved,CursorMovedI * execute "lua AnchorageMarkFoldable()"]])
cmd([[autocmd TextChanged * execute "lua TextChanged()"]])
cmd([[autocmd ModeChanged * execute "lua SetMode()"]])
-- cmd([[autocmd InsertLeave * execute "lua ResetCurrentlySpacedLines.insert()"]])

