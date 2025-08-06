local vim = vim
local is_empty_line = require('markfoldable.helpers.is_empty_line')

local function get_next_line_nr(lnum)
  local i = 1
  local nextLineNum = lnum + i
  while (is_empty_line(nextLineNum) and i < vim.fn.line('$')) do
    nextLineNum = lnum + i
    i = i + 1
  end

  return nextLineNum
end

return {
  get_is_open = function(lnum)
    local total_lines = vim.fn.line('$')
    if (lnum + 1 >= total_lines) then return false end
    if not (vim.fn.foldclosed(lnum + 1) == -1) then return false end
    return true
  end,

  get_is_marked = function(lnum)
    local nextLineNum = get_next_line_nr(lnum)
    local indent = vim.fn.indent(lnum)
    local nextIndent = vim.fn.indent(nextLineNum)

    if is_empty_line(lnum) then return false end

    if (nextIndent <= indent) then return false end

    if (is_empty_line(nextLineNum)) then return false end
    return true
  end,
}
