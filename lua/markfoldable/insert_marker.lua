local vim = vim

local GetHighlightColor = require('markfoldable.get_highlight_color')

local background = GetHighlightColor('Normal', 'guibg')

if (string.len(background) <= 0) then
  background = 'NONE'
end


local function InsertMarker(lineNumber, char, col, position, ns_id, config, higroup)
  local bg = config.anchor_bg
  local fg = config.anchor_color

  local guibg = string.len(bg) > 0 and bg or background

  vim.api.nvim_set_hl(0, higroup, {
    fg = fg,
    bg = guibg,
    italic = config.italic,
    bold = config. bold,
    undercurl = config.undercurl,
    underline = config.underline,
    reverse = config.reverse or false,
    blend = config.blend or 0,
  })

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
