return function(lnum)
  return string.len(string.gsub(vim.fn.getline(lnum), " ", "")) <= 0
end
