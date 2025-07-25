local vim = vim

return function (group, term)
   -- Store output of group to variable
   local output = vim.fn.execute('hi ' .. group)

   -- Find the term we're looking for
   return vim.fn.matchstr(output, term .. [[=\zs\S*]])
end
