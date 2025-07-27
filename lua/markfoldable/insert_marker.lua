local vim = vim

local GetHighlightColor = require('markfoldable.get_highlight_color')

local background = GetHighlightColor('Normal', 'guibg')

if (string.len(background) <= 0) then
  background = 'NONE'
end

local function InsertMarker(lineNumber, char, col, position, ns_id, config, higroup)
  local bg = config.anchor_bg
  local fg = config.anchor_color

  local gui = ""

  if config.italic then gui = gui .. "italic," end
  if config.bold then gui = gui .. "bold," end
  if config.underline then gui = gui .. "underline," end
  if config.undercurl then gui = gui .. "undercurl," end
  local guibg = string.len(bg) > 0 and bg or background

  local hilight = [[hi ]] .. higroup .. [[ guifg=]] .. fg .. [[ guibg=]] .. guibg
  if string.len(gui) > 0 then
    hilight = hilight .. [[ gui=]] .. gui
  end

  if type(mygroup) ~= 'string' then
    vim.cmd(hilight)
  end

  local api = vim.api
  local bnr = vim.fn.bufnr('%')
  local line_num = lineNumber
  local col_num = col or 0

  local opts = {
    end_line = 0,
    id = lineNumber +1,
    virt_text = {{char, higroup}},
    virt_text_pos = position,
  }

  if (position == 'overlay') then
    opts.virt_text_win_col = col_num
  end

  return api.nvim_buf_set_extmark(bnr, ns_id, line_num, col_num, opts)
end

return InsertMarker
